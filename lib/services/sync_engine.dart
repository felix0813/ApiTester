import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/datasources/local/local_database.dart';
import '../data/datasources/remote/supabase_request_datasource.dart';
import '../data/datasources/remote/supabase_collection_datasource.dart';
import '../data/datasources/remote/supabase_environment_datasource.dart';
import '../data/models/api_request.dart';
import '../data/models/collection.dart';
import '../data/models/environment.dart';

enum SyncStatus { idle, syncing, error, offline }

class SyncEngine {
  final SupabaseRequestDataSource _requestDS;
  final SupabaseCollectionDataSource _collectionDS;
  final SupabaseEnvironmentDataSource _environmentDS;

  SyncEngine({
    SupabaseRequestDataSource? requestDS,
    SupabaseCollectionDataSource? collectionDS,
    SupabaseEnvironmentDataSource? environmentDS,
  })  : _requestDS = requestDS ?? SupabaseRequestDataSource(),
        _collectionDS = collectionDS ?? SupabaseCollectionDataSource(),
        _environmentDS = environmentDS ?? SupabaseEnvironmentDataSource();

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  DateTime? _lastSyncAt;

  Future<void> fullSync() async {
    _statusController.add(SyncStatus.syncing);

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.every((r) => r == ConnectivityResult.none)) {
        _statusController.add(SyncStatus.offline);
        return;
      }

      await _syncCollections();
      await _syncRequests();
      await _syncEnvironments();

      _lastSyncAt = DateTime.now();
      _statusController.add(SyncStatus.idle);
    } catch (e) {
      _statusController.add(SyncStatus.error);
      rethrow;
    }
  }

  Future<void> incrementalSync() async {
    if (_lastSyncAt == null) {
      return fullSync();
    }

    _statusController.add(SyncStatus.syncing);

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.every((r) => r == ConnectivityResult.none)) {
        _statusController.add(SyncStatus.offline);
        return;
      }

      await _syncCollectionsSince(_lastSyncAt!);
      await _syncRequestsSince(_lastSyncAt!);
      await _syncEnvironmentsSince(_lastSyncAt!);

      _lastSyncAt = DateTime.now();
      _statusController.add(SyncStatus.idle);
    } catch (e) {
      _statusController.add(SyncStatus.error);
      rethrow;
    }
  }

  Future<void> pushLocalChanges() async {
    try {
      final localRequests = LocalDatabase.requests.values
          .where((r) => r.syncAt == null || r.updatedAt.isAfter(r.syncAt!))
          .toList();
      for (final request in localRequests) {
        await _requestDS.upsert(request);
        request.syncAt = DateTime.now();
        await LocalDatabase.requests.put(request.id, request);
      }

      final localCollections = LocalDatabase.collections.values
          .where((c) => c.syncAt == null || c.updatedAt.isAfter(c.syncAt!))
          .toList();
      for (final collection in localCollections) {
        await _collectionDS.upsert(collection);
        collection.syncAt = DateTime.now();
        await LocalDatabase.collections.put(collection.id, collection);
      }

      final localEnvs = LocalDatabase.environments.values
          .where((e) => e.syncAt == null || e.updatedAt.isAfter(e.syncAt!))
          .toList();
      for (final env in localEnvs) {
        await _environmentDS.upsert(env);
        env.syncAt = DateTime.now();
        await LocalDatabase.environments.put(env.id, env);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _syncCollections() async {
    final remoteItems = await _collectionDS.getAll();
    final localBox = LocalDatabase.collections;

    for (final remote in remoteItems) {
      final local = localBox.get(remote.id);
      if (local == null) {
        await localBox.put(remote.id, remote);
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await localBox.put(remote.id, remote.copyWith(
          childIds: local.childIds,
          requestId: local.requestId,
        ));
      }
    }
  }

  Future<void> _syncCollectionsSince(DateTime since) async {
    final changes = await _collectionDS.getChangesSince(since);
    final localBox = LocalDatabase.collections;

    for (final json in changes) {
      final remote = CollectionItem(
        id: json['id'],
        name: json['name'],
        parentId: json['parent_id'],
        sortOrder: json['sort_order'] ?? 0,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );
      final local = localBox.get(remote.id);
      if (local == null) {
        await localBox.put(remote.id, remote);
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await localBox.put(remote.id, remote.copyWith(
          childIds: local.childIds,
          requestId: local.requestId,
        ));
      }
    }
  }

  Future<void> _syncRequests() async {
    final remoteItems = await _requestDS.getAll();
    final localBox = LocalDatabase.requests;

    for (final remote in remoteItems) {
      final local = localBox.get(remote.id);
      if (local == null) {
        await localBox.put(remote.id, remote);
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await localBox.put(remote.id, remote);
      }
    }
  }

  Future<void> _syncRequestsSince(DateTime since) async {
    final changes = await _requestDS.getChangesSince(since);
    final localBox = LocalDatabase.requests;

    for (final json in changes) {
      final remote = ApiRequest.fromMap({
        'id': json['id'],
        'name': json['name'],
        'method': json['method'],
        'url': json['url'],
        'headers': Map<String, String>.from(json['headers'] ?? {}),
        'queryParams': Map<String, String>.from(json['query_params'] ?? {}),
        'body': json['body'],
        'auth': json['auth'],
        'collectionId': json['collection_id'],
        'createdAt': json['created_at'],
        'updatedAt': json['updated_at'],
      });
      final local = localBox.get(remote.id);
      if (local == null) {
        await localBox.put(remote.id, remote);
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await localBox.put(remote.id, remote);
      }
    }
  }

  Future<void> _syncEnvironments() async {
    final remoteItems = await _environmentDS.getAll();
    final localBox = LocalDatabase.environments;

    for (final remote in remoteItems) {
      final local = localBox.get(remote.id);
      if (local == null) {
        await localBox.put(remote.id, remote);
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await localBox.put(remote.id, remote);
      }
    }
  }

  Future<void> _syncEnvironmentsSince(DateTime since) async {
    final changes = await _environmentDS.getChangesSince(since);
    final localBox = LocalDatabase.environments;

    for (final json in changes) {
      final remote = Environment(
        id: json['id'],
        name: json['name'],
        variables: Map<String, String>.from(json['variables'] ?? {}),
        isActive: json['is_active'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );
      final local = localBox.get(remote.id);
      if (local == null) {
        await localBox.put(remote.id, remote);
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await localBox.put(remote.id, remote);
      }
    }
  }

  void dispose() {
    _statusController.close();
  }
}
