import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/environment.dart';

class SupabaseEnvironmentDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Environment>> getAll() async {
    final data = await _client
        .from('environments')
        .select()
        .eq('user_id', _userId)
        .order('created_at');

    return data.map((json) => Environment(
      id: json['id'],
      name: json['name'],
      variables: Map<String, String>.from(json['variables'] ?? {}),
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    )).toList();
  }

  Future<void> upsert(Environment env) async {
    await _client.from('environments').upsert({
      'id': env.id,
      'user_id': _userId,
      'name': env.name,
      'variables': env.variables,
      'is_active': env.isActive,
      'created_at': env.createdAt.toIso8601String(),
      'updated_at': env.updatedAt.toIso8601String(),
    });
  }

  Future<void> softDelete(String id) async {
    await _client.from('environments').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getChangesSince(DateTime since) async {
    return await _client
        .from('environments')
        .select()
        .eq('user_id', _userId)
        .gt('updated_at', since.toIso8601String())
        .order('updated_at');
  }
}
