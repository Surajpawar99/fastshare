import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fastshare/features/history/presentation/providers/history_provider.dart';

final historyStateProvider = Provider<HistoryProvider>((ref) {
  return HistoryProvider();
});
