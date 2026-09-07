import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/screens/main_screen.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('wallet_smoke_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    await Hive.deleteFromDisk();
    Hive.init(tempDir.path);
    await HiveDatabaseService.instance.init();
  });

  tearDown(() async {
    await HiveDatabaseService.instance.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: MainScreen()),
      ),
    );
    // Pump several frames to let async providers resolve
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('Accounts tab renders wallet list and core actions', (tester) async {
    await pumpApp(tester);

    // Accounts tab is selected by default (index 0)
    expect(find.text('Accounts'), findsWidgets);
    expect(find.text('Total balance'), findsOneWidget);

    // Add wallet FAB visible
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Transfer FAB visible
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);

    // Hamburger menu visible
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });

  testWidgets('Default wallet card renders after init', (tester) async {
    await pumpApp(tester);

    // Default wallet should render (seeded by db.init)
    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('Drawer opens via hamburger menu', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.menu));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Backup'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('About Finsor'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('About Finsor'), findsOneWidget);
  });
}
