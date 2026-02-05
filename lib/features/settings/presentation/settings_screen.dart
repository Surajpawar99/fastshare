import 'package:flutter/material.dart';
import 'package:fastshare/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fastshare/core/theme/theme_provider.dart';
// Use the NotifierProvider exposed by the theme module

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeNotifierProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- SECTION 1: APPEARANCE ---
          _SettingsSection(
            title: "Appearance",
            children: [
              const SizedBox(height: 8),
              // Theme Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "App Theme",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text("System"),
                          icon: Icon(Icons.brightness_auto),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text("Light"),
                          icon: Icon(Icons.light_mode),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text("Dark"),
                          icon: Icon(Icons.dark_mode),
                        ),
                      ],
                      selected: {currentThemeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        ref
                            .read(themeNotifierProvider.notifier)
                            .toggleTheme(newSelection.first);
                      },
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

          const SizedBox(height: 24),

          // --- SECTION 2: GENERAL ---
          _SettingsSection(
            title: "General",
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.screen_lock_portrait_rounded),
                title: const Text("Keep screen on"),
                subtitle: const Text("Prevent sleep during transfer"),
                value: settings.isWakelockEnabled,
                onChanged: (val) {
                  ref.read(settingsProvider).setWakelock(val);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- SECTION 3: PERFORMANCE ---
          _SettingsSection(
            title: "Performance",
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.bolt_rounded),
                title: const Text("High Performance Mode"),
                subtitle: const Text("Prioritize speed over battery"),
                activeThumbColor: theme.colorScheme.primary,
                value: settings.isHighPerformanceModeEnabled,
                onChanged: (val) {
                  ref.read(settingsProvider).setHighPerformanceMode(val);
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "May drain battery faster on older devices.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- APP INFO ---
          Center(
            child: Column(
              children: [
                Text(
                  "FastShare v1.0.0",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Made with FastShare",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// --- HELPER WIDGET: SETTINGS SECTION ---
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}
