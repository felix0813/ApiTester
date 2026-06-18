import '../../data/models/environment.dart';

abstract class EnvironmentRepository {
  Future<List<Environment>> getAll();
  Future<Environment?> getActive();
  Future<void> save(Environment env);
  Future<void> setActive(String id);
  Future<void> delete(String id);
  Stream<List<Environment>> watchAll();
}
