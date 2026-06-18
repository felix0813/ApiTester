import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/request_provider.dart';
import '../../../data/models/request_body.dart';
import '../../../data/models/auth_config.dart';
import '../../widgets/kv_editor.dart';
import '../../widgets/json_editor_widget.dart';
import '../../widgets/response_viewer.dart';
import '../../widgets/auth_config_widget.dart';

class DesktopRequestScreen extends ConsumerStatefulWidget {
  const DesktopRequestScreen({super.key});

  @override
  ConsumerState<DesktopRequestScreen> createState() =>
      _DesktopRequestScreenState();
}

class _DesktopRequestScreenState extends ConsumerState<DesktopRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responseState = ref.watch(responseProvider);

    return Row(
      children: [
        // Left: Request config tabs
        Expanded(
          flex: 1,
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Params'),
                  Tab(text: 'Headers'),
                  Tab(text: 'Body'),
                  Tab(text: 'Auth'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildParamsTab(),
                    _buildHeadersTab(),
                    _buildBodyTab(),
                    _buildAuthTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Right: Response viewer
        Expanded(
          flex: 1,
          child: ResponseViewer(
            response: responseState.response,
            isLoading: responseState.isLoading,
            error: responseState.error,
          ),
        ),
      ],
    );
  }

  Widget _buildParamsTab() {
    final request = ref.read(currentRequestProvider);
    final params = Map<String, String>.from(request.queryParams);
    final entries = params.entries
        .map((e) => KvEntry(key: e.key, value: e.value))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: KvEditor(
        entries: entries,
        addButtonLabel: 'Add Param',
        onChanged: (updated) {
          final map = <String, String>{};
          for (final e in updated) {
            if (e.key.isNotEmpty) map[e.key] = e.value;
          }
          ref.read(currentRequestProvider.notifier).updateRequest(
                (r) => r.copyWith(queryParams: map),
              );
        },
      ),
    );
  }

  Widget _buildHeadersTab() {
    final request = ref.read(currentRequestProvider);
    final headers = Map<String, String>.from(request.headers);
    final entries = headers.entries
        .map((e) => KvEntry(key: e.key, value: e.value))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: KvEditor(
        entries: entries,
        addButtonLabel: 'Add Header',
        onChanged: (updated) {
          final map = <String, String>{};
          for (final e in updated) {
            if (e.key.isNotEmpty) map[e.key] = e.value;
          }
          ref.read(currentRequestProvider.notifier).updateRequest(
                (r) => r.copyWith(headers: map),
              );
        },
      ),
    );
  }

  Widget _buildBodyTab() {
    final request = ref.read(currentRequestProvider);
    final body = request.body ?? const RequestBody();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _BodyTypeChip(
                label: 'JSON',
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
                label: 'Form Data',
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
        addButtonLabel: 'Add Form Field',
        onChanged: (updated) {
          ref.read(currentRequestProvider.notifier).updateRequest(
                (r) => r.copyWith(
                  body: (r.body ?? const RequestBody()).copyWith(
                    type: BodyType.formData,
                    formFields: updated
                        .map((e) => KeyValuePair(
                              key: e.key, value: e.value, enabled: e.enabled))
                        .toList(),
                  ),
                ),
              );
        },
      ),
    );
  }

  Widget _buildAuthTab() {
    final request = ref.read(currentRequestProvider);
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
