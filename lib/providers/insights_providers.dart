import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/analytics_repository.dart';
import '../services/insight_context_builder.dart';
import '../services/insights_service.dart';
import '../services/observability_service.dart';
import 'analytics_providers.dart';
import 'repository_providers.dart';

final insightContextBuilderProvider = Provider<InsightContextBuilder>((ref) {
  final repo = ref.read(analyticsRepositoryProvider);
  return InsightContextBuilder(repo);
});

const _insightRefreshMinInterval = Duration(seconds: 10);
final lastInsightRefreshProvider = StateProvider<DateTime?>((ref) => null);

/// Provider for AI insights - builds context from analytics, generates insights
/// Uses ONLY AnalyticsRepository outputs - no raw transactions
final insightsProvider = FutureProvider<List<Insight>>((ref) async {
  try {
    final builder = ref.read(insightContextBuilderProvider);
    final walletId = ref.watch(selectedWalletIdProvider);
    final context = await builder.buildCurrentMonthContext(walletId: walletId);
    return InsightsService.generateFromContext(context);
  } catch (e, st) {
    ObservabilityService.captureException(e, st, extras: {'feature': 'ai_insights'});
    rethrow;
  }
});


