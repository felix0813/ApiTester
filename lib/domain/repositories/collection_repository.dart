import '../../data/models/collection.dart';

abstract class CollectionRepository {
  Future<List<CollectionItem>> getRootItems();
  Future<List<CollectionItem>> getChildren(String parentId);
  Future<CollectionItem?> getById(String id);
  Future<void> save(CollectionItem item);
  Future<void> delete(String id);
  Stream<List<CollectionItem>> watchAll();
}
