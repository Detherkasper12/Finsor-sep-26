import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/category.dart';

void main() {
  late HiveDatabaseService db;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_cat_reassign_');
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

  group('Category delete with reassignment', () {
    test('Reassign moves transactions to target category', () async {
      // Create custom categories
      final catA = Category(
        id: 'cat_delete_a',
        name: 'Category A',
        type: TransactionType.expense,
        iconName: 'restaurant',
        color: '#F44336',
        sortOrder: 100,
        createdAt: DateTime.now(),
      );
      final catB = Category(
        id: 'cat_delete_b',
        name: 'Category B',
        type: TransactionType.expense,
        iconName: 'shopping_bag',
        color: '#2196F3',
        sortOrder: 101,
        createdAt: DateTime.now(),
      );
      await db.addCategory(catA);
      await db.addCategory(catB);

      // Add transactions to catA
      for (int i = 0; i < 3; i++) {
        await db.addTransaction(Transaction(
          id: 'tx_cat_r_$i',
          amount: 10.0 * (i + 1),
          type: TransactionType.expense,
          categoryId: catA.id,
          walletId: 'wallet_default',
          createdAt: DateTime.now(),
        ));
      }

      final beforeCount = await db.getTransactionCountByCategory(catA.id);
      expect(beforeCount, equals(3));

      // Reassign catA transactions to catB
      await db.reassignTransactionsToCategory(catA.id, catB.id);

      final afterCountA = await db.getTransactionCountByCategory(catA.id);
      final afterCountB = await db.getTransactionCountByCategory(catB.id);
      expect(afterCountA, equals(0));
      expect(afterCountB, equals(3));

      // Delete catA (soft delete — marks isActive=false)
      await db.deleteCategory(catA.id);
      final deleted = await db.getCategory(catA.id);
      expect(deleted!.isActive, isFalse);
    });

    test('Parent category with children — children handled before delete', () async {
      final parent = Category(
        id: 'cat_parent_test',
        name: 'Parent',
        type: TransactionType.expense,
        iconName: 'home',
        color: '#4CAF50',
        sortOrder: 200,
        createdAt: DateTime.now(),
      );
      final child1 = Category(
        id: 'cat_child_1',
        name: 'Child 1',
        type: TransactionType.expense,
        parentId: parent.id,
        iconName: 'restaurant',
        color: '#F44336',
        sortOrder: 201,
        createdAt: DateTime.now(),
      );
      final child2 = Category(
        id: 'cat_child_2',
        name: 'Child 2',
        type: TransactionType.expense,
        parentId: parent.id,
        iconName: 'shopping_bag',
        color: '#2196F3',
        sortOrder: 202,
        createdAt: DateTime.now(),
      );
      await db.addCategory(parent);
      await db.addCategory(child1);
      await db.addCategory(child2);

      // Verify children exist
      final allCats = await db.getCategories();
      final children = allCats.where((c) => c.parentId == parent.id).toList();
      expect(children.length, equals(2));

      // Move children to another parent
      final otherParent = Category(
        id: 'cat_other_parent',
        name: 'Other Parent',
        type: TransactionType.expense,
        iconName: 'build',
        color: '#9C27B0',
        sortOrder: 300,
        createdAt: DateTime.now(),
      );
      await db.addCategory(otherParent);

      for (final child in children) {
        await db.updateCategory(child.copyWith(
          parentId: otherParent.id,
          updatedAt: DateTime.now(),
        ));
      }

      // Verify children moved
      final updatedCats = await db.getCategories();
      final movedChildren =
          updatedCats.where((c) => c.parentId == otherParent.id).toList();
      expect(movedChildren.length, equals(2));

      // Now safe to delete parent (soft delete)
      await db.deleteCategory(parent.id);
      final deleted = await db.getCategory(parent.id);
      expect(deleted!.isActive, isFalse);
    });

    test('Category delete with 0 transactions succeeds directly', () async {
      final cat = Category(
        id: 'cat_empty_del',
        name: 'Empty Cat',
        type: TransactionType.expense,
        iconName: 'category',
        color: '#795548',
        sortOrder: 400,
        createdAt: DateTime.now(),
      );
      await db.addCategory(cat);

      final count = await db.getTransactionCountByCategory(cat.id);
      expect(count, equals(0));

      await db.deleteCategory(cat.id);
      final deleted = await db.getCategory(cat.id);
      expect(deleted!.isActive, isFalse);
    });
  });
}
