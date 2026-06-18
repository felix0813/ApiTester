import '../../models/api_request.dart';
import 'local_database.dart';

class RequestLocalDataSource {
  Future<List<ApiRequest>> getAll() async {
    return LocalDatabase.requests.values.toList();
  }

  Future<ApiRequest?> getById(String id) async {
    return LocalDatabase.requests.get(id);
  }

  Future<void> save(ApiRequest request) async {
    await LocalDatabase.requests.put(request.id, request);
  }

  Future<void> delete(String id) async {
    await LocalDatabase.requests.delete(id);
  }

  Future<void> deleteAll(Iterable<String> ids) async {
    await LocalDatabase.requests.deleteAll(ids);
  }
}
