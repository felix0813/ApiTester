import '../../models/history_entry.dart';
import 'local_database.dart';

class HistoryLocalDataSource {
  Future<List<HistoryEntry>> getAll() async {
    final entries = LocalDatabase.history.values.toList();
    entries.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return entries;
  }

  Future<void> save(HistoryEntry entry) async {
    await LocalDatabase.history.put(entry.id, entry);
  }

  Future<void> delete(String id) async {
    await LocalDatabase.history.delete(id);
  }

  Future<void> clearAll() async {
    await LocalDatabase.history.clear();
  }
}
