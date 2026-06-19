import 'dart:convert';
import '../../data/models/api_request.dart';
import '../../data/models/collection.dart';
import '../../data/models/request_body.dart';
import '../../data/models/auth_config.dart';

/// Import result containing collections and requests
class ImportResult {
  final List<CollectionItem> collections;
  final List<ApiRequest> requests;

  const ImportResult({
    required this.collections,
    required this.requests,
  });
}

class PostmanImporter {
  ImportResult importFromJson(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    if (json['info'] == null || json['item'] == null) {
      throw FormatException('Invalid Postman Collection format');
    }

    final collectionName = json['info']['name'] ?? 'Imported Collection';
    final collections = <CollectionItem>[];
    final requests = <ApiRequest>[];

    final rootCollection = CollectionItem(
      name: collectionName,
      type: CollectionType.folder,
    );
    collections.add(rootCollection);

    _parseItems(
      json['item'] as List,
      rootCollection.id,
      collections,
      requests,
    );

    return ImportResult(
      collections: collections,
      requests: requests,
    );
  }

  void _parseItems(
    List items,
    String parentId,
    List<CollectionItem> collections,
    List<ApiRequest> requests,
  ) {
    int sortOrder = 0;

    for (final item in items) {
      if (item.containsKey('item')) {
        final folder = CollectionItem(
          name: item['name'] ?? 'Unnamed Folder',
          parentId: parentId,
          type: CollectionType.folder,
          sortOrder: sortOrder++,
        );
        collections.add(folder);

        _parseItems(
          item['item'] as List,
          folder.id,
          collections,
          requests,
        );
      } else if (item.containsKey('request')) {
        final request = _parseRequest(item);
        requests.add(request);

        final collectionItem = CollectionItem(
          name: request.name,
          parentId: parentId,
          type: CollectionType.request,
          requestId: request.id,
          sortOrder: sortOrder++,
        );
        collections.add(collectionItem);
      }
    }
  }

  ApiRequest _parseRequest(Map<String, dynamic> item) {
    final requestData = item['request'];
    final name = item['name'] ?? 'Imported Request';

    String url = '';
    if (requestData['url'] is String) {
      url = requestData['url'];
    } else if (requestData['url'] is Map) {
      final urlObj = requestData['url'];
      final protocol = urlObj['protocol'] ?? 'https';
      final host = (urlObj['host'] as List?)?.join('.') ?? '';
      final path = (urlObj['path'] as List?)?.join('/') ?? '';
      url = '$protocol://$host/$path';

      if (urlObj['query'] != null) {
        final params = (urlObj['query'] as List)
            .map((q) => '${q['key']}=${q['value'] ?? ''}')
            .join('&');
        if (params.isNotEmpty) url += '?$params';
      }
    }

    final method = requestData['method'] ?? 'GET';

    final headers = <String, String>{};
    if (requestData['header'] != null) {
      for (final h in requestData['header'] as List) {
        if (h['disabled'] != true) {
          headers[h['key']] = h['value'] ?? '';
        }
      }
    }

    RequestBody? body;
    if (requestData['body'] != null) {
      final bodyData = requestData['body'];
      if (bodyData['mode'] == 'raw') {
        body = RequestBody(
          type: BodyType.json,
          jsonContent: bodyData['raw'] ?? '{}',
        );
      } else if (bodyData['mode'] == 'formdata') {
        final formFields = (bodyData['formdata'] as List?)
            ?.map((f) => KeyValuePair(
                  key: f['key'] ?? '',
                  value: f['value'] ?? '',
                  enabled: f['disabled'] != true,
                ))
            .toList();
        body = RequestBody(
          type: BodyType.formData,
          formFields: formFields ?? [],
        );
      }
    }

    AuthConfig? auth;
    if (requestData['auth'] != null) {
      final authData = requestData['auth'];
      if (authData['type'] == 'bearer') {
        final token = _findAuthValue(authData['bearer'], 'token');
        auth = AuthConfig(type: AuthType.bearer, token: token);
      } else if (authData['type'] == 'basic') {
        final username = _findAuthValue(authData['basic'], 'username');
        final password = _findAuthValue(authData['basic'], 'password');
        auth = AuthConfig(type: AuthType.basic, username: username, password: password);
      }
    }

    return ApiRequest(
      name: name,
      method: method,
      url: url,
      headers: headers,
      body: body,
      auth: auth,
    );
  }

  String _findAuthValue(List? authList, String key) {
    if (authList == null) return '';
    for (final item in authList) {
      if (item['key'] == key) return item['value'] ?? '';
    }
    return '';
  }
}
