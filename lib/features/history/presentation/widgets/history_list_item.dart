import 'package:flutter/material.dart';
import 'package:fastshare/features/history/domain/entities/history_item.dart';
import 'package:fastshare/core/utils/formatters.dart';

class HistoryListItem extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback? onTap;

  const HistoryListItem({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSent = item.isSent;
    final icon =
        isSent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final color = isSent
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          child: Icon(icon, size: 20),
        ),
        title: Text(
          item.fileName,
          style: theme.textTheme.bodyLarge,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${formatBytes(item.fileSize)} • ${item.status}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        trailing: Text(
          formatTimestamp(item.timestamp),
          style: theme.textTheme.bodySmall,
        ),
        onTap: onTap,
      ),
    );
  }
}
