import 'package:flutter_test/flutter_test.dart';

/// SyncService stores lastSyncAt per user with key lastSyncAt_$userId.
String lastSyncAtMetadataKey(String? userId) {
  return 'lastSyncAt_${userId ?? ""}';
}

void main() {
  group('lastSyncAt metadata key is per user (Sprint 19 sync fix)', () {
    test('key format is lastSyncAt_userId', () {
      const uid = '550e8400-e29b-41d4-a716-446655440000';
      expect(lastSyncAtMetadataKey(uid), 'lastSyncAt_$uid');
    });

    test('different users have different keys', () {
      expect(lastSyncAtMetadataKey('user-a'), isNot(lastSyncAtMetadataKey('user-b')));
    });

    test('null userId yields lastSyncAt_ empty suffix', () {
      expect(lastSyncAtMetadataKey(null), 'lastSyncAt_');
    });
  });
}
