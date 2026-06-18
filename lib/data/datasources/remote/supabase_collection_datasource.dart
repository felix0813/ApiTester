import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/collection.dart';

class SupabaseCollectionDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<CollectionItem>> getAll() async {
    final data = await _client
        .from('collections')
        .select()
        .eq('user_id', _userId)
        .order('sort_order');

    return data.map((json) => CollectionItem(
      id: json['id'],
      name: json['name'],
      parentId: json['parent_id'],
      type: CollectionType.folder,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    )).toList();
  }

  Future<void> upsert(CollectionItem item) async {
    await _client.from('collections').upsert({
      'id': item.id,
      'user_id': _userId,
      'name': item.name,
      'parent_id': item.parentId,
      'sort_order': item.sortOrder,
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': item.updatedAt.toIso8601String(),
    });
  }

  Future<void> softDelete(String id) async {
    await _client.from('collections').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getChangesSince(DateTime since) async {
    return await _client
        .from('collections')
        .select()
        .eq('user_id', _userId)
        .gt('updated_at', since.toIso8601String())
        .order('updated_at');
  }
}
