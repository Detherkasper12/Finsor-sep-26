import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/providers/insights_providers.dart';

void main() {
  group('Insight refresh rate limit', () {
    test('lastInsightRefreshProvider is initially null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(lastInsightRefreshProvider), isNull);
    });

    test('lastInsightRefreshProvider can be set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final now = DateTime.now();
      container.read(lastInsightRefreshProvider.notifier).state = now;
      expect(container.read(lastInsightRefreshProvider), equals(now));
    });
  });
}
