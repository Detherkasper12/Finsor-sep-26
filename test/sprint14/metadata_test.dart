import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';

void main() {
  late HiveDatabaseService db;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final path = '${DateTime.now().millisecondsSinceEpoch}_metadata_test';
    Hive.init(path);
    db = HiveDatabaseService.instance;
    await db.init();
  });

  tearDownAll(() async {
    await db.close();
  });

  group('Metadata & Device ID', () {
    test('setMetadata and getMetadata roundtrip', () async {
      await db.setMetadata('test_key', 'test_value');
      expect(db.getMetadata('test_key'), 'test_value');
    });

    test('getMetadata returns null for missing key', () {
      expect(db.getMetadata('nonexistent_key_xyz'), isNull);
    });

    test('device_id can be stored and retrieved', () async {
      await db.setMetadata('device_id', 'test-device-uuid-1234');
      expect(db.getMetadata('device_id'), 'test-device-uuid-1234');
    });

    test('lastSyncAt can be stored and retrieved', () async {
      final now = DateTime.now().toUtc();
      await db.setMetadata('lastSyncAt', now.toIso8601String());
      
      final raw = db.getMetadata('lastSyncAt');
      expect(raw, isNotNull);
      
      final parsed = DateTime.parse(raw!);
      expect(parsed.year, now.year);
      expect(parsed.month, now.month);
      expect(parsed.day, now.day);
    });

    test('overwriting metadata key updates value', () async {
      await db.setMetadata('mutable_key', 'value_1');
      expect(db.getMetadata('mutable_key'), 'value_1');

      await db.setMetadata('mutable_key', 'value_2');
      expect(db.getMetadata('mutable_key'), 'value_2');
    });
  });
}
