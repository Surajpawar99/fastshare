import 'package:flutter/material.dart';
import 'package:fastshare/features/history/data/history_service.dart';
import 'package:fastshare/features/history/domain/entities/history_item.dart';

// Note: Ensure your Hive adapter is registered in main.dart before running this.

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HistoryService _historyService = HistoryService();

  // Future state for loading data
  late Future<List<HistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    if (!mounted) return;
    setState(() {
      _historyFuture = Future.value(_historyService.getAllHistory());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- FILTER LOGIC ---
  List<HistoryItem> _filterList(List<HistoryItem> allItems, int tabIndex) {
    if (tabIndex == 0) return allItems; // All
    if (tabIndex == 1) {
      return allItems.where((item) => item.isSent).toList(); // Sent
    }
    return allItems.where((item) => !item.isSent).toList(); // Received
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transfer History"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.pressed)
                ? theme.colorScheme.primary.withOpacity(0.1)
                : null,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Sent"),
            Tab(text: "Received"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: "Clear History",
            onPressed: () => _showClearAllDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<List<HistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final allItems = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildHistoryList(allItems, 0),
              _buildHistoryList(allItems, 1),
              _buildHistoryList(allItems, 2),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(List<HistoryItem> allItems, int tabIndex) {
    final items = _filterList(allItems, tabIndex);

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _HistoryCard(
            item: items[index],
            onDelete: () async {
              await _historyService.deleteHistoryItem(items[index].id);
              _loadData(); // Refresh list
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "No transfers yet",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear History?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _historyService.clearHistory();
              _loadData();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onDelete;

  const _HistoryCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Visual Helpers
    final isReceived = !item.isSent;
    final isFailed = item.status == 'failed';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isFailed) {
      statusColor = theme.colorScheme.error;
      statusText = "Failed";
      statusIcon = Icons.error_outline;
    } else if (isReceived) {
      statusColor = Colors.blue;
      statusText = "Received";
      statusIcon = Icons.arrow_downward_rounded;
    } else {
      statusColor = Colors.green;
      statusText = "Sent";
      statusIcon = Icons.arrow_upward_rounded;
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _showOptionsSheet(context, theme),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 1. File Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getFileIcon(item.fileName),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),

              // 2. Main Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_formatBytes(item.fileSize)} • ${_formatDate(item.timestamp)}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Status Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'png', 'jpeg'].contains(ext)) return Icons.image_rounded;
    if (['mp4', 'mov', 'avi'].contains(ext)) return Icons.play_circle_rounded;
    if (['mp3', 'wav'].contains(ext)) return Icons.audiotrack_rounded;
    if (['apk'].contains(ext)) return Icons.android_rounded;
    return Icons.description_rounded;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    final kb = bytes / 1024;
    if (kb < 1024) return "${kb.toStringAsFixed(1)} KB";
    final mb = kb / 1024;
    return "${mb.toStringAsFixed(1)} MB";
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  void _showOptionsSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Delete from history',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context); // Close sheet
                onDelete(); // Call parent delete action
              },
            ),
          ],
        ),
      ),
    );
  }
}
