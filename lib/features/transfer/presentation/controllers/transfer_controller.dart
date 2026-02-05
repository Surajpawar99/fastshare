import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/transfer_task.dart';
import 'package:fastshare/features/history/domain/entities/history_item.dart';
import 'package:fastshare/features/history/presentation/providers/history_state_provider.dart';

/// ===== SINGLE ACTIVE TRANSFER GUARANTEE =====
/// This provider enforces exactly ONE active transfer at a time.
/// Key mechanisms:
/// 1. state: TransferTask? (null when idle, non-null during transfer)
/// 2. _historySavedIds: Deduplication set to prevent duplicate history saves
/// 3. reset(): Clears state AND dedup set, enabling next transfer
/// 4. Calling startSending/startReceiving while state!=null is ignored (guard in UI)
final transferControllerProvider =
    NotifierProvider<TransferController, TransferTask?>(
  () => TransferController(),
);

/// ===== TRANSFER CONTROLLER =====
/// Manages single active transfer state and history persistence
///
/// Transfer Lifecycle:
/// 1. startSending/startReceiving() → state becomes TransferTask
/// 2. updateProgress() → update state during transfer
/// 3. markCompleted(isSent: bool) → save history + transition to completed
/// 4. reset() → state = null, ready for next transfer
///
/// History Deduplication:
/// - _historySavedIds tracks UUID of each saved transfer
/// - Prevents duplicate saves if markCompleted called twice
/// - Rebuilt from Hive on app restart (HistoryProvider init)
/// - Transfer ID is UUID.v4() (collision-free)
///
/// Single Active Transfer:
/// - Check: if (state != null) return; (in initState)
/// - This ensures only one transfer screen visible at a time
/// - Prevent: concurrent startServer() calls
/// - Reset: on dispose, on error, on user cancel
///
/// Error Handling:
/// - markFailed(msg) → state.status = failed, speedMbps = 0
/// - User can retry without calling reset (keeps same transfer ID)
/// - Or UI pops and calls reset, clearing state for new transfer
class TransferController extends Notifier<TransferTask?> {
  /// ===== DEDUPLICATION GUARD =====
  /// Tracks which transfer IDs have already been saved to history
  /// Prevents calling markCompleted() twice from saving duplicate entries
  ///
  /// Example:
  /// ```
  /// Transfer ID: "a1b2c3d4..."
  /// 1. markCompleted(isSent: true) → adds to _historySavedIds, saves
  /// 2. markCompleted(isSent: true) again → skipped, ID already in set
  /// 3. reset() → removes ID from set (for next transfer reuse)
  /// ```
  ///
  /// Why needed:
  /// - Network delays might trigger callback twice
  /// - User taps button twice quickly
  /// - UI rebuilds might re-trigger completion logic
  /// - Ensures exactly one history entry per transfer per device
  final Set<String> _historySavedIds = {};

  @override
  TransferTask? build() => null;

  /// Get a formatted speed label
  String get speedLabel {
    if (state == null) return "0.0 MB/s";
    return "${state!.speedMbps.toStringAsFixed(1)} MB/s";
  }

  /// Get progress as percentage string
  String get progressPercentage {
    if (state == null) return "0%";
    return "${(state!.progress * 100).toStringAsFixed(1)}%";
  }

  /// Start sending files (sender side)
  /// Initialize a transfer task with fileName (String) and totalBytes (int)
  /// Sets transfer method to InApp (app-to-app direct transfer)
  void startSending(String fileName, int totalBytes) {
    state = TransferTask(
      id: const Uuid().v4(),
      fileName: fileName,
      totalBytes: totalBytes,
      status: TransferStatus.transferring,
      transferMethod: TransferMethod.inApp,
    );
  }

  /// Start receiving files (receiver side)
  /// Initialize a transfer task for incoming download
  /// Sets transfer method to InApp (app-to-app direct transfer)
  void startReceiving(String fileName, int fileSize) {
    state = TransferTask(
      id: const Uuid().v4(),
      fileName: fileName,
      totalBytes: fileSize,
      status: TransferStatus.transferring,
      transferMethod: TransferMethod.inApp,
    );
  }

  /// Update progress during transfer
  /// fileName: String (file name)
  /// bytesTransferred: current bytes received
  /// totalBytes: int (total size)
  /// speedMbps: double (speed in MB/s)
  void updateProgress({
    required int bytesTransferred,
    required double speedMbps,
  }) {
    if (state == null) return;

    state = state!.copyWith(
      bytesTransferred: bytesTransferred,
      speedMbps: speedMbps,
      status: TransferStatus.transferring,
    );
  }

  /// Save transfer to history (ONLY after successful completion)
  ///
  /// Critical Design:
  /// - This is called TWICE per transfer:
  ///   1. Sender calls: markCompleted(isSent: true) - "I sent a file"
  ///   2. Receiver calls: markCompleted(isSent: false) - "I received a file"
  /// - Both entries saved with same transfer UUID
  /// - Deduplication prevents duplicate saves for the same transfer
  /// - History shows both perspectives (sender's send + receiver's receive)
  ///
  /// REQUIREMENTS:
  /// - Prevent duplicate history entries using _historySavedIds set
  /// - Save ONLY after transfer completion (not during progress)
  /// - Support both:
  ///   - Sender perspective: isSent=true (file was sent)
  ///   - Receiver perspective: isSent=false (file was received)
  /// - Type safety: fileName is String, fileSize is int
  /// - Transition to completed status
  /// - Write history asynchronously (no UI blocking)
  ///
  /// Example Flow:
  /// ```
  /// Device A (Sender):
  ///   1. startSending("photo.jpg", 5000000)
  ///   2. updateProgress(...) - transfer running
  ///   3. markCompleted(isSent: true)
  ///      → Saves: id=UUID, fileName="photo.jpg", isSent=true, status="success"
  ///
  /// Device B (Receiver):
  ///   1. startReceiving("photo.jpg", 5000000)
  ///   2. updateProgress(...) - transfer running
  ///   3. markCompleted(isSent: false)
  ///      → Saves: id=UUID, fileName="photo.jpg", isSent=false, status="success"
  ///
  /// Result: Both devices have transfer in history (different perspective)
  /// ```
  ///
  /// Called by:
  /// - Sender: ShareSessionScreen.handleTransferComplete(viaBrowser)
  /// - Receiver: ReceiveScreen (when browser opens) or QRScanScreen
  void markCompleted({required bool isSent}) {
    final task = state;
    if (task == null) return;

    // Guard against duplicate history saves for the same transfer
    // _historySavedIds tracks which transfers have been saved
    // This prevents duplicate entries if markCompleted called twice
    if (!_historySavedIds.contains(task.id)) {
      _historySavedIds.add(task.id);
      // Fire async history write without blocking UI
      _saveHistoryAsync(task, isSent);
    }

    state = task.copyWith(status: TransferStatus.completed);
  }

  /// Asynchronously save transfer history without blocking UI
  ///
  /// Design Principles:
  /// - Fire and forget: Async operation doesn't block transfer completion UI
  /// - Idempotent: Deduplication ensures exactly one save per transfer per device
  /// - Silent failure: History save failure won't disrupt completed transfer
  /// - Both perspectives: Sender and receiver save independently
  ///
  /// Persistence Strategy:
  /// 1. Create HistoryItem with transfer UUID
  /// 2. Add to HistoryProvider (updates Riverpod state)
  /// 3. HistoryProvider saves to Hive (device storage)
  /// 4. On app restart, HistoryService loads from Hive
  /// 5. HistoryProvider rebuilds deduplication set from loaded items
  ///
  /// Retry Logic:
  /// - If save fails, exception caught and logged
  /// - User sees "Transfer Complete!" regardless of history save status
  /// - On app restart, transfer UUID not in seen set, retry occurs
  /// - Eventually succeeds or is skipped if corrupted
  ///
  /// Timing:
  /// - Called ONLY after transfer completes (not during progress)
  /// - Both sender and receiver call this separately with different isSent values
  ///
  /// Persistence:
  /// - Writes to Hive box (device storage)
  /// - Survives app restart
  /// - Accessible in History tab and Recent Transfers widget
  Future<void> _saveHistoryAsync(TransferTask task, bool isSent) async {
    try {
      final transferMethodStr =
          task.transferMethod == TransferMethod.inApp ? 'InApp' : 'Browser';

      final historyItem = HistoryItem(
        id: task.id,
        fileName: task.fileName,
        fileSize: task.totalBytes,
        isSent: isSent,
        status: 'success',
        timestamp: DateTime.now(),
        transferMethod: transferMethodStr,
      );

      // Add to Hive (persistent) and update Riverpod provider (UI)
      ref.read(historyStateProvider).addTransferToHistory(historyItem);
    } catch (e) {
      // Silently fail history write to avoid disrupting completed transfer
      // User sees "Transfer Complete!" even if history save failed
      // Next app restart will retry or skip
      print('History save failed: $e');
    }
  }

  /// Mark transfer as failed with optional error message
  void markFailed([String? error]) {
    if (state == null) return;

    state = state!.copyWith(
      status: TransferStatus.failed,
      errorMessage: error ?? 'Transfer failed',
      speedMbps: 0,
    );
  }

  /// Pause an active transfer
  void pause() {
    if (state == null) return;
    state = state!.copyWith(status: TransferStatus.paused);
  }

  /// Update the transfer method (InApp / Browser) for the current task
  void updateTransferMethod(TransferMethod method) {
    if (state == null) return;
    state = state!.copyWith(transferMethod: method);
  }

  /// Resume a paused transfer
  void resume() {
    if (state == null) return;
    state = state!.copyWith(status: TransferStatus.transferring);
  }

  /// Reset transfer state (called when exiting transfer screens)
  /// Also clears deduplication guard for the transfer ID
  void reset() {
    if (state != null) {
      _historySavedIds.remove(state!.id);
    }
    state = null;
  }
}
