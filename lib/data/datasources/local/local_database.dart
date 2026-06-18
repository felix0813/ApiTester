import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/api_request.dart';
import '../../../data/models/collection.dart';
import '../../../data/models/environment.dart';
import '../../../data/models/history_entry.dart';
import '../../../data/models/request_body.dart';
import '../../../data/models/auth_config.dart';

class LocalDatabase {
  static const String requestsBox = 'requests';
  static const String collectionsBox = 'collections';
  static const String environmentsBox = 'environments';
  static const String historyBox = 'history';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register sub-model adapters first (used as fields by main models)
    Hive.registerAdapter(KeyValuePairAdapter());
    Hive.registerAdapter(AuthConfigAdapter());
    Hive.registerAdapter(RequestBodyAdapter());

    // Register main model adapters
    Hive.registerAdapter(ApiRequestAdapter());
    Hive.registerAdapter(CollectionItemAdapter());
    Hive.registerAdapter(EnvironmentAdapter());
    Hive.registerAdapter(HistoryEntryAdapter());

    // Open boxes
    await Hive.openBox<ApiRequest>(requestsBox);
    await Hive.openBox<CollectionItem>(collectionsBox);
    await Hive.openBox<Environment>(environmentsBox);
    await Hive.openBox<HistoryEntry>(historyBox);
  }

  static Box<ApiRequest> get requests => Hive.box<ApiRequest>(requestsBox);
  static Box<CollectionItem> get collections =>
      Hive.box<CollectionItem>(collectionsBox);
  static Box<Environment> get environments =>
      Hive.box<Environment>(environmentsBox);
  static Box<HistoryEntry> get history =>
      Hive.box<HistoryEntry>(historyBox);
}
