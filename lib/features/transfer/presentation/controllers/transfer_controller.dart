import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import '../../domain/entities/transfer_task.dart';
import 'package:fastshare/features/history/domain/entities/history_item.dart';
import 'package:fastshare/features/history/presentation/providers/history_state_provider.dart';
import 'package:fastshare/features/transfer/data/services/file_receiver.dart';

final transferControllerProvider =
    NotifierProvider<TransferController, TransferTask?>(
  () => TransferController(),
);

class TransferController extends Notifier<TransferTask?> {
  final Set<String> _historySavedIds = {};
  FileTransferClient? _client;

  @override
  TransferTask? build() {
    // Clean up client on dispose
    ref.onDispose(() {
      _client?.cancelDownload();
    });
    return null;
  }
  
  // ... (Existing Getters)
  String get speedLabel {
    if (state == null) return "0.0 MB/s";
    return "${state!.speedMbps.toStringAsFixed(1)} MB/s";
  }

  String get progressPercentage {
    if (state == null) return "0%";
    return "${(state!.progress * 100).toStringAsFixed(1)}%";
  }

  void startSending(String fileName, int totalBytes) {
    state = TransferTask(
      id: const Uuid().v4(),
      fileName: fileName,
      totalBytes: totalBytes,
      status: TransferStatus.transferring,
      transferMethod: TransferMethod.inApp,
    );
  }

  Future<void> startReceiving(String ip, int port) async {
    try {
      // 1. Get Download Directory
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download/FastShare');
      } else {
        downloadDir = await getDownloadsDirectory();
        downloadDir = Directory('${downloadDir!.path}/FastShare');
      }
      
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // 2. Fetch File Info
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://$ip:$port/info'));
      final response = await request.close();
      
      if (response.statusCode != 200) throw Exception("Could not get file info");
      
      final jsonStr = await response.transform(utf8.decoder).join();
      final List<dynamic> files = json.decode(jsonStr);
      
      if (files.isEmpty) throw Exception("No files shared");
      
      // For simplicity, download first file (or create zip logic later)
      final fileData = files[0];
      final String fileName = fileData['name'];
      final int fileSize = fileData['size'];
      final int fileId = fileData['id'];

      // 3. Init State
      state = TransferTask(
        id: const Uuid().v4(),
        fileName: fileName,
        totalBytes: fileSize,
        status: TransferStatus.transferring,
        transferMethod: TransferMethod.inApp,
      );

      // 4. Start Download
      _client = FileTransferClient(
        onProgress: (bytes, speed) {
          updateProgress(bytesTransferred: bytes, speedMbps: speed);
        },
        onComplete: (path) {
          markCompleted(isSent: false);
        },
        onError: (err) {
          markFailed(err);
        },
      );
      
      await _client!.downloadFile(
        ip, 
        port, 
        DownloadTask(
          id: fileId,
          savePath: downloadDir.path,
          filename: fileName,
          fileSize: fileSize,
        ),
      );

    } catch (e) {
      markFailed("Start failed: $e");
    }
  }

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

  void markCompleted({required bool isSent}) {
    final task = state;
    if (task == null) return;

    if (!_historySavedIds.contains(task.id)) {
      _historySavedIds.add(task.id);
      _saveHistoryAsync(task, isSent);
    }

    state = task.copyWith(status: TransferStatus.completed);
  }

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

      ref.read(historyStateProvider).addTransferToHistory(historyItem);
    } catch (e) {
      print('History save failed: $e');
    }
  }

  void markFailed([String? error]) {
    if (state == null) return;
    state = state!.copyWith(
      status: TransferStatus.failed,
      errorMessage: error ?? 'Transfer failed',
      speedMbps: 0,
    );
  }

  Future<void> pause() async {
    if (state == null) return;
    state = state!.copyWith(status: TransferStatus.paused);
    await _client?.pauseDownload();
  }

  Future<void> resume() async {
    if (state == null) return;
    state = state!.copyWith(status: TransferStatus.transferring);
    await _client?.resumeDownload();
  }
  
  void updateTransferMethod(TransferMethod method) {
    if (state == null) return;
    state = state!.copyWith(transferMethod: method);
  }

  void reset() {
    if (state != null) {
      _historySavedIds.remove(state!.id);
      _client?.cancelDownload();
      _client = null;
    }
    state = null;
  }
}
