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
    tempDir = await Directory.systemTemp.createTemp('drawer_nav_');
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
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.menu).first);
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('Drawer contains all required sections', (tester) async {
    await pumpApp(tester);
    await openDrawer(tester);

    expect(find.text('Settings'), findsOneWidget);
    // New: Features section
    expect(find.text('Features'), findsOneWidget);
    expect(find.text('Recurring Transactions'), findsOneWidget);
    expect(find.text('Goals & Debts'), findsOneWidget);
    expect(find.text('Data Management'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Backup'), findsOneWidget);
    expect(find.text('Import / Restore'), findsOneWidget);

    // Scroll down within the drawer to reveal bottom items
    await tester.scrollUntilVisible(
      find.text('Privacy Policy'),
      200.0,
      scrollable: find.byType(Scrollable).last,
    );
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('About & Legal'), findsOneWidget);
    expect(find.text('About Finsor'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget);
  });

  testWidgets('Bottom nav has 6 tabs including AI', (tester) async {
    await pumpApp(tester);

    expect(find.text('Accounts'), findsWidgets);
    expect(find.text('Categories'), findsWidgets);
    expect(find.text('Transactions'), findsWidgets);
    expect(find.text('Budget'), findsWidgets);
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('AI'), findsWidgets);

    expect(find.byType(NavigationDestination), findsNWidgets(6));
  });

  testWidgets('Switching tabs works', (tester) async {
    await pumpApp(tester);

    // Navigate to Transactions tab
    await tester.tap(find.text('Transactions').last);
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Navigate back to Accounts
    await tester.tap(find.text('Accounts').last);
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Total balance'), findsOneWidget);
  });
}
