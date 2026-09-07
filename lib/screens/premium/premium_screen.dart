import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../constants/iap_constants.dart';
import '../../providers/iap_provider.dart';
import '../../providers/premium_provider.dart';
import '../../services/iap_service.dart';
import '../../services/observability_service.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isPurchasing = false;
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      body: isPremium
          ? _PremiumActiveContent()
          : _PaywallContent(
              onUpgrade: _isPurchasing ? null : () => _handleUpgrade(context),
              onRestore: _isRestoring ? null : () => _handleRestore(context),
              isPurchasing: _isPurchasing,
              isRestoring: _isRestoring,
            ),
    );
  }

  Future<void> _handleUpgrade(BuildContext context) async {
    ObservabilityService.trackPremiumUpgradeAttempt();
    final iapService = ref.read(iapServiceProvider);
    if (!iapService.isAvailable) {
      _showStoreUnavailable(context);
      return;
    }

    setState(() => _isPurchasing = true);
    try {
      final response = await iapService.queryProducts();
      if (response.notFoundIDs.contains(IapConstants.premiumMonthly) &&
          response.notFoundIDs.contains(IapConstants.premiumYearly)) {
        if (mounted) _showStoreUnavailable(context);
        return;
      }

      final product = response.productDetails.isNotEmpty
          ? response.productDetails.first
          : null;
      if (product == null) {
        if (mounted) _showError(context, 'No products available');
        return;
      }

      final result = await iapService.purchase(product);
      if (!mounted) return;
      if (result.success) {
        ObservabilityService.trackPremiumPurchaseSuccess();
        ref.read(premiumStateProvider.notifier).grantPremium(tier: 'Premium');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium unlocked!')),
        );
      } else if (!result.canceled) {
        ObservabilityService.trackPremiumPurchaseFailure(reason: result.error);
        _showError(context, result.error ?? 'Purchase failed');
      }
    } catch (e, st) {
      ObservabilityService.captureException(e, st, extras: {'feature': 'iap_upgrade'});
      if (mounted) _showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    final iapService = ref.read(iapServiceProvider);
    if (!iapService.isAvailable) {
      _showStoreUnavailable(context);
      return;
    }

    setState(() => _isRestoring = true);
    try {
      await ref.read(premiumStateProvider.notifier).refreshPremiumState();
      if (!mounted) return;
      final isPremium = ref.read(isPremiumProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPremium ? 'Purchases restored!' : 'No purchases to restore.',
          ),
        ),
      );
    } catch (e, st) {
      ObservabilityService.captureException(e, st, extras: {'feature': 'iap_restore'});
      if (mounted) _showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  void _showStoreUnavailable(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Store Unavailable'),
        content: Text(
          kIsWeb
              ? 'In-app purchases are not available on web. Use the mobile app.'
              : 'Store is not available. Check your connection or try again later.\n\n'
                  'For testing, enable Premium in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          if (kDebugMode)
            TextButton(
              onPressed: () {
                ref.read(premiumStateProvider.notifier).grantPremium();
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Enable for Testing'),
            ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _PaywallContent extends StatelessWidget {
  final VoidCallback? onUpgrade;
  final VoidCallback? onRestore;
  final bool isPurchasing;
  final bool isRestoring;

  const _PaywallContent({
    required this.onUpgrade,
    required this.onRestore,
    this.isPurchasing = false,
    this.isRestoring = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.amber.shade50,
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Gap(16),

                    // Premium Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade600, Colors.orange.shade700],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withAlpha(100),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.white, size: 24),
                          Gap(8),
                          Text(
                            'FINSOR PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(32),

                    // Headline
                    Text(
                      'Unlock Your Full\nFinancial Potential',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                    ),

                    const Gap(12),

                    Text(
                      'Get advanced analytics, smart alerts, and more',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),

                    const Gap(40),

                    // Features List
                    _FeatureItem(
                      icon: Icons.analytics,
                      title: 'Advanced Analytics',
                      description: 'Detailed trends, comparisons, and spending insights',
                    ),
                    _FeatureItem(
                      icon: Icons.notifications_active,
                      title: 'Smart Budget Alerts',
                      description: 'Custom thresholds and proactive warnings',
                    ),
                    _FeatureItem(
                      icon: Icons.account_balance_wallet,
                      title: 'Unlimited Wallets',
                      description: 'Track all your accounts in one place',
                    ),
                    _FeatureItem(
                      icon: Icons.download,
                      title: 'Data Export',
                      description: 'Export to CSV or PDF for reporting',
                      isFuture: true,
                    ),
                    _FeatureItem(
                      icon: Icons.smart_toy,
                      title: 'AI Insights',
                      description: 'Smart categorization and predictions',
                      isFuture: true,
                    ),
                    _FeatureItem(
                      icon: Icons.cloud_sync,
                      title: 'Cloud Sync',
                      description: 'Sync across all your devices',
                      isFuture: true,
                    ),

                    const Gap(40),

                    // Comparison Table
                    _ComparisonTable(),

                    const Gap(40),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (isPurchasing || isRestoring) ? null : onUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: Colors.amber.withAlpha(100),
                      ),
                      child: isPurchasing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Upgrade to Premium',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const Gap(12),
                  TextButton(
                    onPressed: (isPurchasing || isRestoring) ? null : onRestore,
                    child: isRestoring
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Restore Purchases',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isFuture;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    this.isFuture = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.amber.shade700, size: 22),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (isFuture) ...[
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Coming Soon',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(30),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Free vs Premium',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Gap(20),
          _ComparisonRow(feature: 'Basic Analytics', free: true, premium: true),
          _ComparisonRow(feature: 'Category Breakdown', free: true, premium: true),
          _ComparisonRow(feature: 'Up to 3 Wallets', free: true, premium: false),
          _ComparisonRow(feature: 'Unlimited Wallets', free: false, premium: true),
          _ComparisonRow(feature: 'Advanced Trends', free: false, premium: true),
          _ComparisonRow(feature: 'Custom Budget Alerts', free: false, premium: true),
          _ComparisonRow(feature: 'Data Export', free: false, premium: true),
          _ComparisonRow(feature: 'Priority Support', free: false, premium: true),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String feature;
  final bool free;
  final bool premium;

  const _ComparisonRow({
    required this.feature,
    required this.free,
    required this.premium,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                free ? Icons.check_circle : Icons.remove_circle_outline,
                color: free ? Colors.green : Colors.grey,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                premium ? Icons.check_circle : Icons.remove_circle_outline,
                color: premium ? Colors.amber.shade700 : Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumActiveContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade600, Colors.orange.shade700],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withAlpha(100),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 64),
            ),
            const Gap(32),
            Text(
              'You\'re Premium!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Gap(12),
            Text(
              'Thank you for supporting Finsor.\nAll premium features are unlocked.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
