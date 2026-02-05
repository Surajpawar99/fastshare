import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenInBrowserScreen extends StatelessWidget {
  final String shareLink;

  const OpenInBrowserScreen({super.key, required this.shareLink});

  Future<void> _handleOpenBrowser(BuildContext context) async {
    try {
      final Uri uri = Uri.parse(shareLink);

      // Attempt to launch in external browser (Chrome/Safari)
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showErrorSnackBar(context);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context);
      }
    }
  }

  void _showErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Could not open browser"),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: shareLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Link copied to clipboard"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Web Share"), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Icon & Title ---
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.public_rounded,
                  size: 50,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Open in Browser",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "If the receiver does not have the app, they can download files via their web browser.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 40),

              // --- Link Card ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        shareLink,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () => _copyToClipboard(context),
                      tooltip: "Copy Link",
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // --- Main Action Button ---
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => _handleOpenBrowser(context),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text(
                    "Open in Browser",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
