import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("About"), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- LOGO ---
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.wifi_tethering,
                  size: 60,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // --- APP DETAILS ---
              Text(
                "FastShare",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Fast. Offline. Secure File Sharing.",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "FastShare allows you to transfer photos, videos, and documents between Android devices without using the internet. It uses local WiFi Hotspot technology for high-speed, secure peer-to-peer sharing.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // --- FEATURES LIST ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _FeatureItem(
                      icon: Icons.wifi_off_rounded,
                      text: "No Internet Required",
                    ),
                    _FeatureItem(
                      icon: Icons.bolt_rounded,
                      text: "High Speed Transfer",
                    ),
                    _FeatureItem(
                      icon: Icons.security_rounded,
                      text: "Secure & Private",
                    ),
                    _FeatureItem(
                      icon: Icons.block_flipped,
                      text: "No Ads, No Tracking",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // --- FOOTER ---
              Text(
                "Developed by Suraj",
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "© ${DateTime.now().year} FastShare Open Source",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
