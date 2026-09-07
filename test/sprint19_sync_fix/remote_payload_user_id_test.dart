import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/models/transaction.dart';

/// Mimics SyncService remote payload for transactions: localToRemote + user_id.
Map<String, dynamic> buildRemotePayloadForTransaction(
  Map<String, dynamic> local,
  String userId,
) {
  final remote = {
    'id': local['id'],
    'amount': local['amount'],
    'type': local['type'],
    'category_id': local['categoryId'],
    'wallet_id': local['walletId'],
    'to_wallet_id': local['toWalletId'],
    'description': local['description'],
    'date': local['createdAt'],
    'recurring_id': local['recurringId'],
    'goal_id': local['goalId'],
    'metadata': local['metadata'] ?? {},
    'created_at': local['createdAt'],
    'updated_at': local['updatedAt'],
    'parent_transaction_id': local['parentTransactionId'],
    'is_split': local['isSplit'] ?? false,
    'split_index': local['splitIndex'],
  };
  remote['user_id'] = userId;
  return remote;
}

void main() {
  group('Remote payload includes user_id (Sprint 19 sync fix)', () {
    test('buildRemotePayloadForTransaction adds user_id', () {
      const userId = '550e8400-e29b-41d4-a716-446655440000';
      final local = {
        'id': 'tx-1',
        'amount': 10.5,
        'type': 'expense',
        'categoryId': 'cat-1',
        'walletId': 'wal-1',
        'createdAt': '2025-01-01T00:00:00.000Z',
      };
      final payload = buildRemotePayloadForTransaction(local, userId);
      expect(payload['user_id'], userId);
      expect(payload['id'], 'tx-1');
    });

    test('transaction toJson does not contain user_id', () {
      final t = Transaction(
        id: 't1',
        amount: 1,
        type: TransactionType.expense,
        categoryId: 'c1',
        walletId: 'w1',
        createdAt: DateTime.now(),
      );
      final j = t.toJson();
      expect(j.containsKey('user_id'), false);
    });

    test('transaction toJson then buildRemotePayload yields user_id in payload', () {
      const userId = 'user-123';
      final t = Transaction(
        id: 't1',
        amount: 1,
        type: TransactionType.expense,
        categoryId: 'c1',
        walletId: 'w1',
        createdAt: DateTime.now(),
      );
      final payload = buildRemotePayloadForTransaction(t.toJson(), userId);
      expect(payload['user_id'], userId);
      expect(payload['id'], 't1');
      expect(payload['amount'], 1);
      expect(payload['category_id'], 'c1');
    });
  });
}
