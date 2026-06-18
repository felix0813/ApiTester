import '../../models/environment.dart';
import 'local_database.dart';

class EnvironmentLocalDataSource {
  Future<List<Environment>> getAll() async {
    return LocalDatabase.environments.values.toList();
  }

  Future<Environment?> getById(String id) async {
    return LocalDatabase.environments.get(id);
  }

  Future<Environment?> getActive() async {
    final envs = LocalDatabase.environments.values;
    try {
      return envs.firstWhere((e) => e.isActive);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Environment env) async {
    await LocalDatabase.environments.put(env.id, env);
  }

  Future<void> setActive(String id) async {
    // Deactivate all
    final all = await getAll();
    for (final env in all) {
      if (env.isActive && env.id != id) {
        await save(env.copyWith(isActive: false));
      }
    }
    // Activate target
    final target = await getById(id);
    if (target != null) {
      await save(target.copyWith(isActive: true));
    }
  }

  Future<void> delete(String id) async {
    await LocalDatabase.environments.delete(id);
  }
}
