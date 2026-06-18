import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/sync_engine.dart';
import 'auth_provider.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine();
});

final syncStatusProvider = StateProvider<SyncStatus>((ref) {
  return SyncStatus.idle;
});

final autoSyncProvider = Provider<void>((ref) {
  final auth = ref.watch(authStateProvider);
  final syncEngine = ref.watch(syncEngineProvider);

  auth.whenData((authState) {
    if (authState.event == AuthChangeEvent.signedIn) {
      syncEngine.fullSync().catchError((_) {});
    }
  });

  Connectivity().onConnectivityChanged.listen((results) {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (hasConnection) {
      syncEngine.incrementalSync().catchError((_) {});
    }
  });
});
