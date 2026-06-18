import '../../data/models/history_entry.dart';

abstract class HistoryRepository {
  Future<List<HistoryEntry>> getAll();
  Future<void> save(HistoryEntry entry);
  Future<void> delete(String id);
  Future<void> clearAll();
  Stream<List<HistoryEntry>> watchAll();
}
