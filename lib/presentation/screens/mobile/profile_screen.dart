import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/history_entry.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/sync_status_indicator.dart';
import 'auth_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyListProvider);
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(currentUserProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tabProfile),
        actions: const [
          SyncStatusIndicator(),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isAuthenticated
                    ? Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            child: Text(
                              (user?.email ?? '?')[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user?.email ?? '',
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600)),
                                const Text('Signed in',
                                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await ref.read(authServiceProvider).signOut();
                            },
                            child: const Text('Sign Out'),
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              child: Icon(
                                Icons.person_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Local Mode',
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w600)),
                                  Text('Sign in to sync your data',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
              ),
            ),
          ),

          // Theme settings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Theme'),
                    subtitle: _buildThemeSubtitle(themeMode),
                    trailing: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                        ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (mode) {
                        ref.read(themeModeProvider.notifier).setTheme(mode.first);
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStateProperty.all(
                          const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Import section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text('Import Collections'),
                subtitle: const Text('Import from Postman or OpenAPI'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.go('/import');
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // History section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Request History',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: () {
                    ref.read(historyListProvider.notifier).clearAll();
                  },
                  icon: const Icon(Icons.delete_sweep, size: 16),
                  label: const Text(AppStrings.clearHistory,
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // History list
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history,
                    message: AppStrings.noHistory,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _HistoryTile(entry: entry);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSubtitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return const Text('Light', style: TextStyle(fontSize: 12));
      case ThemeMode.dark:
        return const Text('Dark', style: TextStyle(fontSize: 12));
      case ThemeMode.system:
        return const Text('Follow system', style: TextStyle(fontSize: 12));
    }
  }
}

class _HistoryTile extends ConsumerWidget {
  final HistoryEntry entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodColor = AppColors.forMethod(entry.method);

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final historyNotifier = ref.read(historyListProvider.notifier);
          final request = historyNotifier.getRequestFromHistory(entry);
          if (request != null) {
            ref.read(currentRequestProvider.notifier).loadRequest(request);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: methodColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.method,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: methodColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.url.isEmpty ? '(no URL)' : entry.url,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(entry.sentAt),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              if (entry.statusCode != null)
                StatusBadge(statusCode: entry.statusCode),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
