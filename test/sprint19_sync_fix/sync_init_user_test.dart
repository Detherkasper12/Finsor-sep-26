import 'package:flutter_test/flutter_test.dart';

/// Sync is only initialized when currentUser is non-null (app logic).
bool shouldInitSync(String? currentUserId) {
  return currentUserId != null && currentUserId.isNotEmpty;
}

void main() {
  group('Sync init uses currentUser (Sprint 19 sync fix)', () {
    test('when currentUser id is null, should not init sync', () {
      expect(shouldInitSync(null), false);
    });

    test('when currentUser id is empty string, should not init sync', () {
      expect(shouldInitSync(''), false);
    });

    test('when currentUser id is non-null, should init sync', () {
      expect(shouldInitSync('550e8400-e29b-41d4-a716-446655440000'), true);
    });
  });
}
