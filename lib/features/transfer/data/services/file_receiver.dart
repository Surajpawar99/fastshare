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
  bool _isReceiving = false;
  bool _isPaused = false;
  
  // Current task info for resume
  String? _currentServerIp;
  int? _currentServerPort;
  DownloadTask? _currentTask;

  // Callbacks
  Function(int bytesReceived, double speedMbps)? onProgress;
  Function(String savedPath)? onComplete;
  Function(String error)? onError;

  FileTransferClient({
    this.onProgress,
    this.onComplete,
    this.onError,
  });

  /// Starts a new download or resumes if file exists
  Future<void> downloadFile(
    String serverIp,
    int serverPort,
    DownloadTask task,
  ) async {
    if (_isReceiving) {
      onError?.call("A download is already in progress.");
      return;
    }
    
    _currentServerIp = serverIp;
    _currentServerPort = serverPort;
    _currentTask = task;
    _isReceiving = true;
    _isPaused = false;
    _lastSpeedCheckBytes = 0;

    try {
      final file = File('${task.savePath}/${task.filename}');
      
      // Check for existing partial file to resume
      int startByte = 0;
      if (await file.exists()) {
        startByte = await file.length();
        if (startByte >= task.fileSize) {
           // Already done?
           _isReceiving = false;
           onComplete?.call(file.path);
           return;
        }
      } else {
        await file.parent.create(recursive: true);
      }
      
      _receivedBytes = startByte;
      
      // Open file in APPEND mode if resuming, WRITE if new
      _fileSink = file.openWrite(mode: startByte > 0 ? FileMode.append : FileMode.write);

      _httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);

      final url = Uri.parse('http://$serverIp:$serverPort/files?id=${task.id}');
      final request = await _httpClient!.getUrl(url);
      
      // Add Range Header for Resume
      if (startByte > 0) {
        request.headers.add("Range", "bytes=$startByte-");
      }
      
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok || response.statusCode == HttpStatus.partialContent) {
         _startSpeedTimer();
         
         _downloadSubscription = response.listen(
          (List<int> chunk) {
            if (_isPaused) return; // Drop packets if paused (shouldn't happen if connection closed)
            
            _fileSink?.add(chunk);
            _receivedBytes += chunk.length;
            
            // Speed timer handles progress updates
          },
          onError: (e) {
            if (!_isPaused) onError?.call("Download Error: $e");
          },
          onDone: () async {
            await _fileSink?.flush();
            await _fileSink?.close();
            _speedTimer?.cancel();
            
            if (!_isPaused && _isReceiving) {
               _isReceiving = false;
               onComplete?.call(file.path);
            }
          },
          cancelOnError: true,
        );
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }

    } catch (e) {
      _cleanup();
      onError?.call("Connection failed: $e");
    }
  }

  Future<void> pauseDownload() async {
    if (!_isReceiving) return;
    _isPaused = true;
    _isReceiving = false;
    
    // Close connection but keep task info for resume
    await _downloadSubscription?.cancel();
    await _fileSink?.close();
    _httpClient?.close(force: true);
    _speedTimer?.cancel();
    
    // Notify UI
    if (onProgress != null) onProgress!(_receivedBytes, 0.0);
  }

  Future<void> resumeDownload() async {
    if (_isReceiving || _currentTask == null) return;
    
    // Restart download with same task (logic handles Range header)
    await downloadFile(_currentServerIp!, _currentServerPort!, _currentTask!);
  }

  Future<void> cancelDownload() async {
    _isReceiving = false;
    _isPaused = false;
    _cleanup();
    _currentTask = null;
  }

  void _startSpeedTimer() {
    _speedTimer?.cancel();
    _speedTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isReceiving) {
        timer.cancel();
        return;
      }

      final bytesDiff = _receivedBytes - _lastSpeedCheckBytes;
      _lastSpeedCheckBytes = _receivedBytes;
      
      // Bytes per 0.5s * 2 = Bytes/sec
      final double mbps = (bytesDiff * 2) / (1024 * 1024);
      
      if (onProgress != null) {
        onProgress!(_receivedBytes, mbps);
      }
    });
  }

  Future<void> _cleanup() async {
    _speedTimer?.cancel();
    await _downloadSubscription?.cancel();
    await _fileSink?.close();
    _httpClient?.close(force: true);
    _httpClient = null;
    _fileSink = null;
  }
}
