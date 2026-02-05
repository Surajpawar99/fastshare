import 'package:flutter/material.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/home/presentation/screens/splash_screen.dart';
import 'features/transfer/presentation/screens/send_screen.dart';
import 'features/transfer/presentation/screens/receive_screen.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/support/presentation/help_screen.dart';
import 'features/support/presentation/about_screen.dart';
import 'features/transfer/presentation/screens/qr_scan_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String send = '/send';
  static const String receive = '/receive';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String share = '/share';
  static const String help = '/help';
  static const String about = '/about';
  static const String qrScan = '/qr-scan';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        home: (context) => const HomeScreen(),
        send: (context) => const SendScreen(),
        // Note: ShareSessionScreen requires files, so it's not in static routes
        // Use Navigator.push with ShareSessionScreen(files: [...]) instead
        receive: (context) => const ReceiveScreen(),
        history: (context) => const HistoryScreen(),
        settings: (context) => const SettingsScreen(),
        help: (context) => const HelpScreen(),
        about: (context) => const AboutScreen(),
        qrScan: (context) => const QRScanScreen(),
      };
}
