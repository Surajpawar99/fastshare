import 'package:hive/hive.dart';

part 'history_item.g.dart'; // This file is generated automatically

@HiveType(typeId: 0)
class HistoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fileName;

  @HiveField(2)
  final int fileSize;

  @HiveField(3)
  final bool isSent; // true = Sent, false = Received

  @HiveField(4)
  final String status; // 'completed', 'failed', 'cancelled'

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final String transferMethod; // 'InApp' or 'Browser'

  HistoryItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.isSent,
    required this.status,
    required this.timestamp,
    this.transferMethod = 'InApp',
  });

  // Factory constructor for creating an instance from a JSON map (optional utility)
  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      isSent: json['isSent'] as bool,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      transferMethod: json['transferMethod'] as String? ?? 'InApp',
    );
  }

  // Convert to Map (optional utility)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileSize': fileSize,
      'isSent': isSent,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'transferMethod': transferMethod,
    };
  }
}
