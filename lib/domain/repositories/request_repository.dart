import '../../data/models/api_request.dart';

abstract class RequestRepository {
  Future<List<ApiRequest>> getAll();
  Future<ApiRequest?> getById(String id);
  Future<void> save(ApiRequest request);
  Future<void> delete(String id);
  Stream<List<ApiRequest>> watchAll();
}
