import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fastshare/features/history/presentation/providers/history_state_provider.dart';
import 'package:fastshare/features/history/presentation/widgets/history_list_item.dart';
import 'package:fastshare/features/home/presentation/widgets/home_action_card.dart';
import 'package:fastshare/routes.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hive is already initialized in main.dart, no need for initState here
    return _buildHomeContent(context, ref);
  }

  Widget _buildHomeContent(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Padding(
                padding: EdgeInsets.only(top: 10 * (1 - value)),
                child: child,
              ),
            );
          },
          child: const Text(
            'FastShare',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ✅ DRAWER ADDED HERE
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: const Text(
                'FastShare',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('How to Use'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.help);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.about);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.history);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.settings);
              },
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // --- Main Actions Row ---
              Row(
                children: [
                  Expanded(
                    child: HomeActionCard(
                      title: 'Send',
                      subtitle: 'Share files',
                      icon: Icons.arrow_upward_rounded,
                      color: theme.colorScheme.primary,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.send),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: HomeActionCard(
                      title: 'Receive',
                      subtitle: 'Get files',
                      icon: Icons.arrow_downward_rounded,
                      color: theme.colorScheme.secondary,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.receive),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // --- Recent Transfers Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transfers',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.history),
                    child: const Text('View All'),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // --- Recent Transfers List (Null-Safe) ---
              // ===== BULLETPROOF EMPTY STATE HANDLING =====
              // Shows last 3 successful transfers or graceful empty state
              //
              // Safety guarantees:
              // 1. history.recentTransfers NEVER returns null
              //    → Returns empty list if Hive box is empty
              //    → Returns empty list if no successful transfers
              // 2. No crash on app launch (Hive initialized in main.dart)
              // 3. No crash after clear history (empty list handled)
              // 4. Graceful UI feedback ("No transfers yet" message)
              //
              // Flow:
              // - If recent.isEmpty → show empty state card
              // - Else → show ListView with transfers
              // - No try-catch needed (HistoryProvider handles all errors)
              Consumer(
                builder: (context, ref, child) {
                  final history = ref.watch(historyStateProvider);
                  final recent =
                      history.recentTransfers; // Safe: always non-null list

                  // Empty state: no transfers yet
                  if (recent.isEmpty) {
                    return Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 64,
                              color: theme.colorScheme.outline.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transfers yet',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sent and received files will appear here',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Populated state: show recent transfers
                  return Expanded(
                    child: ListView.builder(
                      itemCount: recent.length,
                      itemBuilder: (context, index) {
                        final item = recent[index];
                        return HistoryListItem(item: item);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
