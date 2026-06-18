import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:api_tester/app.dart';
import 'package:api_tester/data/datasources/local/local_database.dart';

void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('hive_test_');
    await LocalDatabase.init(path: dir.path);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App renders with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const ApiTesterApp());
    await tester.pumpAndSettle();

    // Verify bottom navigation bar exists with 4 items
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify all 4 navigation destinations exist
    final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(navBar.items.length, 4);
    expect(navBar.items[0].label, 'Request');
    expect(navBar.items[1].label, 'Collections');
    expect(navBar.items[2].label, 'Environments');
    expect(navBar.items[3].label, 'Me');
  });
}
