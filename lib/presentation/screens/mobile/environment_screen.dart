import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/environment_provider.dart';
import '../../../data/models/environment.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sync_status_indicator.dart';

class EnvironmentScreen extends ConsumerStatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  ConsumerState<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends ConsumerState<EnvironmentScreen> {
  void _showCreateDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.newEnvironment),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Environment name'),
          autofocus: true,
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
              final env = Environment(name: name);
              ref.read(environmentListProvider.notifier).save(env);
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Environment env) {
    final nameController = TextEditingController(text: env.name);
    final variableControllers = env.variables.entries
        .map((e) => (
              keyController: TextEditingController(text: e.key),
              valueController: TextEditingController(text: e.value),
            ))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit ${env.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Variables',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...variableControllers.asMap().entries.map((e) {
                    final i = e.key;
                    final ctrls = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ctrls.keyController,
                              decoration: const InputDecoration(
                                hintText: 'Key',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: ctrls.valueController,
                              decoration: const InputDecoration(
                                hintText: 'Value',
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setDialogState(() {
                                variableControllers.removeAt(i);
                              });
                            },
                            icon: const Icon(Icons.close, size: 16),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      setDialogState(() {
                        variableControllers.add((
                          keyController: TextEditingController(),
                          valueController: TextEditingController(),
                        ));
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(AppStrings.newVariable),
                  ),
                ],
              ),
            ),
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

                final variables = <String, String>{};
                for (final ctrls in variableControllers) {
                  final key = ctrls.keyController.text.trim();
                  if (key.isNotEmpty) {
                    variables[key] = ctrls.valueController.text;
                  }
                }

                final updated =
                    env.copyWith(name: name, variables: variables);
                ref.read(environmentListProvider.notifier).save(updated);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final envsAsync = ref.watch(environmentListProvider);
    final activeEnv = ref.watch(activeEnvironmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tabEnvironments),
        actions: const [
          SyncStatusIndicator(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: envsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (envs) {
          if (envs.isEmpty) {
            return EmptyState(
              icon: Icons.layers_outlined,
              message: AppStrings.noEnvironments,
              actionLabel: AppStrings.newEnvironment,
              onAction: _showCreateDialog,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: envs.length,
            itemBuilder: (context, index) {
              final env = envs[index];
              final isActive = env.id == activeEnv?.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _showEditDialog(env),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 20,
                              color: isActive
                                  ? Colors.green
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                env.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!isActive)
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(environmentListProvider.notifier)
                                      .setActive(env.id);
                                },
                                child: const Text('Activate'),
                              ),
                            PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'delete') {
                                  ref
                                      .read(environmentListProvider.notifier)
                                      .delete(env.id);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (env.variables.isNotEmpty) ...[
                          const Divider(height: 16),
                          ...env.variables.entries.map((e) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '{{${e.key}}}',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
