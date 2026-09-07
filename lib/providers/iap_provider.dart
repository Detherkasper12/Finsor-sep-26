import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/iap_service.dart';

final iapServiceProvider = Provider<IapService>((ref) {
  final service = IapService();
  ref.onDispose(() => service.dispose());
  return service;
});

final iapAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(iapServiceProvider);
  return service.initialize();
});
