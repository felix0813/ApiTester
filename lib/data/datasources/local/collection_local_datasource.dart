import '../../models/collection.dart';
import 'local_database.dart';

class CollectionLocalDataSource {
  Future<List<CollectionItem>> getAll() async {
    return LocalDatabase.collections.values.toList();
  }

  Future<CollectionItem?> getById(String id) async {
    return LocalDatabase.collections.get(id);
  }

  Future<List<CollectionItem>> getByParentId(String? parentId) async {
    final items = LocalDatabase.collections.values
        .where((c) => c.parentId == parentId)
        .toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  Future<List<CollectionItem>> getRootItems() async {
    return getByParentId(null);
  }

  Future<void> save(CollectionItem item) async {
    await LocalDatabase.collections.put(item.id, item);
  }

  Future<void> delete(String id) async {
    await LocalDatabase.collections.delete(id);
  }
}
