import 'dart:async';
import '../../domain/repositories/request_repository.dart';
import '../models/api_request.dart';
import '../datasources/local/local_database.dart';
import '../datasources/local/request_local_datasource.dart';

class RequestRepositoryImpl implements RequestRepository {
  final RequestLocalDataSource _local;

  RequestRepositoryImpl({RequestLocalDataSource? local})
      : _local = local ?? RequestLocalDataSource();

  @override
  Future<List<ApiRequest>> getAll() => _local.getAll();

  @override
  Future<ApiRequest?> getById(String id) => _local.getById(id);

  @override
  Future<void> save(ApiRequest request) => _local.save(request);

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Stream<List<ApiRequest>> watchAll() {
    return LocalDatabase.requests.watch().map(
        (_) => LocalDatabase.requests.values.toList());
  }
}
