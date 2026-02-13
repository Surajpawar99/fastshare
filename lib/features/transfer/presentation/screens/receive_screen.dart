import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fastshare/features/transfer/domain/entities/transfer_task.dart';
import 'package:fastshare/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:fastshare/features/transfer/presentation/screens/qr_scan_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fastshare/core/services/discovery_service.dart';
import 'package:bonsoir/bonsoir.dart';

/// ReceiveScreen: ConsumerStatefulWidget for file receiving with proper Riverpod binding
///
/// Design Principles:
/// - Always opens URLs in external browser via url_launcher
/// - No in-app download logic
/// - No storage permission required
/// - Stateless: All persistent state stored in transferControllerProvider
class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  final DiscoveryService _discoveryService = DiscoveryService();
  List<BonsoirService> _discoveredDevices = [];
  StreamSubscription? _discoverySubscription;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  void _startDiscovery() {
    _discoveryService.startDiscovery();
    _discoverySubscription = _discoveryService.discoveredServices.listen((devices) {
      if (mounted) {
        setState(() {
          _discoveredDevices = devices;
        });
      }
    });
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _discoveryService.dispose();
    super.dispose();
  }

  /// Single entry point for all incoming links (QR scan or paste)
  /// Validates, normalizes, parses server details, and opens in external browser
  void handleIncomingLink(String link) {
    final trimmed = link.trim();

    if (!trimmed.startsWith('http')) {
      _showError('Invalid link');
      return;
    }

    // Normalize to ROOT link only
    Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      _showError('Invalid link');
      return;
    }

    // Build ROOT link: http://IP:PORT/
    final rootLink = '${uri.scheme}://${uri.host}:${uri.port}/';

    // Always open in external browser
    _startExternalBrowser(rootLink);
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ===== RIVERPOD: WATCH the controller state =====
    final task = ref.watch(transferControllerProvider);

    // Decision Logic for View State
    Widget content;

    if (task == null) {
      // No transfer in progress - show selection UI
      content = _buildSelectionState(theme);
    } else if (task.status == TransferStatus.failed) {
      content = _buildErrorState(theme, task.errorMessage);
    } else if (task.status == TransferStatus.completed) {
      content = _buildCompletedState(theme);
    } else {
      // Transferring or Paused
      content = _buildReceivingState(theme, task);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Receive Files"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBack(context, task),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: content,
          ),
        ),
      ),
    );
  }

  // --- STATES ---

  Widget _buildSelectionState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_discoveredDevices.isNotEmpty) ...[
          Text(
            "Nearby Devices Found",
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _discoveredDevices.length,
              itemBuilder: (context, index) {
                final device = _discoveredDevices[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: InkWell(
                    onTap: () {
                      final host = device.toJson()['host'] ?? device.name;
                      final port = device.port;
                      handleIncomingLink('http://$host:$port/');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.devices, color: theme.colorScheme.primary),
                          const SizedBox(height: 8),
                          Text(
                            device.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
        ],
        const Text(
          "Choose connection method",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        _ActionCard(
          icon: Icons.qr_code_scanner,
          title: "Scan QR Code",
          subtitle: "Scan sender's screen",
          color: theme.colorScheme.primary,
          onTap: () async {
            // Request camera permission before opening scanner
            final status = await Permission.camera.request();
            if (status.isDenied || status.isPermanentlyDenied) {
              // Show friendly message and offer to open settings
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Camera Permission'),
                  content: const Text(
                      'Camera access is required to scan QR codes. Please grant permission in Settings.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () {
                        openAppSettings();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              );
              return;
            }

            // Navigate to Scan Screen
            final scannedValue = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QRScanScreen()),
            );

            // If we got a value back, handle it
            if (scannedValue != null && scannedValue is String) {
              handleIncomingLink(scannedValue);
            }
          },
        ),
        const SizedBox(height: 16),
        _ActionCard(
          icon: Icons.link,
          title: "Paste Link",
          subtitle: "Enter http://IP:PORT",
          color: theme.colorScheme.tertiary,
          onTap: _showLinkBottomSheet,
        ),
      ],
    );
  }

  Widget _buildReceivingState(ThemeData theme, TransferTask task) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.downloading,
            size: 64,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 40),

        Text(
          "Receiving ${task.fileName}",
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: task.progress,
            minHeight: 12,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "${(task.progress * 100).toStringAsFixed(1)}%",
            style: theme.textTheme.bodySmall,
          ),
        ),

        const SizedBox(height: 32),

        // Stats
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat(
                "Speed",
                "${task.speedMbps.toStringAsFixed(1)} MB/s",
                theme,
              ),
              _stat("Received", _formatBytes(task.bytesTransferred), theme),
              _stat("Total", _formatBytes(task.totalBytes), theme),
            ],
          ),
        ),
        const Spacer(),

        OutlinedButton.icon(
          onPressed: () => _handleBack(context, task),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            minimumSize: const Size(double.infinity, 56),
          ),
          icon: const Icon(Icons.close),
          label: const Text("Cancel Transfer"),
        ),
      ],
    );
  }

  Widget _buildCompletedState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          Text("Transfer Complete!", style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            "Files saved to Download/FastShare",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 40),
          FilledButton(
            onPressed: () {
              // ===== RIVERPOD: Reset controller when done =====
              ref.read(transferControllerProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: theme.colorScheme.error),
          const SizedBox(height: 24),
          Text("Transfer Failed", style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(
            error ?? "Unknown Error",
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: () {
              // ===== RIVERPOD: Reset controller to retry =====
              ref.read(transferControllerProvider.notifier).reset();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Try Again"),
          ),
        ],
      ),
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

  // --- ACTIONS ---

  void _showLinkBottomSheet() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter Link",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: "http://192.168.x.x:8080",
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  Navigator.pop(context);
                  handleIncomingLink(textController.text);
                } else {
                  Navigator.pop(context);
                  _showError('Paste a valid link');
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Connect"),
            ),
          ],
        ),
      ),
    );
  }

  /// ===== BROWSER-ONLY FLOW =====
  /// This is the ONLY entry point for all incoming file downloads
  /// Routes:
  /// 1. QR Scan → extractLink() → handleIncomingLink()
  /// 2. Paste Link → handleIncomingLink()
  /// 3. Both call → _startExternalBrowser()
  ///
  /// Design Principles:
  /// - NO in-app download logic (removed)
  /// - NO storage permissions needed
  /// - Opens external browser via url_launcher
  /// - Browser handles all download complexity (zip, multiple files, etc.)
  /// - Single, simple, reliable flow
  Future<void> _startExternalBrowser(String filesUrl) async {
    try {
      // ===== LAUNCH EXTERNAL BROWSER =====
      // LaunchMode.externalApplication ensures:
      // - Always opens system default browser (not in-app webview)
      // - User has full browser capabilities (save, share, manage downloads)
      // - Browser handles all file operations (not our responsibility)
      // - No app-level permissions needed for downloads
      await launchUrl(
        Uri.parse(filesUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      // Browser not available (unlikely, but handled)
      _showError('Could not open browser: $e');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleBack(BuildContext context, TransferTask? task) {
    if (task != null && task.status == TransferStatus.transferring) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Stop Receiving?"),
          content: const Text("Transfer will be cancelled."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Continue"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                // ===== RIVERPOD: Reset controller when cancelled =====
                ref.read(transferControllerProvider.notifier).reset();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text("Stop"),
            ),
          ],
        ),
      );
    } else {
      // ===== RIVERPOD: Reset controller on normal back =====
      ref.read(transferControllerProvider.notifier).reset();
      Navigator.pop(context);
    }
  }

  String _formatBytes(int bytes) =>
      "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
}

// Reusable Action Card helper
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
