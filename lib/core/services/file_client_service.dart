import 'dart:async';
import 'dart:io';

class DownloadTask {
  final String id;
  final String filename;
  final int fileSize;
  final String savePath;

  DownloadTask({
    required this.id,
    required this.filename,
    required this.fileSize,
    required this.savePath,
  });
}

class FileTransferClient {
  bool _isDownloadCancelled = false;
  bool _isDownloadCompleted = false;

  Future<void> downloadFile(
    String ip,
    int port,
    DownloadTask task, {
    required Function(int bytesReceived, double percent) onProgress,
    required Function(double mbps) onSpeedUpdate,
    required Function(String path) onComplete,
    required Function(String error) onError,
  }) async {
    _isDownloadCancelled = false;
    _isDownloadCompleted = false;
    // Create FastShare folder if it doesn't exist
    final directory = Directory(task.savePath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final file = File('${task.savePath}/${task.filename}');
    final sink = file.openWrite();
    int totalBytesReceived = 0;
    final stopwatch = Stopwatch()..start();

    try {
      final httpClient = HttpClient();
      try {
        final request = await httpClient.getUrl(
          Uri.parse('http://$ip:$port/files?id=${task.id}'),
        );
        final response = await request.close();

        if (response.statusCode != 200) {
          throw Exception("Failed to download file: ${response.statusCode}");
        }

        final totalBytes = response.contentLength;

        // Speed calculation timer
        final speedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (stopwatch.elapsed.inSeconds > 0) {
            final speed =
                totalBytesReceived /
                (stopwatch.elapsed.inMilliseconds / 1000.0);
            final mbps = speed / (1024 * 1024);
            onSpeedUpdate(mbps);
          }
        });

        await for (var chunk in response) {
          if (_isDownloadCancelled) {
            speedTimer.cancel();
            await sink.close();
            break;
          }
          sink.add(chunk);
          totalBytesReceived += chunk.length;
          onProgress(totalBytesReceived, totalBytesReceived / totalBytes);
        }

        await sink.close();
        speedTimer.cancel();

        if (!_isDownloadCancelled && !_isDownloadCompleted) {
          _isDownloadCompleted = true;
          onComplete(file.path);
        }
      } finally {
        httpClient.close(force: true);
      }
    } catch (e) {
      await sink.close();
      if (!_isDownloadCompleted) {
        _isDownloadCompleted = true;
        onError(e.toString());
      }
    }
  }

  void cancelDownload() {
    _isDownloadCancelled = true;
  }
}
