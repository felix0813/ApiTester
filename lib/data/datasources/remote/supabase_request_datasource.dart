import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/api_request.dart';

class SupabaseRequestDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<ApiRequest>> getAll() async {
    final data = await _client
        .from('requests')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return data.map((json) => ApiRequest.fromMap({
      'id': json['id'],
      'name': json['name'],
      'method': json['method'],
      'url': json['url'],
      'headers': Map<String, String>.from(json['headers'] ?? {}),
      'queryParams': Map<String, String>.from(json['query_params'] ?? {}),
      'body': json['body'],
      'auth': json['auth'],
      'collectionId': json['collection_id'],
      'createdAt': json['created_at'],
      'updatedAt': json['updated_at'],
    })).toList();
  }

  Future<void> upsert(ApiRequest request) async {
    await _client.from('requests').upsert({
      'id': request.id,
      'user_id': _userId,
      'collection_id': request.collectionId,
      'name': request.name,
      'method': request.method,
      'url': request.url,
      'headers': request.headers,
      'query_params': request.queryParams,
      'body': request.body?.toMap(),
      'auth': request.auth?.toMap(),
      'created_at': request.createdAt.toIso8601String(),
      'updated_at': request.updatedAt.toIso8601String(),
    });
  }

  Future<void> softDelete(String id) async {
    await _client.from('requests').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getChangesSince(DateTime since) async {
    return await _client
        .from('requests')
        .select()
        .eq('user_id', _userId)
        .gt('updated_at', since.toIso8601String())
        .order('updated_at');
  }
}
