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
  static const String settingsBox = 'settings';

  static Future<void> init({String? path}) async {
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }

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
    await Hive.openBox(settingsBox);
    await Hive.openBox('sync_queue');

    // Migrate: assign sortOrder to existing items by createdAt
    final collections = Hive.box<CollectionItem>(collectionsBox);
    if (collections.isNotEmpty) {
      final all = collections.values.toList();
      final hasUnsorted = all.any((c) => c.sortOrder == 0);
      if (hasUnsorted && all.length > 1) {
        final groups = <String?, List<CollectionItem>>{};
        for (final item in all) {
          groups.putIfAbsent(item.parentId, () => []).add(item);
        }
        for (final entry in groups.entries) {
          final sorted = entry.value
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          for (int i = 0; i < sorted.length; i++) {
            sorted[i].sortOrder = i;
            await collections.put(sorted[i].id, sorted[i]);
          }
        }
      }
    }
  }

  static Box<ApiRequest> get requests => Hive.box<ApiRequest>(requestsBox);
  static Box<CollectionItem> get collections =>
      Hive.box<CollectionItem>(collectionsBox);
  static Box<Environment> get environments =>
      Hive.box<Environment>(environmentsBox);
  static Box<HistoryEntry> get history =>
      Hive.box<HistoryEntry>(historyBox);
  static Box get settings => Hive.box(settingsBox);
}
