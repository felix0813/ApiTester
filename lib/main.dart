import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/supabase_config.dart';
import 'data/datasources/local/local_database.dart';
import 'data/datasources/local/sync_queue_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );

  await LocalDatabase.init();
  await SyncQueueDataSource.init();

  runApp(const ProviderScope(child: ApiTesterApp()));
}
