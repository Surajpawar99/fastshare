import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'routes.dart';
import 'core/theme/theme_provider.dart';
import 'features/history/domain/entities/history_item.dart';

class FastShareApp extends ConsumerWidget {
  const FastShareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: 'FastShare',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      themeMode: themeMode,

      // ✅ Start with splash screen
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===== CRITICAL: Initialize Hive BEFORE runApp() =====
  // This prevents HiveError: Box not found when services access history during startup.
  // We do this once in main() so all screens can use the box synchronously via HistoryService.
  await Hive.initFlutter();
  Hive.registerAdapter(HistoryItemAdapter());
  await Hive.openBox<HistoryItem>('historyBox');

  runApp(const ProviderScope(child: FastShareApp()));
}
