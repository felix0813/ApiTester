import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/collection_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/environment_provider.dart';
import '../../widgets/method_selector.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/collection.dart';

class DesktopShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  const DesktopShellScreen({super.key, required this.child});

  @override
  ConsumerState<DesktopShellScreen> createState() => _DesktopShellScreenState();
}

class _DesktopShellScreenState extends ConsumerState<DesktopShellScreen> {
  String _selectedRequestId = '';

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionTreeProvider);
    final request = ref.watch(currentRequestProvider);
    final activeEnv = ref.watch(activeEnvironmentProvider);

    return Scaffold(
      body: Row(
        children: [
          // Left sidebar — collection tree
          SizedBox(
            width: 260,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App title
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text('API Tester',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  // Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search collections...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Collection tree
                  Expanded(
                    child: collectionsAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (e, _) => const Center(child: Text('Error')),
                      data: (items) {
                        final roots = items.where((c) => c.parentId == null).toList();
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: roots.length,
                          itemBuilder: (ctx, i) =>
                              _buildTreeItem(roots[i], items),
                        );
                      },
                    ),
                  ),
                  // Bottom actions
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          tooltip: 'New',
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 20),
                          tooltip: 'Settings',
                          onPressed: () => context.go('/profile'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const VerticalDivider(width: 1),

          // Right content area
          Expanded(
            child: Column(
              children: [
                // Top URL toolbar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: const Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      MethodSelector(
                        selectedMethod: request.method,
                        onChanged: (m) =>
                            ref.read(currentRequestProvider.notifier).setMethod(m),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Enter URL...',
                            isDense: true,
                          ),
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 14),
                          controller: TextEditingController(text: request.url)
                            ..selection = TextSelection.collapsed(
                                offset: request.url.length),
                          onChanged: (v) =>
                              ref.read(currentRequestProvider.notifier).setUrl(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => ref
                            .read(responseProvider.notifier)
                            .sendRequest(activeEnv?.variables),
                        child: const Text('Send'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => context.go('/environments'),
                        child: const Text('Environments'),
                      ),
                    ],
                  ),
                ),
                // Main content (child router page)
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeItem(CollectionItem item, List<CollectionItem> allItems) {
    final children = allItems.where((c) => c.parentId == item.id).toList();

    if (item.isFolder) {
      return ExpansionTile(
        leading: const Icon(Icons.folder_outlined, size: 20),
        title: Text(item.name, style: const TextStyle(fontSize: 13)),
        initiallyExpanded: true,
        children: children.map((c) => _buildTreeItem(c, allItems)).toList(),
      );
    }

    return ListTile(
      leading: Text(item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColors.forMethod('GET'),
          )),
      title: Text(item.name, style: const TextStyle(fontSize: 13)),
      dense: true,
      selected: item.requestId == _selectedRequestId,
      onTap: () {
        setState(() => _selectedRequestId = item.requestId ?? '');
        if (item.requestId != null) {
          _loadRequest(item.requestId!);
        }
      },
    );
  }

  void _loadRequest(String id) {
    ref.read(requestRepositoryProvider).getById(id).then((req) {
      if (req != null) {
        ref.read(currentRequestProvider.notifier).loadRequest(req);
      }
    });
  }
}
