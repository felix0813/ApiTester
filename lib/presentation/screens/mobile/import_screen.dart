import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/utils/postman_importer.dart';
import '../../../core/utils/openapi_importer.dart';
import '../../providers/collection_provider.dart';
import '../../providers/request_provider.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  Future<void> _importPostmanCollection() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isLoading = true;
        _error = null;
        _successMessage = null;
      });

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();

      final importer = PostmanImporter();
      final importResult = importer.importFromJson(jsonString);

      for (final request in importResult.requests) {
        await ref.read(requestRepositoryProvider).save(request);
      }
      for (final collection in importResult.collections) {
        await ref.read(collectionTreeProvider.notifier).save(collection);
      }

      setState(() {
        _isLoading = false;
        _successMessage = 'Imported ${importResult.collections.length} collections, ${importResult.requests.length} requests';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Import failed: $e';
      });
    }
  }

  Future<void> _importOpenApiSpec() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'yaml', 'yml'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isLoading = true;
        _error = null;
        _successMessage = null;
      });

      final file = File(result.files.first.path!);
      final content = await file.readAsString();

      final importer = OpenApiImporter();
      final importResult = importer.import(content);

      for (final request in importResult.requests) {
        await ref.read(requestRepositoryProvider).save(request);
      }
      for (final collection in importResult.collections) {
        await ref.read(collectionTreeProvider.notifier).save(collection);
      }

      setState(() {
        _isLoading = false;
        _successMessage = 'Imported ${importResult.collections.length} collections, ${importResult.requests.length} requests';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Import failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/collections'),
        ),
        title: const Text('Import'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
            ],
            if (_error != null) ...[
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_successMessage != null) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_successMessage!, style: const TextStyle(color: Colors.green)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              child: ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text('Import Postman Collection'),
                subtitle: const Text('Import from Postman Collection v2.1 JSON file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _isLoading ? null : _importPostmanCollection,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.code_outlined),
                title: const Text('Import OpenAPI Spec'),
                subtitle: const Text('Import from OpenAPI 3.0 JSON or YAML file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _isLoading ? null : _importOpenApiSpec,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
