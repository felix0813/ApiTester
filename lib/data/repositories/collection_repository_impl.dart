import 'dart:async';
import '../../domain/repositories/collection_repository.dart';
import '../models/collection.dart';
import '../datasources/local/local_database.dart';
import '../datasources/local/collection_local_datasource.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final CollectionLocalDataSource _local;

  CollectionRepositoryImpl({CollectionLocalDataSource? local})
      : _local = local ?? CollectionLocalDataSource();

  @override
  Future<List<CollectionItem>> getRootItems() => _local.getRootItems();

  @override
  Future<List<CollectionItem>> getChildren(String parentId) =>
      _local.getByParentId(parentId);

  @override
  Future<CollectionItem?> getById(String id) => _local.getById(id);

  @override
  Future<void> save(CollectionItem item) async {
    if (item.parentId != null) {
      final parent = await _local.getById(item.parentId!);
      if (parent != null && !parent.childIds.contains(item.id)) {
        final updatedChildIds = List<String>.from(parent.childIds)..add(item.id);
        await _local.save(parent.copyWith(childIds: updatedChildIds));
      }
    }
    await _local.save(item);
  }

  @override
  Future<void> delete(String id) async {
    final item = await _local.getById(id);
    if (item == null) return;

    if (item.parentId != null) {
      final parent = await _local.getById(item.parentId!);
      if (parent != null) {
        final updatedChildIds =
            parent.childIds.where((c) => c != id).toList();
        await _local.save(parent.copyWith(childIds: updatedChildIds));
      }
    }

    if (item.isFolder) {
      for (final childId in item.childIds) {
        await delete(childId);
      }
    }

    await _local.delete(id);
  }

  @override
  Stream<List<CollectionItem>> watchAll() {
    return LocalDatabase.collections
        .watch()
        .map((_) => LocalDatabase.collections.values.toList());
  }
}
