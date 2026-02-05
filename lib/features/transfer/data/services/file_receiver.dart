import 'dart:async';
import 'dart:io';

class DownloadTask {
  final int id; // ID on the server (e.g., 0, 1, 2)
  final String savePath; // Where to save locally
  final String filename;
  final int fileSize;

  DownloadTask({
    required this.id,
    required this.savePath,
    required this.filename,
    required this.fileSize,
  });
}

class FileTransferClient {
  HttpClient? _httpClient;
  StreamSubscription? _downloadSubscription;
  IOSink? _fileSink;
  Timer? _speedTimer;

  // State Tracking
  int _receivedBytes = 0;
  int _lastSpeedCheckBytes = 0;
  bool _inAppReceiving = false;

  // Callbacks
  final Function(int bytesReceived, double progress)? onProgress;
  final Function(double speedInMBps)? onSpeedUpdate;
  final Function(String savedPath)? onComplete;
  final Function(String error)? onError;

  // NEW: Combined progress callback with speed
  Function(int bytesReceived, double speedMbps)? onProgressWithSpeed;

  FileTransferClient({
    this.onProgress,
    this.onSpeedUpdate,
    this.onComplete,
    this.onError,
    this.onProgressWithSpeed,
  });

  /// Connects to the sender and downloads a specific file
  Future<void> downloadFile(
    String serverIp,
    int serverPort,
    DownloadTask task,
  ) async {
    if (_inAppReceiving) {
      onError?.call("A download is already in progress.");
      return;
    }
    _inAppReceiving = true;
    _receivedBytes = 0;
    _lastSpeedCheckBytes = 0;

    _httpClient = HttpClient()
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true)
      ..connectionTimeout = const Duration(seconds: 10);
    // Note: HttpClient maintains keepAlive automatically for streaming

    try {
      // 1. Prepare Local File
      final file = File('${task.savePath}/${task.filename}');
      if (await file.exists()) {
        await file.delete();
      }
      await file.parent.create(recursive: true);

      _fileSink = file.openWrite();

      // 2. Request File from Server with explicit streaming
      final url = Uri.parse('http://$serverIp:$serverPort/files?id=${task.id}');
      final request = await _httpClient!.getUrl(url);
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw Exception('Server returned status: ${response.statusCode}');
      }

      // 3. Start Speed Calculation Timer
      final startTime = DateTime.now();
      _startSpeedTimer(startTime);

      // 4. Process the Incoming Stream (streaming, no buffering)
      _downloadSubscription = response.listen(
        (List<int> chunk) {
          // Streaming directly to file, no memory buffering
          _fileSink!.add(chunk);
          _receivedBytes += chunk.length;
          final double progress = _receivedBytes / task.fileSize;

          if (onProgress != null) {
            onProgress!(_receivedBytes, progress);
          }
        },
        onError: (e) {
          // Error callback - guard will be reset in finally
          onError?.call("Download Error: $e");
        },
        onDone: () async {
          // Success path: completion fires ONCE
          await _fileSink!.flush();
          await _fileSink!.close();

          final savedSize = await file.length();
          if (savedSize == task.fileSize) {
            // File integrity verified - fire completion callback once
            if (!_inAppReceiving) return; // Already cleaned up
            onComplete?.call(file.path);
          } else {
            onError?.call(
              "File corrupted: Size mismatch ($savedSize != ${task.fileSize})",
            );
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      // Connection error - ensure guard is reset and show user-friendly error
      onError?.call("Connection failed: $e");
    } finally {
      _cleanup();
    }
  }

  /// Cancels the current download
  Future<void> cancelDownload() async {
    if (!_inAppReceiving) return;
    await _cleanup();
    onError?.call("Download cancelled by user");
  }

  // --- INTERNAL HELPERS ---

  void _startSpeedTimer(DateTime startTime) {
    // Check speed every 500ms
    _speedTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_inAppReceiving) {
        timer.cancel();
        return;
      }

      final bytesDiff = _receivedBytes - _lastSpeedCheckBytes;
      _lastSpeedCheckBytes = _receivedBytes;

      // Calculate Speed: bytes per 0.5s -> multiply by 2 for bytes/sec
      final bytesPerSecond = bytesDiff * 2;
      final mbps = bytesPerSecond / (1024 * 1024);

      if (onSpeedUpdate != null) {
        onSpeedUpdate!(mbps);
      }

      // NEW: Combined callback with bytes and speed
      if (onProgressWithSpeed != null) {
        onProgressWithSpeed!(_receivedBytes, mbps);
      }
    });
  }

  Future<void> _cleanup() async {
    if (!_inAppReceiving) return;
    _inAppReceiving = false;
    _speedTimer?.cancel();
    await _downloadSubscription?.cancel();
    await _fileSink?.close();
    _httpClient?.close(force: true);
    _httpClient = null;
  }
}
