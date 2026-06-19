import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/collection_provider.dart';
import '../../providers/request_provider.dart';
import '../../../data/models/collection.dart';
import '../../../data/models/api_request.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/empty_state.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  void _showCreateDialog({String? parentId}) {
    final nameController = TextEditingController();
    String selectedType = 'Folder';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create New'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Folder', label: Text('Folder')),
                  ButtonSegment(value: 'Request', label: Text('Request')),
                ],
                selected: {selectedType},
                onSelectionChanged: (v) {
                  setDialogState(() => selectedType = v.first);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: selectedType == 'Folder'
                      ? 'Folder name'
                      : 'Request name',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                if (selectedType == 'Folder') {
                  final folder = CollectionItem(
                    name: name,
                    parentId: parentId,
                    type: CollectionType.folder,
                  );
                  ref.read(collectionTreeProvider.notifier).save(folder);
                } else {
                  final request = ApiRequest(name: name);
                  final item = CollectionItem(
                    name: name,
                    parentId: parentId,
                    type: CollectionType.request,
                    requestId: request.id,
                  );
                  ref.read(requestRepositoryProvider).save(request);
                  ref.read(collectionTreeProvider.notifier).save(item);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _loadRequest(String requestId) {
    final requestRepo = ref.read(requestRepositoryProvider);
    requestRepo.getById(requestId).then((req) {
      if (req != null && mounted) {
        ref.read(currentRequestProvider.notifier).loadRequest(req);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionTreeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tabCollections),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: 'Run Collection',
            onPressed: () {
              final rootItems = ref.read(collectionTreeProvider).valueOrNull
                  ?.where((c) => c.parentId == null)
                  .toList();
              if (rootItems != null && rootItems.isNotEmpty) {
                context.go('/runner/${rootItems.first.id}');
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(),
        child: const Icon(Icons.add),
      ),
      body: collectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (items) {
          final rootItems = items.where((c) => c.parentId == null).toList();

          if (rootItems.isEmpty) {
            return EmptyState(
              icon: Icons.folder_outlined,
              message: AppStrings.noCollections,
              actionLabel: AppStrings.newCollection,
              onAction: () => _showCreateDialog(),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rootItems.length,
            onReorder: (oldIndex, newIndex) {
              ref.read(collectionTreeProvider.notifier)
                  .reorderRootItems(oldIndex, newIndex);
            },
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 2,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final item = rootItems[index];
              return _CollectionTreeTile(
                key: ValueKey(item.id),
                item: item,
                allItems: items,
                onTap: () {
                  if (item.isRequest && item.requestId != null) {
                    _loadRequest(item.requestId!);
                  }
                },
                onDelete: (id) {
                  ref.read(collectionTreeProvider.notifier).delete(id);
                },
                onCreateChild: (parentId) =>
                    _showCreateDialog(parentId: parentId),
              );
            },
          );
        },
      ),
    );
  }
}

class _CollectionTreeTile extends StatelessWidget {
  final CollectionItem item;
  final List<CollectionItem> allItems;
  final VoidCallback? onTap;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onCreateChild;

  const _CollectionTreeTile({
    super.key,
    required this.item,
    required this.allItems,
    this.onTap,
    required this.onDelete,
    required this.onCreateChild,
  });

  @override
  Widget build(BuildContext context) {
    final children = allItems.where((c) => c.parentId == item.id).toList();
    final canExpand = item.isFolder && children.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              item.isFolder
                  ? (canExpand ? Icons.folder : Icons.folder_outlined)
                  : Icons.http,
              color: item.isFolder ? Colors.amber.shade700 : AppColors.forMethod('GET'),
              size: 22,
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            onTap: item.isFolder && canExpand ? null : onTap,
            trailing: PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'delete':
                    onDelete(item.id);
                    break;
                  case 'add':
                    onCreateChild(item.id);
                    break;
                }
              },
              itemBuilder: (context) => [
                if (item.isFolder)
                  const PopupMenuItem(
                    value: 'add',
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 18),
                        SizedBox(width: 8),
                        Text('Add inside'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (canExpand)
            ...children.map((child) => Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: _CollectionTreeTile(
                    item: child,
                    allItems: allItems,
                    onTap: onTap,
                    onDelete: onDelete,
                    onCreateChild: onCreateChild,
                  ),
                )),
        ],
      ),
    );
  }
}
