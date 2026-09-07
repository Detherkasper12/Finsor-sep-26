import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/models/category.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/services/hive_database_service.dart';

void main() {
  late HiveDatabaseService db;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('s17_cat_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    await Hive.deleteFromDisk();
    Hive.init(tempDir.path);
    db = HiveDatabaseService.instance;
    await db.init();
  });

  tearDown(() async {
    await db.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Category with subcategories', () {
    test('creating parent then children with parentId persists and children have parentId', () async {
      final parentId = 'parent_car';
      final parent = Category(
        id: parentId,
        name: 'Car',
        type: TransactionType.expense,
        iconName: 'directions_car',
        color: '#607D8B',
        sortOrder: 999,
        createdAt: DateTime.now(),
      );
      await db.addCategory(parent);

      final childNames = ['Fuel', 'Tires', 'Service'];
      for (final name in childNames) {
        final child = Category(
          id: '${parentId}_$name',
          name: name,
          type: TransactionType.expense,
          parentId: parent.id,
          iconName: parent.iconName,
          color: parent.color,
          sortOrder: 999,
          createdAt: DateTime.now(),
        );
        await db.addCategory(child);
      }

      final all = await db.getCategories();
      expect(all.length, greaterThanOrEqualTo(4));
      final children = all.where((c) => c.parentId == parentId).toList();
      expect(children.length, 3);
      expect(children.map((c) => c.name).toSet(), containsAll(childNames));
      for (final c in children) {
        expect(c.parentId, parentId);
        expect(c.type, TransactionType.expense);
      }
      final ourParent = all.where((c) => c.id == parentId).toList();
      expect(ourParent.length, 1);
      expect(ourParent.first.parentId, isNull);
    });
  });
}
