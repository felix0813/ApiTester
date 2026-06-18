import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/collection.dart';
import '../../data/repositories/collection_repository_impl.dart';
import '../../domain/repositories/collection_repository.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepositoryImpl();
});

class CollectionTreeNotifier
    extends StateNotifier<AsyncValue<List<CollectionItem>>> {
  final CollectionRepository _repo;
  StreamSubscription? _sub;

  CollectionTreeNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
    _sub = _repo.watchAll().listen((items) {
      state = AsyncValue.data(items);
    });
  }

  Future<void> _load() async {
    try {
      final items = await _repo.getAll();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(CollectionItem item) async {
    await _repo.save(item);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
  }

  List<CollectionItem> getRootItems() {
    return state.valueOrNull
            ?.where((c) => c.parentId == null)
            .toList() ??
        [];
  }

  List<CollectionItem> getChildren(String parentId) {
    return state.valueOrNull
            ?.where((c) => c.parentId == parentId)
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final collectionTreeProvider = StateNotifierProvider<CollectionTreeNotifier,
    AsyncValue<List<CollectionItem>>>((ref) {
  final repo = ref.watch(collectionRepositoryProvider);
  return CollectionTreeNotifier(repo);
});
