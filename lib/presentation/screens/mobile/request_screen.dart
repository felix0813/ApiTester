import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/request_provider.dart';
import '../../providers/environment_provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/request_body.dart';
import '../../../data/models/auth_config.dart';
import '../../widgets/method_selector.dart';
import '../../widgets/kv_editor.dart';
import '../../widgets/json_editor_widget.dart';
import '../../widgets/response_viewer.dart';
import '../../widgets/auth_config_widget.dart';
import '../../widgets/script_editor_widget.dart';

class RequestScreen extends ConsumerStatefulWidget {
  const RequestScreen({super.key});

  @override
  ConsumerState<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends ConsumerState<RequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _requestTabController;

  @override
  void initState() {
    super.initState();
    _requestTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _requestTabController.dispose();
    super.dispose();
  }

  void _showScriptsDialog(dynamic request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Scripts',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Pre-request'),
                  Tab(text: 'Tests'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ScriptEditorWidget(
                      script: request.preRequestScript ?? '',
                      label: 'Pre-request Script',
                      onChanged: (v) {
                        ref.read(currentRequestProvider.notifier).updateRequest(
                              (r) => r.copyWith(preRequestScript: v),
                            );
                      },
                    ),
                    ScriptEditorWidget(
                      script: request.testsScript ?? '',
                      label: 'Tests Script',
                      onChanged: (v) {
                        ref.read(currentRequestProvider.notifier).updateRequest(
                              (r) => r.copyWith(testsScript: v),
                            );
                      },
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

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(currentRequestProvider);
    final responseState = ref.watch(responseProvider);
    final activeEnv = ref.watch(activeEnvironmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tabRequest),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'scripts':
                  _showScriptsDialog(request);
                  break;
                case 'reset':
                  ref.read(currentRequestProvider.notifier).reset();
                  ref.read(responseProvider.notifier).clearResponse();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'scripts',
                child: Row(
                  children: [
                    Icon(Icons.code, size: 20),
                    SizedBox(width: 12),
                    Text('Scripts'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 12),
                    Text('Reset'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // URL bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                MethodSelector(
                  selectedMethod: request.method,
                  onChanged: (method) {
                    ref.read(currentRequestProvider.notifier).setMethod(method);
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: request.url)
                      ..selection =
                          TextSelection.collapsed(offset: request.url.length),
                    onChanged: (url) {
                      ref.read(currentRequestProvider.notifier).setUrl(url);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Enter URL',
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: responseState.isLoading
                      ? null
                      : () {
                          ref.read(responseProvider.notifier).sendRequest(
                                activeEnv?.variables,
                              );
                        },
                  child: responseState.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(AppStrings.send),
                ),
              ],
            ),
          ),

          // Request config tabs (4 tabs: Params, Headers, Body, Auth)
          TabBar(
            controller: _requestTabController,
            tabs: const [
              Tab(text: 'Params'),
              Tab(text: 'Headers'),
              Tab(text: 'Body'),
              Tab(text: 'Auth'),
            ],
            labelStyle: const TextStyle(fontSize: 13),
          ),

          // Request config content
          Expanded(
            flex: 1,
            child: TabBarView(
              controller: _requestTabController,
              children: [
                _buildParamsTab(request),
                _buildHeadersTab(request),
                _buildBodyTab(request),
                _buildAuthTab(request),
              ],
            ),
          ),

          // Divider and response section
          const Divider(height: 1),
          Expanded(
            flex: 2,
            child: ResponseViewer(
              response: responseState.response,
              isLoading: responseState.isLoading,
              error: responseState.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamsTab(dynamic request) {
    final Map<String, String> params = Map<String, String>.from(request.queryParams ?? {});
    final List<KvEntry> entries = params.entries
        .map((e) => KvEntry(key: e.key, value: e.value))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: KvEditor(
        entries: entries,
        addButtonLabel: AppStrings.addParam,
        onChanged: (updated) {
          final map = <String, String>{};
          for (final e in updated) {
            if (e.key.isNotEmpty) {
              map[e.key] = e.value;
            }
          }
          ref.read(currentRequestProvider.notifier).updateRequest(
                (r) => r.copyWith(queryParams: map),
              );
        },
      ),
    );
  }

  Widget _buildHeadersTab(dynamic request) {
    final Map<String, String> headers = Map<String, String>.from(request.headers ?? {});
    final List<KvEntry> entries = headers.entries
        .map((e) => KvEntry(key: e.key, value: e.value))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: KvEditor(
        entries: entries,
        addButtonLabel: AppStrings.addHeader,
        onChanged: (updated) {
          final map = <String, String>{};
          for (final e in updated) {
            if (e.key.isNotEmpty) {
              map[e.key] = e.value;
            }
          }
          ref.read(currentRequestProvider.notifier).updateRequest(
                (r) => r.copyWith(headers: map),
              );
        },
      ),
    );
  }

  Widget _buildBodyTab(request) {
    final body = request.body ?? const RequestBody();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _BodyTypeChip(
                label: AppStrings.jsonBody,
                selected: body.type == BodyType.json,
                onTap: () {
                  ref.read(currentRequestProvider.notifier).updateRequest(
                        (r) => r.copyWith(
                          body: (r.body ?? const RequestBody())
                              .copyWith(type: BodyType.json),
                        ),
                      );
                },
              ),
              const SizedBox(width: 8),
              _BodyTypeChip(
                label: AppStrings.formData,
                selected: body.type == BodyType.formData,
                onTap: () {
                  ref.read(currentRequestProvider.notifier).updateRequest(
                        (r) => r.copyWith(
                          body: (r.body ?? const RequestBody())
                              .copyWith(type: BodyType.formData),
                        ),
                      );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: body.type == BodyType.json
              ? JsonEditorWidget(
                  content: body.jsonContent,
                  onChanged: (v) {
                    ref.read(currentRequestProvider.notifier).updateRequest(
                          (r) => r.copyWith(
                            body: (r.body ?? const RequestBody())
                                .copyWith(jsonContent: v),
                          ),
                        );
                  },
                )
              : _buildFormDataEditor(body),
        ),
      ],
    );
  }

  Widget _buildFormDataEditor(RequestBody body) {
    final entries = body.formFields
        .map((f) => KvEntry(key: f.key, value: f.value, enabled: f.enabled))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: KvEditor(
        entries: entries,
        addButtonLabel: AppStrings.addFormField,
        onChanged: (updated) {
          ref.read(currentRequestProvider.notifier).updateRequest(
                (r) => r.copyWith(
                  body: (r.body ?? const RequestBody()).copyWith(
                    type: BodyType.formData,
                    formFields: updated
                        .map((e) => KeyValuePair(
                              key: e.key,
                              value: e.value,
                              enabled: e.enabled,
                            ))
                        .toList(),
                  ),
                ),
              );
        },
      ),
    );
  }

  Widget _buildAuthTab(dynamic request) {
    final auth = request.auth ?? const AuthConfig();
    return AuthConfigWidget(
      config: auth,
      onChanged: (updated) {
        ref.read(currentRequestProvider.notifier).updateRequest(
              (r) => r.copyWith(auth: updated),
            );
      },
    );
  }
}

class _BodyTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BodyTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
