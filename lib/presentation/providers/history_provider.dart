import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import 'request_provider.dart';

final historyListProvider = StateNotifierProvider<HistoryListNotifier,
    AsyncValue<List<HistoryEntry>>>((ref) {
  final repo = ref.watch(historyRepositoryProvider);
  return HistoryListNotifier(repo);
});

class HistoryListNotifier
    extends StateNotifier<AsyncValue<List<HistoryEntry>>> {
  final HistoryRepository _repo;
  StreamSubscription? _sub;

  HistoryListNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
    _sub = _repo.watchAll().listen((entries) {
      state = AsyncValue.data(entries);
    });
  }

  Future<void> _load() async {
    try {
      final entries = await _repo.getAll();
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
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
