import 'dart:convert';
import 'package:yaml/yaml.dart';
import '../../data/models/api_request.dart';
import '../../data/models/collection.dart';
import '../../data/models/request_body.dart';
import 'postman_importer.dart';

class OpenApiImporter {
  ImportResult import(String content) {
    Map<String, dynamic> spec;

    try {
      spec = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      try {
        final yaml = loadYaml(content);
        spec = Map<String, dynamic>.from(yaml as Map);
      } catch (e) {
        throw FormatException('Invalid OpenAPI spec: not valid JSON or YAML');
      }
    }

    if (spec['openapi'] == null && spec['swagger'] == null) {
      throw FormatException('Not a valid OpenAPI/Swagger spec');
    }

    final info = spec['info'] ?? {};
    final title = info['title'] ?? 'API';
    final servers = spec['servers'] as List?;
    final basePath = servers?.isNotEmpty == true
        ? servers![0]['url'] ?? ''
        : '';

    final collections = <CollectionItem>[];
    final requests = <ApiRequest>[];

    final rootCollection = CollectionItem(
      name: title,
      type: CollectionType.folder,
    );
    collections.add(rootCollection);

    final paths = spec['paths'] as Map<String, dynamic>? ?? {};
    int sortOrder = 0;

    for (final pathEntry in paths.entries) {
      final path = pathEntry.key;
      final methods = pathEntry.value as Map<String, dynamic>;

      for (final methodEntry in methods.entries) {
        final method = methodEntry.key.toUpperCase();
        if (!['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].contains(method)) continue;

        final operation = methodEntry.value as Map<String, dynamic>;
        final summary = operation['summary'] ?? operation['operationId'] ?? '$method $path';

        final url = '$basePath$path';

        final headers = <String, String>{};
        final queryParams = <String, String>{};
        final parameters = operation['parameters'] as List? ?? [];

        for (final param in parameters) {
          if (param['in'] == 'header') {
            headers[param['name']] = param['schema']?['example']?.toString() ?? '';
          } else if (param['in'] == 'query') {
            queryParams[param['name']] = param['schema']?['example']?.toString() ?? '';
          }
        }

        RequestBody? body;
        final requestBody = operation['requestBody'] as Map<String, dynamic>?;
        if (requestBody != null) {
          final content = requestBody['content'] as Map<String, dynamic>?;
          if (content != null && content.containsKey('application/json')) {
            final schema = content['application/json']?['schema'];
            body = RequestBody(
              type: BodyType.json,
              jsonContent: _generateExampleJson(schema),
            );
          }
        }

        final request = ApiRequest(
          name: summary,
          method: method,
          url: url,
          headers: headers,
          queryParams: queryParams,
          body: body,
        );
        requests.add(request);

        final collectionItem = CollectionItem(
          name: summary,
          parentId: rootCollection.id,
          type: CollectionType.request,
          requestId: request.id,
          sortOrder: sortOrder++,
        );
        collections.add(collectionItem);
      }
    }

    return ImportResult(collections: collections, requests: requests);
  }

  String _generateExampleJson(Map<String, dynamic>? schema) {
    if (schema == null) return '{}';

    if (schema.containsKey('example')) {
      return jsonEncode(schema['example']);
    }

    if (schema['type'] == 'object') {
      final properties = schema['properties'] as Map<String, dynamic>? ?? {};
      final result = <String, dynamic>{};
      for (final entry in properties.entries) {
        result[entry.key] = _getExampleValue(entry.value);
      }
      return const JsonEncoder.withIndent('  ').convert(result);
    }

    return '{}';
  }

  dynamic _getExampleValue(Map<String, dynamic> schema) {
    if (schema.containsKey('example')) return schema['example'];
    switch (schema['type']) {
      case 'string':
        return schema['example'] ?? '';
      case 'integer':
        return schema['example'] ?? 0;
      case 'number':
        return schema['example'] ?? 0.0;
      case 'boolean':
        return schema['example'] ?? false;
      case 'array':
        return [];
      case 'object':
        return {};
      default:
        return null;
    }
  }
}
