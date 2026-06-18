import 'dart:async';
import '../../domain/repositories/environment_repository.dart';
import '../models/environment.dart';
import '../datasources/local/local_database.dart';
import '../datasources/local/environment_local_datasource.dart';

class EnvironmentRepositoryImpl implements EnvironmentRepository {
  final EnvironmentLocalDataSource _local;

  EnvironmentRepositoryImpl({EnvironmentLocalDataSource? local})
      : _local = local ?? EnvironmentLocalDataSource();

  @override
  Future<List<Environment>> getAll() => _local.getAll();

  @override
  Future<Environment?> getActive() => _local.getActive();

  @override
  Future<void> save(Environment env) => _local.save(env);

  @override
  Future<void> setActive(String id) => _local.setActive(id);

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Stream<List<Environment>> watchAll() {
    return LocalDatabase.environments
        .watch()
        .map((_) => LocalDatabase.environments.values.toList());
  }
}
