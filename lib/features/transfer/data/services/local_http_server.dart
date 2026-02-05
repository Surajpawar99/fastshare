import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

const int _kChunkSize = 512 * 1024; // 512 KB - large chunk for efficient IO

/// Represents the connection details needed by the Receiver
class ServerInfo {
  final String ipAddress;
  final int port;

  ServerInfo({required this.ipAddress, required this.port});
}

class SharedFile {
  final String name;
  final int size;
  final File? file; // if available (seekable)
  final Stream<List<int>>? stream; // non-seekable stream (content URI)

  SharedFile._({
    required this.name,
    required this.size,
    this.file,
    this.stream,
  });

  factory SharedFile.fromFile(File f) => SharedFile._(
        name: f.uri.pathSegments.last,
        size: f.lengthSync(),
        file: f,
        stream: null,
      );

  factory SharedFile.fromPlatformFile(PlatformFile pf) {
    // If path is available, prefer File for seekable operations
    if (pf.path != null) {
      final file = File(pf.path!);
      return SharedFile.fromFile(file);
    }

    // Else use provided readStream
    return SharedFile._(
      name: pf.name,
      size: pf.size,
      file: null,
      stream: pf.readStream,
    );
  }
}

class FileTransferServer {
  HttpServer? _server;
  List<SharedFile> _filesToShare = [];

  // Callbacks
  final Function(String clientIp)? onClientConnected;
  Function(int bytesSent)? onBytesSent;
  Function(int bytesTransferred, double speedMbps)? onProgress;

  /// Called when a download completes successfully.
  /// Provides the file index (id) and a flag indicating whether the
  /// request likely originated from a browser (true) or in-app client (false).
  Function(int fileIndex, bool viaBrowser)? onDownloadComplete;
  final Function(String error)? onError;

  FileTransferServer({
    this.onClientConnected,
    this.onBytesSent,
    this.onProgress,
    this.onDownloadComplete,
    this.onError,
  });

  /// Starts the HTTP Server
  Future<ServerInfo?> startServer(
    List<SharedFile> files, {
    Function(String)? onClientConnected,
    Function(int)? onBytesSent,
    Function(String)? onError,
  }) async {
    if (_server != null) return null;

    _filesToShare = files;

    try {
      final ip = await _getLocalIpAddress();
      if (ip == null) throw Exception("Could not determine local IP");

      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      _server!.listen(_handleRequest);

      print('Server running at http://${ip.address}:${_server!.port}');

      return ServerInfo(ipAddress: ip.address, port: _server!.port);
    } catch (e) {
      this.onError?.call("Failed to start server: $e");
      return null;
    }
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _filesToShare = [];
  }

  // --- INTERNAL REQUEST HANDLING ---

  void _handleRequest(HttpRequest request) async {
    final response = request.response;
    final clientIp = request.connectionInfo?.remoteAddress.address ?? 'Unknown';

    // Only notify connection for API/Download hits, to avoid spamming on favicon requests
    if (request.uri.path.contains('/files')) {
      onClientConnected?.call(clientIp);
    }

    try {
      if (request.uri.path == '/' || request.uri.path.isEmpty) {
        // SERVE THE UI PAGE
        _serveHtmlPage(response);
      } else if (request.uri.path == '/files') {
        // SERVE FILE DOWNLOAD
        _handleFileDownload(request, response);
      } else if (request.uri.path == '/info') {
        // SERVE JSON METADATA
        _handleInfoRequest(request, response);
      } else {
        response.statusCode = HttpStatus.notFound;
        response.write('404 Not Found');
        await response.close();
      }
    } catch (e) {
      print("Server Error: $e");
      response.statusCode = HttpStatus.internalServerError;
      await response.close();
    }
  }

  // --- 1. HTML UI GENERATION ---
  void _serveHtmlPage(HttpResponse response) async {
    response.headers.contentType = ContentType.html;

    // Generate File List HTML
    final fileListHtml = _filesToShare.asMap().entries.map((entry) {
      final index = entry.key;
      final sf = entry.value;
      final name = sf.name;
      final sizeMB = (sf.size / (1024 * 1024)).toStringAsFixed(1);

      return '''
        <div class="file-item">
          <div class="file-icon">📄</div>
          <div class="file-info">
            <div class="file-name">$name</div>
            <div class="file-size">$sizeMB MB</div>
          </div>
          <a href="/files?id=$index" class="download-btn">Download</a>
        </div>
      ''';
    }).join('');

    // Full HTML Page
    final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <!-- Page Metadata & Branding -->
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="FastShare - Secure local file transfer. Download files shared via FastShare app.">
    <meta name="theme-color" content="#009688">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="apple-mobile-web-app-title" content="FastShare">
    
    <!-- Page Title (appears in browser tab) -->
    <title>FastShare - File Download</title>
    
    <!-- Favicon (appears in browser tab) -->
    <link rel="icon" type="image/svg+xml" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 192 192'><rect fill='%23009688' width='192' height='192'/><text x='96' y='120' font-size='120' font-weight='bold' fill='white' text-anchor='middle' font-family='Arial'>FS</text></svg>">
    
    <style>
        body {
            font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: #F5F5F5;
            margin: 0;
            padding: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: #333;
        }
        .card {
            background: white;
            border-radius: 24px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.08);
            width: 100%;
            max-width: 400px;
            overflow: hidden;
        }
        .header {
            background-color: #009688; /* Teal Primary */
            padding: 40px 20px;
            text-align: center;
            color: white;
        }
        .logo {
            font-size: 48px;
            margin-bottom: 10px;
        }
        .app-name {
            font-size: 24px;
            font-weight: bold;
            margin: 0;
        }
        .subtitle {
            font-size: 14px;
            opacity: 0.9;
            margin-top: 5px;
        }
        .content {
            padding: 24px;
        }
        .section-title {
            font-size: 14px;
            color: #666;
            font-weight: 600;
            margin-bottom: 16px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .file-list {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }
        .file-item {
            display: flex;
            align-items: center;
            background: #F9F9F9;
            padding: 12px;
            border-radius: 16px;
            border: 1px solid #EEE;
        }
        .file-icon {
            font-size: 24px;
            margin-right: 12px;
            width: 40px;
            height: 40px;
            background: #E0F2F1;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .file-info {
            flex: 1;
            overflow: hidden;
        }
        .file-name {
            font-weight: 600;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            font-size: 14px;
        }
        .file-size {
            font-size: 12px;
            color: #888;
        }
        .download-btn {
            background-color: #009688;
            color: white;
            text-decoration: none;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            transition: opacity 0.2s;
        }
        .download-btn:active {
            opacity: 0.8;
        }
        .footer {
            text-align: center;
            padding: 20px;
            font-size: 12px;
            color: #AAA;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="header">
            <div class="logo">📡</div>
            <h1 class="app-name">FastShare</h1>
            <div class="subtitle">Secure Local File Transfer</div>
        </div>
        <div class="content">
            <div class="section-title">Files ready to download</div>
            <div class="file-list">
                $fileListHtml
            </div>
        </div>
        <div class="footer">
            No internet required • End-to-End Encrypted
        </div>
    </div>
</body>
</html>
    ''';

    response.write(html);
    await response.close();
  }

  // --- 2. JSON METADATA ---
  void _handleInfoRequest(HttpRequest request, HttpResponse response) async {
    final fileData = _filesToShare.asMap().entries.map((e) {
      final index = e.key;
      final sf = e.value;
      final name = sf.name.replaceAll('"', '\\"');
      final size = sf.size;
      return '{"id": $index, "name": "$name", "size": $size}';
    }).join(',');

    response.headers.contentType = ContentType.json;
    response.headers.add(
      "Access-Control-Allow-Origin",
      "*",
    ); // Allow Web Clients
    response.write('[$fileData]');
    await response.close();
  }

  // --- 3. FILE STREAMING ---
  void _handleFileDownload(HttpRequest request, HttpResponse response) async {
    final idStr = request.uri.queryParameters['id'];
    // Default to first file if no ID provided (Direct download button behavior)
    final id = int.tryParse(idStr ?? '0');

    if (id == null || id < 0 || id >= _filesToShare.length) {
      response.statusCode = HttpStatus.notFound;
      response.write('File not found');
      await response.close();
      return;
    }

    final sf = _filesToShare[id];
    final filename = sf.name;
    final fileSize = sf.size;

    response.headers.contentType = ContentType.binary;
    response.headers.add(
      HttpHeaders.contentDisposition,
      'attachment; filename="$filename"',
    );

    // If file is seekable (File-backed), support Range requests and Accept-Ranges
    if (sf.file != null) {
      response.headers.add(HttpHeaders.acceptRangesHeader, 'bytes');

      // Handle Range header
      final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
      int start = 0;
      int end = fileSize - 1;
      bool isPartial = false;
      if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
        // format bytes=start-end
        final rangeParts = rangeHeader.substring(6).split('-');
        try {
          if (rangeParts[0].isNotEmpty) {
            start = int.parse(rangeParts[0]);
          }
          if (rangeParts.length > 1 && rangeParts[1].isNotEmpty) {
            end = int.parse(rangeParts[1]);
          }
          if (start < 0) {
            start = 0;
          }
          if (end >= fileSize) {
            end = fileSize - 1;
          }
          if (start <= end) {
            isPartial = true;
          }
        } catch (_) {
          // ignore parse errors and fall back to full
          start = 0;
          end = fileSize - 1;
          isPartial = false;
        }
      }

      final contentLength = end - start + 1;
      response.headers.contentLength = contentLength;
      if (isPartial) {
        response.statusCode = HttpStatus.partialContent;
        response.headers.add(
          HttpHeaders.contentRangeHeader,
          'bytes $start-$end/$fileSize',
        );
      }

      int cumulativeBytes = 0;
      int lastTimestamp = DateTime.now().millisecondsSinceEpoch;

      final raf = await sf.file!.open(mode: FileMode.read);
      try {
        await raf.setPosition(start);
        int remaining = contentLength;
        while (remaining > 0) {
          final toRead = remaining > _kChunkSize ? _kChunkSize : remaining;
          final bytes = await raf.read(toRead);
          if (bytes.isEmpty) break;
          cumulativeBytes += bytes.length;

          if (onBytesSent != null) onBytesSent!(cumulativeBytes);

          final now = DateTime.now().millisecondsSinceEpoch;
          final elapsedMs = now - lastTimestamp;
          double speedMbps = 0.0;
          if (elapsedMs > 0) {
            speedMbps = (bytes.length / (1024 * 1024)) / (elapsedMs / 1000.0);
          }
          lastTimestamp = now;
          if (onProgress != null) onProgress!(cumulativeBytes, speedMbps);

          response.add(bytes);
          await response.flush();
          remaining -= bytes.length;
        }
        // If we reach here without exception, the download completed
        // Notify listeners that this file was fully served.
        try {
          onDownloadComplete?.call(id, _isBrowserRequest(request));
        } catch (_) {}
      } finally {
        await raf.close();
        await response.close();
      }
    } else if (sf.stream != null) {
      // Non-seekable stream (e.g., content URI). We cannot support Range requests here.
      response.headers.contentLength = fileSize;
      int cumulativeBytes = 0;
      int lastTimestamp = DateTime.now().millisecondsSinceEpoch;

      await for (final chunk in sf.stream!) {
        cumulativeBytes += chunk.length;
        if (onBytesSent != null) onBytesSent!(cumulativeBytes);

        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsedMs = now - lastTimestamp;
        double speedMbps = 0.0;
        if (elapsedMs > 0) {
          speedMbps = (chunk.length / (1024 * 1024)) / (elapsedMs / 1000.0);
        }
        lastTimestamp = now;
        if (onProgress != null) onProgress!(cumulativeBytes, speedMbps);

        response.add(chunk);
        await response.flush();
      }
      // Notify completion for stream-backed files as well
      try {
        onDownloadComplete?.call(id, _isBrowserRequest(request));
      } catch (_) {}
      await response.close();
    } else {
      // Should not happen
      response.statusCode = HttpStatus.internalServerError;
      await response.close();
    }
  }

  bool _isBrowserRequest(HttpRequest request) {
    final ua = request.headers.value(HttpHeaders.userAgentHeader) ?? '';
    final lower = ua.toLowerCase();
    // Very lightweight heuristic: typical browsers include "mozilla" or "chrome"
    if (lower.contains('mozilla') ||
        lower.contains('chrome') ||
        lower.contains('safari')) {
      return true;
    }
    return false;
  }

  Future<InternetAddress?> _getLocalIpAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );
    try {
      NetworkInterface? targetInterface;
      for (var interface in interfaces) {
        if (interface.name.toLowerCase().contains('wlan') ||
            interface.name.toLowerCase().contains('ap') ||
            interface.name.toLowerCase().contains('eth')) {
          targetInterface = interface;
          break;
        }
      }
      targetInterface ??= interfaces.first;
      return targetInterface.addresses.first;
    } catch (e) {
      return null;
    }
  }
}
