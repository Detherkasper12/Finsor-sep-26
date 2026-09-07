import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_database_service.dart';

/// Provider for database service singleton (now using Hive for persistence)
final databaseServiceProvider = Provider<HiveDatabaseService>((ref) {
  return HiveDatabaseService.instance;
});

/// Provider for database initialization
final databaseInitProvider = FutureProvider<void>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  await databaseService.init();
});

/// Provider for database info
final databaseInfoProvider = FutureProvider<Map<String, int>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getDatabaseInfo();
});
