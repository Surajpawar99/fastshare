import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'auth_manager.dart';

// const int _kChunkSize = 512 * 1024; // 512 KB - large chunk for efficient IO

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

  /// Asynchronously create a SharedFile from a PlatformFile.
  /// This avoids synchronous file I/O on the UI thread by using async File.length().
  static Future<SharedFile> fromPlatformFileAsync(PlatformFile pf) async {
    if (pf.path != null) {
      final file = File(pf.path!);
      int size = pf.size;
      try {
        size = await file.length();
      } catch (_) {}
      return SharedFile._(
          name: file.uri.pathSegments.last,
          size: size,
          file: file,
          stream: null);
    }

    // Stream-backed file
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
  AuthManager? _authManager;

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

  // Single-serving guard: only one file may be served at a time.
  bool _isServing = false;

  /// Starts the HTTP Server with optional password protection.
  /// If [password] is provided, all requests require authentication via token or password.
  /// Returns the server info including the auth token (if protected).
  Future<ServerInfo?> startServer(
    List<SharedFile> files, {
    String? password,
    Function(String)? onClientConnected,
    Function(int)? onBytesSent,
    Function(String)? onError,
  }) async {
    if (_server != null) return null;

    _filesToShare = files;

    // Initialize auth manager if password is provided
    if (password != null && password.isNotEmpty) {
      _authManager = AuthManager.fromPassword(password);
      print(
          '⚠️  Password-protected server enabled. Token: ${_authManager!.token}');
    }

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
    _authManager = null;
  }

  // --- AUTHENTICATION CHECK ---

  /// Returns true if the request is authenticated or if no password is set.
  /// Returns false if password protection is enabled but authentication fails.
  bool _isAuthenticated(HttpRequest request) {
    // If no auth manager, no password protection - all requests allowed
    if (_authManager == null) return true;

    // Check token in query parameters: ?token=...
    final tokenParam = request.uri.queryParameters['token'];
    if (tokenParam != null && _authManager!.validateToken(tokenParam)) {
      return true;
    }

    // Check token in X-Share-Token header
    final tokenHeader = request.headers.value('X-Share-Token');
    if (tokenHeader != null && _authManager!.validateToken(tokenHeader)) {
      return true;
    }

    return false;
  }

  /// Handles password submission via POST request.
  /// If password is correct, returns token via Location header redirect or JSON.
  Future<void> _handlePasswordSubmission(
    HttpRequest request,
    HttpResponse response,
  ) async {
    try {
      // Read POST body
      final bodyBytes = await request.fold<List<int>>(
        <int>[],
        (previous, element) => previous + element,
      );
      final bodyStr = String.fromCharCodes(bodyBytes);

      // Parse form data
      final params = Uri.splitQueryString(bodyStr);
      final password = params['password'] ?? '';

      if (_authManager!.validatePassword(password)) {
        // Password correct! Return token
        final token = _authManager!.token;

        // Send back token in multiple ways for flexibility
        response.headers.contentType = ContentType.json;
        response.statusCode = HttpStatus.ok;
        response.write('{"success": true, "token": "$token"}');
        await response.close();
      } else {
        // Password incorrect
        response.statusCode = HttpStatus.unauthorized;
        response.headers.contentType = ContentType.json;
        response.write('{"success": false, "error": "Invalid password"}');
        await response.close();
      }
    } catch (e) {
      response.statusCode = HttpStatus.badRequest;
      response.headers.contentType = ContentType.json;
      response.write('{"error": "Invalid request"}');
      await response.close();
    }
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
      // Handle password submission via POST
      if (request.method == 'POST' &&
          request.uri.path == '/' &&
          _authManager != null) {
        await _handlePasswordSubmission(request, response);
        return;
      }

      // Check authentication for all requests except static resources
      if (!_isAuthenticated(request) && request.uri.path != '/') {
        _servePasswordForm(response);
        return;
      }

      if (request.uri.path == '/' || request.uri.path.isEmpty) {
        // SERVE THE UI PAGE (or password form if not authenticated)
        if (!_isAuthenticated(request)) {
          _servePasswordForm(response);
        } else {
          _serveHtmlPage(response);
        }
      } else if (request.uri.path == '/download-all') {
        // SERVE ALL FILES AS ZIP
        if (!_isAuthenticated(request)) {
          _servePasswordForm(response);
          return;
        }
        _handleZipDownload(request, response);
      } else if (request.uri.path == '/files') {
        // SERVE FILE DOWNLOAD
        if (!_isAuthenticated(request)) {
          _servePasswordForm(response);
          return;
        }
        _handleFileDownload(request, response);
      } else if (request.uri.path == '/info') {
        // SERVE JSON METADATA
        if (!_isAuthenticated(request)) {
          response.statusCode = HttpStatus.unauthorized;
          response.headers.contentType = ContentType.json;
          response.write('{"error": "Unauthorized"}');
          await response.close();
          return;
        }
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
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
                <div class="section-title" style="margin-bottom: 0;">Files ready</div>
                ${_filesToShare.length > 1 ? '<a href="/download-all" class="download-btn" style="background-color: #00796B;">📦 Download All (.zip)</a>' : ''}
            </div>
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

  // --- 1.5 PASSWORD FORM ---
  void _servePasswordForm(HttpResponse response) async {
    response.headers.contentType = ContentType.html;

    final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="FastShare - Password Protected Share">
    <meta name="theme-color" content="#009688">
    <title>FastShare - Password Required</title>
    <link rel="icon" type="image/svg+xml" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 192 192'><rect fill='%23009688' width='192' height='192'/><text x='96' y='120' font-size='120' font-weight='bold' fill='white' text-anchor='middle' font-family='Arial'>FS</text></svg>">
    
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background: linear-gradient(135deg, #009688 0%, #00796B 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .card {
            background: white;
            border-radius: 24px;
            box-shadow: 0 15px 35px rgba(0,0,0,0.2);
            width: 100%;
            max-width: 380px;
            overflow: hidden;
            animation: slideUp 0.4s ease-out;
        }
        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        .header {
            background: linear-gradient(135deg, #009688 0%, #00796B 100%);
            padding: 50px 20px;
            text-align: center;
            color: white;
        }
        .logo {
            font-size: 52px;
            margin-bottom: 15px;
        }
        .app-name {
            font-size: 28px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        .subtitle {
            font-size: 14px;
            opacity: 0.95;
            font-weight: 500;
        }
        .content {
            padding: 30px;
        }
        .lock-icon {
            text-align: center;
            font-size: 42px;
            margin-bottom: 20px;
        }
        .title {
            font-size: 20px;
            font-weight: 600;
            color: #333;
            text-align: center;
            margin-bottom: 10px;
        }
        .message {
            text-align: center;
            font-size: 14px;
            color: #666;
            margin-bottom: 25px;
            line-height: 1.5;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: #333;
            margin-bottom: 8px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        input[type="password"] {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #E0E0E0;
            border-radius: 10px;
            font-size: 16px;
            font-family: inherit;
            transition: all 0.3s;
            color: #333;
        }
        input[type="password"]:focus {
            outline: none;
            border-color: #009688;
            box-shadow: 0 0 0 3px rgba(0,150,136,0.1);
        }
        input[type="password"]::placeholder {
            color: #AAA;
        }
        .submit-btn {
            width: 100%;
            padding: 13px;
            background: linear-gradient(135deg, #009688 0%, #00796B 100%);
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .submit-btn:hover {
            box-shadow: 0 8px 16px rgba(0,150,136,0.3);
            transform: translateY(-2px);
        }
        .submit-btn:active {
            transform: translateY(0);
        }
        .error {
            color: #D32F2F;
            font-size: 13px;
            margin-top: 8px;
            display: none;
            text-align: center;
        }
        .error.show {
            display: block;
            animation: shake 0.4s;
        }
        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            25% { transform: translateX(-5px); }
            75% { transform: translateX(5px); }
        }
        .footer {
            text-align: center;
            padding: 15px 20px;
            background: #F9F9F9;
            font-size: 12px;
            color: #999;
            border-top: 1px solid #EEE;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="header">
            <div class="app-name">FastShare</div>
            <div class="subtitle">Password Protected</div>
        </div>
        <div class="content">
            <div class="lock-icon">🔒</div>
            <div class="title">Enter Password</div>
            <div class="message">This share is password protected. Please enter the password to access the files.</div>
            
            <form id="passwordForm" onsubmit="handleSubmit(event)">
                <div class="form-group">
                    <label for="passwordInput">Password</label>
                    <input 
                        type="password" 
                        id="passwordInput" 
                        name="password" 
                        placeholder="Enter password"
                        autocomplete="off"
                        autofocus
                        required
                    >
                    <div class="error" id="error"></div>
                </div>
                <button type="submit" class="submit-btn">Unlock</button>
            </form>
        </div>
        <div class="footer">
            🔐 Secure offline sharing • No data is sent to servers
        </div>
    </div>

    <script>
        async function handleSubmit(event) {
            event.preventDefault();
            const password = document.getElementById('passwordInput').value;
            const errorEl = document.getElementById('error');
            
            try {
                // Submit password to server
                const response = await fetch('/', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: 'password=' + encodeURIComponent(password)
                });
                
                if (response.ok) {
                    const data = await response.json();
                    if (data.success && data.token) {
                        // Store token in localStorage for subsequent requests
                        localStorage.setItem('fastshare_token', data.token);
                        // Redirect to main page on success
                        window.location.href = '/?token=' + encodeURIComponent(data.token);
                    } else {
                        throw new Error('No token received');
                    }
                } else {
                    errorEl.textContent = 'Invalid password';
                    errorEl.classList.add('show');
                    document.getElementById('passwordInput').value = '';
                    setTimeout(() => errorEl.classList.remove('show'), 3000);
                }
            } catch (error) {
                console.error(error);
                errorEl.textContent = 'Connection error';
                errorEl.classList.add('show');
                setTimeout(() => errorEl.classList.remove('show'), 3000);
            }
        }

        // Auto-fill token if available from localStorage
        window.addEventListener('load', () => {
            const token = localStorage.getItem('fastshare_token');
            if (token && !new URLSearchParams(window.location.search).has('token')) {
                // Redirect with token
                window.location.href = '/?token=' + encodeURIComponent(token);
            }
        });
    </script>
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
  void _handleZipDownload(HttpRequest request, HttpResponse response) async {
    if (_filesToShare.isEmpty) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }

    if (_isServing) {
      response.statusCode = HttpStatus.tooManyRequests;
      response.write('Another transfer is in progress.');
      await response.close();
      return;
    }

    _isServing = true;
    try {
      final archive = Archive();
      
      for (final sf in _filesToShare) {
        if (sf.file != null) {
          final bytes = await sf.file!.readAsBytes();
          archive.addFile(ArchiveFile(sf.name, sf.size, bytes));
        } else if (sf.stream != null) {
          // For stream-backed files, we collect bytes (limited by memory for ZIP)
          final bytes = await sf.stream!.fold<List<int>>([], (p, e) => p + e);
          archive.addFile(ArchiveFile(sf.name, sf.size, bytes));
        }
      }

      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) throw Exception("Zip encoding failed");

      response.headers.contentType = ContentType('application', 'zip');
      response.headers.add(HttpHeaders.contentDisposition, 'attachment; filename="FastShare_Bundle.zip"');
      response.headers.contentLength = zipData.length;
      
      response.add(zipData);
      await response.flush();
      
      onDownloadComplete?.call(-1, true); // -1 indicates bundle download
    } catch (e) {
      print("Zip Error: $e");
      response.statusCode = HttpStatus.internalServerError;
    } finally {
      _isServing = false;
      await response.close();
    }
  }

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

    // Disallow non-browser clients from downloading ZIP files.
    // ZIP transfers must go via a browser (require browser download flow).
    if (filename.toLowerCase().endsWith('.zip') &&
        !_isBrowserRequest(request)) {
      response.statusCode = HttpStatus.forbidden;
      response.headers.contentType = ContentType.text;
      response.write(
          'ZIP download is restricted: please open this link in a browser to download the ZIP file.');
      await response.close();
      return;
    }

    response.headers.contentType = ContentType.binary;
    response.headers.add(
      HttpHeaders.contentDisposition,
      'attachment; filename="$filename"',
    );

    // Enforce single active download: reject concurrent requests
    if (_isServing) {
      response.statusCode = HttpStatus.tooManyRequests;
      response.write('Another download is in progress. Try again later.');
      await response.close();
      return;
    }

    // If file is seekable (File-backed), support Range requests and Accept-Ranges
    if (sf.file != null) {
      _isServing = true;
      response.headers.add(HttpHeaders.acceptRangesHeader, 'bytes');

      // Handle Range header for resume support
      // Supports formats: "bytes=100-200" or "bytes=100-" (from 100 to end)
      final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
      int start = 0;
      int end = fileSize - 1;
      bool isPartial = false;

      if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
        final rangeSpec = rangeHeader.substring(6); // Remove "bytes="
        final rangeParts = rangeSpec.split('-');

        try {
          // Parse start position
          if (rangeParts[0].isNotEmpty) {
            start = int.parse(rangeParts[0]);
          }

          // Parse end position (if specified)
          if (rangeParts.length > 1 && rangeParts[1].isNotEmpty) {
            end = int.parse(rangeParts[1]);
          }
          // If end is empty string (e.g., "bytes=100-"), use end of file
          // This is the standard format for resume: start from byte N to end

          // Validate ranges
          if (start < 0) start = 0;
          if (end >= fileSize) end = fileSize - 1;

          // Only treat as partial if we're not serving the full file
          if (start > 0 || end < fileSize - 1) {
            isPartial = true;
          }
        } catch (e) {
          // Invalid range format - serve full file
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
      int pendingIntervalBytes = 0;
      const int progressThrottleMs = 400; // throttle UI updates to 300-500ms

      // Create a tapped stream to report progress without awaiting per-chunk
      final fileStream = sf.file!.openRead(start, end + 1);
      final tapped = fileStream.transform(StreamTransformer.fromHandlers(
        handleData: (List<int> chunk, EventSink<List<int>> sink) {
          cumulativeBytes += chunk.length;
          pendingIntervalBytes += chunk.length;

          final now = DateTime.now().millisecondsSinceEpoch;
          final elapsedMs = now - lastTimestamp;

          if (elapsedMs >= progressThrottleMs) {
            // Report aggregated progress to UI/network callbacks
            final double speedMbps = elapsedMs > 0
                ? (pendingIntervalBytes / (1024 * 1024)) / (elapsedMs / 1000.0)
                : 0.0;
            if (onBytesSent != null) onBytesSent!(cumulativeBytes);
            if (onProgress != null) onProgress!(cumulativeBytes, speedMbps);
            pendingIntervalBytes = 0;
            lastTimestamp = now;
          }

          // Always forward chunk immediately to response stream
          sink.add(chunk);
        },
      ));

      bool completionNotified = false;
      try {
        // Stream directly to response without per-chunk awaits or flushes
        await response.addStream(tapped);

        // Only notify completion if this was a FULL file transfer (not a range request)
        // This prevents history duplication and duplicate completion handlers on resume
        try {
          if (!completionNotified && !isPartial) {
            completionNotified = true;
            onDownloadComplete?.call(id, _isBrowserRequest(request));
          }
        } catch (_) {}
      } catch (e) {
        // Stream error - client disconnected or IO error
      } finally {
        _isServing = false;
        await response.close();
      }
    } else if (sf.stream != null) {
      _isServing = true;
      // Non-seekable stream (e.g., content URI). We cannot support Range requests here.
      response.headers.contentLength = fileSize;

      int cumulativeBytes = 0;
      int lastTimestamp = DateTime.now().millisecondsSinceEpoch;
      int pendingIntervalBytes = 0;
      bool completionNotified = false;
      const int progressThrottleMs = 400; // throttle UI updates to 300-500ms

      // Tap the provided stream so we can report progress without awaiting per-chunk
      final tapped = sf.stream!.transform(StreamTransformer.fromHandlers(
        handleData: (List<int> chunk, EventSink<List<int>> sink) {
          cumulativeBytes += chunk.length;
          pendingIntervalBytes += chunk.length;

          final now = DateTime.now().millisecondsSinceEpoch;
          final elapsedMs = now - lastTimestamp;

          if (elapsedMs >= progressThrottleMs) {
            final double speedMbps = elapsedMs > 0
                ? (pendingIntervalBytes / (1024 * 1024)) / (elapsedMs / 1000.0)
                : 0.0;
            if (onBytesSent != null) onBytesSent!(cumulativeBytes);
            if (onProgress != null) onProgress!(cumulativeBytes, speedMbps);
            pendingIntervalBytes = 0;
            lastTimestamp = now;
          }

          sink.add(chunk);
        },
      ));

      try {
        await response.addStream(tapped);

        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsedMs = now - lastTimestamp;
        if (pendingIntervalBytes > 0) {
          final double speedMbps = elapsedMs > 0
              ? (pendingIntervalBytes / (1024 * 1024)) / (elapsedMs / 1000.0)
              : 0.0;
          if (onBytesSent != null) onBytesSent!(cumulativeBytes);
          if (onProgress != null) onProgress!(cumulativeBytes, speedMbps);
          pendingIntervalBytes = 0;
        }

        try {
          if (!completionNotified) {
            completionNotified = true;
            onDownloadComplete?.call(id, _isBrowserRequest(request));
          }
        } catch (_) {}
      } catch (e) {
        // Stream error
      } finally {
        _isServing = false;
        await response.close();
      }
    } else {
      // Should not happen
      response.statusCode = HttpStatus.internalServerError;
      await response.close();
    }
  }

  bool _isBrowserRequest(HttpRequest request) {
    final ua = request.headers.value(HttpHeaders.userAgentHeader) ?? '';
    final lower = ua.toLowerCase();
    // Very lightweight heuristic: typical browsers include "mozilla" or "chrome" or "safari"
    if (lower.contains('mozilla') ||
        lower.contains('chrome') ||
        lower.contains('safari')) {
      return true;
    }
    return false;
  }

  Future<InternetAddress?> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 &&
              !address.isLoopback &&
              address.address != '0.0.0.0') {
            return address;
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
