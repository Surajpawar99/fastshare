enum TransferStatus { idle, transferring, paused, completed, failed }

enum TransferMethod { inApp, browser }

class TransferTask {
  final String id;
  final String fileName;
  final int totalBytes;
  final int bytesTransferred;
  final double speedMbps;
  final TransferStatus status;
  final String? errorMessage;
  final TransferMethod transferMethod;

  const TransferTask({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    this.bytesTransferred = 0,
    this.speedMbps = 0.0,
    this.status = TransferStatus.idle,
    this.errorMessage,
    this.transferMethod = TransferMethod.inApp,
  });

  double get progress {
    if (totalBytes == 0) return 0.0;
    return bytesTransferred / totalBytes;
  }

  TransferTask copyWith({
    int? bytesTransferred,
    double? speedMbps,
    TransferStatus? status,
    String? errorMessage,
    TransferMethod? transferMethod,
  }) {
    return TransferTask(
      id: id,
      fileName: fileName,
      totalBytes: totalBytes,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      speedMbps: speedMbps ?? this.speedMbps,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      transferMethod: transferMethod ?? this.transferMethod,
    );
  }
}
