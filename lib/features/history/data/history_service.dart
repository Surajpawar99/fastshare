import 'package:hive/hive.dart';
import 'package:fastshare/features/history/domain/entities/history_item.dart';

/// HistoryService: Persistent storage for transfer history via Hive
///
/// Key Points:
/// 1. Box MUST be opened in main.dart before app runs
/// 2. Items persisted on BOTH sender and receiver sides:
///    - Sender saves: isSent=true (sent a file)
///    - Receiver saves: isSent=false (received a file)
/// 3. Deduplication: Transfer UUID (item.id) prevents duplicate saves
/// 4. Survives app restart via Hive file storage
/// 5. Safe empty-state: Returns empty list, never throws
///
/// Persistence Flow:
/// 1. Transfer completes → TransferController.markCompleted()
/// 2. _saveHistoryAsync() creates HistoryItem with transfer UUID
/// 3. HistoryProvider.addTransferToHistory() adds to Hive
/// 4. HistoryService.getAllHistory() loads on app restart
/// 5. Deduplication set rebuilt from persisted items
class HistoryService {
  static const String _boxName = 'historyBox';

  /// Get reference to Hive box (must already be open from main.dart)
  /// Throws: HiveError if box not opened in main.dart (initialization error)
  Box<HistoryItem> get _box {
    try {
      return Hive.box<HistoryItem>(_boxName);
    } catch (e) {
      throw HiveError(
        'History box not initialized. Ensure Hive.openBox<HistoryItem>("$_boxName") '
        'is called in main.dart before runApp(). Error: $e',
      );
    }
  }

  /// Save history entry to persistent storage
  ///
  /// Parameters:
  /// - item: HistoryItem with transfer UUID as ID
  ///
  /// Preconditions:
  /// - Called ONLY after successful transfer completion
  /// - Item ID must be transfer session UUID (from TransferTask)
  /// - Both sender and receiver call this separately
  ///
  /// Postconditions:
  /// - Entry persisted to device storage
  /// - Survives app restart
  /// - Accessible via getAllHistory()
  ///
  /// Safe: Does not throw if item already exists (overwrites)
  Future<void> addHistory(HistoryItem item) async {
    try {
      // Use item's UUID as key for O(1) lookup/delete operations
      // Overwrites if key already exists (idempotent)
      await _box.put(item.id, item);
    } catch (e) {
      print('HistoryService: Failed to save history item: $e');
      rethrow;
    }
  }

  /// Retrieve all history items, newest first
  ///
  /// Returns:
  /// - List of HistoryItem, sorted by timestamp (descending, most recent first)
  /// - Empty list if no transfers yet (safe, never throws)
  ///
  /// Behavior:
  /// - Safe for empty box: Returns empty list, no error
  /// - Safe for UI: Can be called repeatedly without side effects
  /// - Efficient: O(n log n) sort, acceptable for typical history sizes
  ///
  /// Called by:
  /// - HistoryProvider._initializeHistory() on app startup
  /// - HistoryProvider.addTransferToHistory() after each save
  List<HistoryItem> getAllHistory() {
    try {
      // Empty-safe: box.values is empty Iterable if no items
      if (_box.isEmpty) {
        return [];
      }

      final historyList = _box.values.toList();

      // Guard: skip if somehow got nulls (shouldn't happen with typed box)
      if (historyList.isEmpty) {
        return [];
      }

      // Sort: most recent transfers first (descending timestamp)
      historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return historyList;
    } catch (e) {
      print('HistoryService: Error retrieving history: $e');
      return []; // Graceful degradation: empty state better than crash
    }
  }

  /// Delete specific history entry by transfer UUID
  ///
  /// Parameters:
  /// - id: Transfer UUID to delete
  ///
  /// Safe: Does not throw if key not found
  /// Called by: HistoryScreen "delete" action
  Future<void> deleteHistoryItem(String id) async {
    try {
      if (id.isEmpty) {
        return; // Guard: skip empty IDs
      }
      await _box.delete(id);
    } catch (e) {
      print('HistoryService: Failed to delete history item: $e');
    }
  }

  /// Clear all history entries
  ///
  /// Safe: Does not throw if box already empty
  /// Called by: HistoryScreen "Clear All" button
  /// Warning: This is destructive and irreversible
  Future<void> clearHistory() async {
    try {
      await _box.clear();
    } catch (e) {
      print('HistoryService: Failed to clear history: $e');
    }
  }

  /// Get count of history items
  /// Safe: Returns 0 if box empty or error
  int getHistoryCount() {
    try {
      return _box.length;
    } catch (e) {
      print('HistoryService: Error getting history count: $e');
      return 0;
    }
  }

  /// Check if transfer already saved by UUID
  /// Safe: Returns false if error or not found
  bool isTransferSaved(String transferId) {
    try {
      return _box.containsKey(transferId);
    } catch (e) {
      print('HistoryService: Error checking transfer: $e');
      return false;
    }
  }
}
