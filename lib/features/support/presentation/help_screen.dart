import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("How to Use"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- STEPS ---
          _StepCard(
            step: 1,
            title: "Connect to the Same Network",
            description:
                "Ensure both the sender and receiver devices are on the same Wi-Fi network.",
            icon: Icons.wifi_rounded,
          ),
          _StepCard(
            step: 2,
            title: "Select Files to Send",
            description:
                "On the sender's device, tap 'Send' and choose the files you want to share. A QR code will appear.",
            icon: Icons.file_present_rounded,
          ),
          _StepCard(
            step: 3,
            title: "Scan to Receive",
            description:
                "On the receiver's device, tap 'Receive' and use the camera to scan the QR code from the sender's screen.",
            icon: Icons.qr_code_scanner_rounded,
          ),
          _StepCard(
            step: 4,
            title: "Automatic Transfer",
            description:
                "The transfer begins instantly after a successful connection. Keep the app open until it's complete.",
            icon: Icons.rocket_launch_rounded,
          ),

          const SizedBox(height: 32),

          // --- TIPS SECTION ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.tertiary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Pro Tips",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TipItem(
                    text:
                        "Enable High Performance Mode in settings for the fastest speeds."),
                _TipItem(
                    text:
                        "Use a 5GHz Wi-Fi hotspot for a significant speed boost over 2.4GHz."),
                _TipItem(
                    text:
                        "Enable 'Keep screen on' in settings to prevent transfers from being interrupted."),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final String title;
  final String description;
  final IconData icon;

  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Number Badge
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              "$step",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(icon, color: theme.colorScheme.primary.withOpacity(0.7)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;
  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
