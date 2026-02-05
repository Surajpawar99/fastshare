import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Imports
import 'package:fastshare/features/transfer/data/services/local_http_server.dart';
import 'package:fastshare/features/transfer/domain/entities/transfer_task.dart';
import 'package:fastshare/features/transfer/presentation/controllers/transfer_controller.dart';

class ShareSessionScreen extends ConsumerStatefulWidget {
  final List<PlatformFile> files;

  const ShareSessionScreen({super.key, required this.files});

  @override
  ConsumerState<ShareSessionScreen> createState() => _ShareSessionScreenState();
}

class _ShareSessionScreenState extends ConsumerState<ShareSessionScreen> {
  FileTransferServer? _server;
  String? _serverIp;
  int? _serverPort;

  // Test mode variables
  Timer? _testTimer;
  int _testBytesTransferred = 0;
  static const int _testTotalBytes = 10000000; // 10 MB
  bool _showTestButton = true; // Toggle for test button visibility

  // ===== SINGLE ACTIVE TRANSFER GUARD =====
  // Prevents multiple concurrent calls to _initializeSession()
  // This ensures:
  // - startServer() is called ONLY ONCE
  // - No duplicate HTTP servers on different ports
  // - No concurrent file transfers
  // - "Cannot bind server port" errors prevented
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    // Post-frame callback to ensure Ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession();
    });
  }

  @override
  void dispose() {
    _server?.stopServer();
    _testTimer?.cancel(); // Cancel test timer
    _isInitializing = false; // Reset guard
    super.dispose();
  }

  /// Initialize transfer session with single-active-transfer guarantee
  /// Guard prevents multiple concurrent initializations
  /// Scenarios prevented:
  /// - User quickly pops and re-enters screen
  /// - Navigation race conditions
  /// - Multiple port binding attempts
  /// - Concurrent file server startups
  Future<void> _initializeSession() async {
    // Guard: prevent concurrent initialization
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // 1. Calculate total size
      int totalBytes = 0;
      for (var pf in widget.files) {
        if (pf.path != null) {
          try {
            totalBytes += await File(pf.path!).length();
          } catch (_) {
            totalBytes += pf.size;
          }
        } else {
          totalBytes += pf.size;
        }
      }
      final fileName = widget.files.length == 1
          ? widget.files.first.name
          : "${widget.files.length} files";

      // Get controller notifier for wiring progress
      final controller = ref.read(transferControllerProvider.notifier);

      // 2. Initialize Controller State
      controller.startSending(fileName, totalBytes);

      // 3. Create server with error callback wired to controller
      _server = FileTransferServer(
        onError: (err) {
          controller.markFailed(err);
        },
      );

      // 4. Wire server progress callback to controller
      _server!.onProgress = (bytes, speed) {
        controller.updateProgress(bytesTransferred: bytes, speedMbps: speed);
      };

      // 5. Start Server
      // Convert PlatformFile -> SharedFile (server-friendly wrapper)
      final shared =
          widget.files.map((pf) => SharedFile.fromPlatformFile(pf)).toList();

      final info = await _server!.startServer(shared);

      // Wire download-complete callback so sender can mark completion and persist history
      _server!.onDownloadComplete = (fileIndex, viaBrowser) {
        // Update transfer method (Browser vs InApp) before marking completed
        if (viaBrowser) {
          ref
              .read(transferControllerProvider.notifier)
              .updateTransferMethod(TransferMethod.browser);
        } else {
          ref
              .read(transferControllerProvider.notifier)
              .updateTransferMethod(TransferMethod.inApp);
        }
        ref
            .read(transferControllerProvider.notifier)
            .markCompleted(isSent: true);
      };

      if (info != null) {
        if (mounted) {
          setState(() {
            _serverIp = info.ipAddress;
            _serverPort = info.port;
          });
        }
      } else {
        controller.markFailed("Could not bind server port");
      }
    } catch (e) {
      // Initialization error (no port available, etc.)
      if (mounted) {
        ref
            .read(transferControllerProvider.notifier)
            .markFailed("Server error: $e");
      }
    } finally {
      // ===== CRITICAL: Reset guard even on error =====
      // Ensures next access to this screen doesn't skip initialization
      _isInitializing = false;
    }
  }

  // ========== TEST MODE FEATURE (TEMPORARY) ==========
  /// TEST BUTTON: Simulates file transfer without actual file operations
  /// This is ONLY for testing Riverpod binding and controller updates
  void _startTestTransfer() {
    setState(() => _showTestButton = false);

    // Reset test state
    _testBytesTransferred = 0;
    _testTimer?.cancel();

    // Initialize the controller with test data
    ref
        .read(transferControllerProvider.notifier)
        .startSending("test.zip", _testTotalBytes);

    // Simulate progress with timer
    _testTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final task = ref.read(transferControllerProvider);
      if (task == null) {
        timer.cancel();
        return;
      }

      // Increment progress (250 KB per tick at 100ms = ~2.5 MB/s avg)
      _testBytesTransferred += 250000;

      // Simulate speed (varying between 2-5 MB/s)
      final randomSpeed = 2.0 + ((_testBytesTransferred % 3000) / 1000.0);

      // Clamp bytes to max
      final clampedBytes = _testBytesTransferred > _testTotalBytes
          ? _testTotalBytes
          : _testBytesTransferred;

      // Update controller with progress
      ref.read(transferControllerProvider.notifier).updateProgress(
            bytesTransferred: clampedBytes,
            speedMbps: randomSpeed,
          );

      // Auto-complete when done
      if (_testBytesTransferred >= _testTotalBytes) {
        timer.cancel();
        ref
            .read(transferControllerProvider.notifier)
            .markCompleted(isSent: true);
      }
    });
  }

  void _stopTestTransfer() {
    _testTimer?.cancel();
    setState(() => _showTestButton = true);
    ref.read(transferControllerProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ===== RIVERPOD: WATCH the controller state =====
    final task = ref.watch(transferControllerProvider);

    // Handle Null/Loading State
    if (task == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Share Files"),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _handleClose(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isWaiting = _serverIp != null && task.bytesTransferred == 0;
    final isError = task.status == TransferStatus.failed;
    final isCompleted = task.status == TransferStatus.completed;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Share Files"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- QR CODE ---
            _buildQRSection(theme, isWaiting, task),

            const SizedBox(height: 32),

            // --- ERROR MESSAGE ---
            if (isError)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.errorMessage ?? "Unknown Error",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),

            // --- LINK CARD (Only when waiting) ---
            if (isWaiting && !isError) _buildLinkCard(theme),

            // --- PROGRESS (When transferring or done) ---
            if (!isWaiting && !isError) ...[_buildProgressSection(theme, task)],

            const SizedBox(height: 40),

            // --- COMPLETE BUTTON (Mark as done) ---
            if (task.status == TransferStatus.completed)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FilledButton.icon(
                  onPressed: () {
                    ref
                        .read(transferControllerProvider.notifier)
                        .markCompleted(isSent: true);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Done"),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),

            // --- TEST BUTTON (TEMPORARY FOR TESTING - CLEARLY MARKED) ---
            if (_showTestButton && task.status != TransferStatus.transferring)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FilledButton.icon(
                  onPressed: _startTestTransfer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Start Test Transfer"),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.deepOrange,
                  ),
                ),
              ),

            // --- STOP TEST BUTTON ---
            if (!_showTestButton)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OutlinedButton.icon(
                  onPressed: _stopTestTransfer,
                  icon: const Icon(Icons.stop),
                  label: const Text("Stop Test"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    foregroundColor: Colors.red,
                  ),
                ),
              ),

            // --- CONTROLS ---
            if (!isCompleted && !isError) _buildControls(theme, task),

            if (isCompleted)
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check),
                label: const Text("Done"),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildQRSection(ThemeData theme, bool isWaiting, TransferTask task) {
    return Column(
      children: [
        Container(
          width: 220,
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: isWaiting && _serverIp != null && _serverPort != null
                ? QrImageView(
                    data: 'http://$_serverIp:$_serverPort/',
                    size: 200,
                    backgroundColor: Colors.white,
                  )
                : isWaiting
                    ? const Icon(
                        Icons.qr_code_2_rounded,
                        size: 160,
                        color: Colors.black87,
                      )
                    : Icon(
                        Icons.upload_file_rounded,
                        size: 100,
                        color: theme.colorScheme.primary,
                      ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isWaiting ? "Scan to Connect" : "Sending ${task.fileName}...",
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isWaiting
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkCard(ThemeData theme) {
    // Expose only the root link to users (matches QR behavior)
    final url = "http://$_serverIp:$_serverPort/";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.link),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              url,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Link copied!")));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme, TransferTask task) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Progress", style: theme.textTheme.titleMedium),
            Text(
              "${(task.progress * 100).toStringAsFixed(1)}%",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: task.progress,
            minHeight: 12,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _stat("Speed", "${task.speedMbps.toStringAsFixed(1)} MB/s", theme),
            _stat("Sent", _formatBytes(task.bytesTransferred), theme),
            _stat("Total", _formatBytes(task.totalBytes), theme),
          ],
        ),
      ],
    );
  }

  Widget _stat(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildControls(ThemeData theme, TransferTask task) {
    final isPaused = task.status == TransferStatus.paused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause / Resume
        FloatingActionButton.large(
          heroTag: 'pause',
          onPressed: () {
            if (isPaused) {
              ref.read(transferControllerProvider.notifier).resume();
            } else {
              ref.read(transferControllerProvider.notifier).pause();
            }
          },
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            size: 36,
          ),
        ),
        const SizedBox(width: 32),
        // Stop
        FloatingActionButton.large(
          heroTag: 'stop',
          onPressed: () => _handleClose(context),
          backgroundColor: theme.colorScheme.errorContainer,
          foregroundColor: theme.colorScheme.onErrorContainer,
          child: const Icon(Icons.stop_rounded, size: 36),
        ),
      ],
    );
  }

  void _handleClose(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Stop Sharing?"),
        content: const Text("This will disconnect any active transfers."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              ref.read(transferControllerProvider.notifier).reset();
              _testTimer?.cancel(); // Cancel test timer
              Navigator.pop(context); // Close screen
            },
            child: const Text("Stop"),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }
}
