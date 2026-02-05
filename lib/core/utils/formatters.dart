import 'package:intl/intl.dart';

String formatBytes(int bytes, {int decimals = 2}) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (bytes.toString().length - 1) ~/ 3;
  return '${(bytes / (1 << (i * 10))).toStringAsFixed(decimals)} ${suffixes[i]}';
}

String formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);

  final dateToCompare = DateTime(timestamp.year, timestamp.month, timestamp.day);

  if (dateToCompare == today) {
    return DateFormat.jm().format(timestamp); // e.g., 5:30 PM
  } else if (dateToCompare == yesterday) {
    return 'Yesterday';
  } else {
    return DateFormat.yMd().format(timestamp); // e.g., 12/31/2023
  }
}
