import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:fastshare/features/history/data/history_service.dart';
import 'package:fastshare/features/history/domain/entities/history_item.dart';

/// HistoryProvider: Manages transfer history state and persistence
///
/// Key Responsibilities:
/// 1. Load history from Hive on startup (empty-safe)
/// 2. Deduplicate by transfer UUID to prevent duplicate saves
/// 3. Provide recent transfers (last 3 successful)
/// 4. Provide full history list (filtered by status)
/// 5. Add new transfers with idempotent behavior
///
/// Design Principles:
/// - Deduplication uses transfer ID (UUID), not file name + timestamp
/// - Safe for app restarts: _seenTransfers rebuilt from Hive on init
/// - Safe for rapid retries: UUID prevents duplicate entries
/// - Safe for empty state: Returns empty list, never throws
class HistoryProvider extends ChangeNotifier {
  final HistoryService _historyService = HistoryService();
  List<HistoryItem> _history = [];

  /// Track transfer IDs already in history to prevent duplicates
  /// Rebuilt from Hive on startup, not persisted separately
  final Set<String> _seenTransferIds = {};

  HistoryProvider() {
    _initializeHistory();
  }

  /// Get all history items (unmodifiable, sorted newest first)
  /// Safe: Returns empty list if no history
  List<HistoryItem> get allHistory => List.unmodifiable(_history);

  /// Get last 3 successful transfers only (for Recent Transfers widget)
  /// Safe: Returns empty list if no successful transfers
  List<HistoryItem> get recentTransfers {
    try {
      final successfulTransfers =
          _history.where((item) => item.status == 'success').toList();

      // Return at most 3, most recent first
      return successfulTransfers.sublist(0, min(3, successfulTransfers.length));
    } catch (e) {
      print('Error getting recent transfers: $e');
      return [];
    }
  }

  /// Initialize history from Hive on app startup
  /// Safe: Handles empty box, corrupted items, gracefully skips on error
  void _initializeHistory() {
    try {
      _history = _historyService.getAllHistory();

      // Build deduplication set from existing items
      // This ensures app restart doesn't create duplicates
      for (var item in _history) {
        if (item.id.isNotEmpty) {
          _seenTransferIds.add(item.id);
        }
      }
    } catch (e) {
      print('Error initializing history: $e');
      _history = [];
      _seenTransferIds.clear();
    }
  }

  /// Add a new transfer to history, preventing duplicates via transfer UUID
  ///
  /// Behavior:
  /// - Idempotent: Calling twice with same item ID only saves once
  /// - Safe: Handles null/empty items gracefully
  /// - Async-safe: UI updates via notifyListeners()
  ///
  /// Called by:
  /// - Sender: After successful send (isSent=true)
  /// - Receiver: After successful receive (isSent=false)
  /// - Both save their perspective as separate history entries
  void addTransferToHistory(HistoryItem item) {
    try {
      // Guard: check if already saved by transfer ID
      if (item.id.isEmpty || _seenTransferIds.contains(item.id)) {
        return; // Already saved, prevent duplicate
      }

      // Mark as seen before saving (prevents race conditions)
      _seenTransferIds.add(item.id);

      // Save to persistent storage (Hive)
      _historyService.addHistory(item);

      // Reload from storage to ensure consistency
      _history = _historyService.getAllHistory();

      // Notify UI to update
      notifyListeners();
    } catch (e) {
      // Silently fail: don't disrupt transfer completion
      // History may be partially saved, retry on app restart
      print('Failed to add transfer to history: $e');
      // Remove from seen set to retry on next attempt
      _seenTransferIds.remove(item.id);
    }
  }
}
