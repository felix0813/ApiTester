import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';
import '../../services/sync_engine.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);

    IconData icon;
    Color color;
    String tooltip;

    switch (syncStatus) {
      case SyncStatus.idle:
        icon = Icons.cloud_done_outlined;
        color = Colors.green;
        tooltip = 'Synced';
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.blue;
        tooltip = 'Syncing...';
        break;
      case SyncStatus.error:
        icon = Icons.cloud_off_outlined;
        color = Colors.red;
        tooltip = 'Sync error';
        break;
      case SyncStatus.offline:
        icon = Icons.wifi_off_outlined;
        color = Colors.grey;
        tooltip = 'Offline';
        break;
    }

    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      tooltip: tooltip,
      onPressed: () {
        ref.read(syncEngineProvider).incrementalSync();
      },
    );
  }
}
