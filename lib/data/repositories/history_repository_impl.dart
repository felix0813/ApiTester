import 'dart:async';
import '../../domain/repositories/history_repository.dart';
import '../models/history_entry.dart';
import '../datasources/local/local_database.dart';
import '../datasources/local/history_local_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryLocalDataSource _local;

  HistoryRepositoryImpl({HistoryLocalDataSource? local})
      : _local = local ?? HistoryLocalDataSource();

  @override
  Future<List<HistoryEntry>> getAll() => _local.getAll();

  @override
  Future<void> save(HistoryEntry entry) => _local.save(entry);

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Future<void> clearAll() => _local.clearAll();

  @override
  Stream<List<HistoryEntry>> watchAll() {
    return LocalDatabase.history
        .watch()
        .map((_) => LocalDatabase.history.values.toList());
  }
}
