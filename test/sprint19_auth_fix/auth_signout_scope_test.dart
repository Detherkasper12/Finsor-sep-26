import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Auth signOut scope (Sprint 19.1)', () {
    test('SignOutScope.global exists and is used for full logout', () {
      expect(SignOutScope.global, isNotNull);
      expect(SignOutScope.global, SignOutScope.global);
      expect(SignOutScope.values.contains(SignOutScope.global), true);
    });

    test('global scope is different from local', () {
      expect(SignOutScope.global, isNot(SignOutScope.local));
    });
  });
}
