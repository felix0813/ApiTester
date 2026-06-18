import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/environment.dart';
import '../../data/repositories/environment_repository_impl.dart';
import '../../domain/repositories/environment_repository.dart';

final environmentRepositoryProvider = Provider<EnvironmentRepository>((ref) {
  return EnvironmentRepositoryImpl();
});

class EnvironmentListNotifier
    extends StateNotifier<AsyncValue<List<Environment>>> {
  final EnvironmentRepository _repo;
  StreamSubscription? _sub;

  EnvironmentListNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
    _sub = _repo.watchAll().listen((envs) {
      state = AsyncValue.data(envs);
    });
  }

  Future<void> _load() async {
    try {
      final envs = await _repo.getAll();
      state = AsyncValue.data(envs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(Environment env) async {
    await _repo.save(env);
  }

  Future<void> setActive(String id) async {
    await _repo.setActive(id);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final environmentListProvider = StateNotifierProvider<EnvironmentListNotifier,
    AsyncValue<List<Environment>>>((ref) {
  final repo = ref.watch(environmentRepositoryProvider);
  return EnvironmentListNotifier(repo);
});

final activeEnvironmentProvider = Provider<Environment?>((ref) {
  final envsAsync = ref.watch(environmentListProvider);
  final envs = envsAsync.valueOrNull;
  if (envs == null) return null;
  for (final env in envs) {
    if (env.isActive) return env;
  }
  return null;
});
