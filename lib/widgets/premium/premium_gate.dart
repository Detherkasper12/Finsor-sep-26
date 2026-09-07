import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../premium/premium_features.dart';
import '../../providers/premium_provider.dart';
import '../../screens/premium/premium_screen.dart';

/// Widget that gates content behind a premium check
///
/// If the user has the required feature, [child] is displayed.
/// If not, [lockedPlaceholder] is shown (or a default premium badge).
///
/// This is a SOFT gate - no hard blocks, graceful disabled states.
class PremiumGate extends ConsumerWidget {
  /// The feature required to access this content
  final PremiumFeature feature;

  /// The content to show when feature is unlocked
  final Widget child;

  /// Optional custom placeholder when feature is locked
  final Widget? lockedPlaceholder;

  /// Whether to show a subtle badge instead of full placeholder
  final bool useSubtleBadge;

  const PremiumGate({
    super.key,
    required this.feature,
    required this.child,
    this.lockedPlaceholder,
    this.useSubtleBadge = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = ref.watch(isFeatureLockedProvider(feature));

    if (!isLocked) {
      return child;
    }

    if (useSubtleBadge) {
      return Stack(
        children: [
          Opacity(
            opacity: 0.6,
            child: IgnorePointer(child: child),
          ),
          const Positioned(
            top: 8,
            right: 8,
            child: PremiumBadge(size: PremiumBadgeSize.small),
          ),
        ],
      );
    }

    return lockedPlaceholder ?? PremiumLockedCard(feature: feature);
  }
}

/// Sizes for premium badge
enum PremiumBadgeSize { small, medium, large }

/// Premium badge widget
class PremiumBadge extends StatelessWidget {
  final PremiumBadgeSize size;

  const PremiumBadge({
    super.key,
    this.size = PremiumBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize;
    final EdgeInsets padding;
    final double iconSize;

    switch (size) {
      case PremiumBadgeSize.small:
        fontSize = 10;
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
        iconSize = 10;
        break;
      case PremiumBadgeSize.medium:
        fontSize = 12;
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
        iconSize = 12;
        break;
      case PremiumBadgeSize.large:
        fontSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
        iconSize = 14;
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade600,
            Colors.orange.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withAlpha(60),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: iconSize, color: Colors.white),
          Gap(size == PremiumBadgeSize.small ? 3 : 4),
          Text(
            'PRO',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper to convert icon name to IconData
IconData _iconFromName(String iconName) {
  switch (iconName) {
    case 'analytics':
      return Icons.analytics_outlined;
    case 'wallet':
      return Icons.account_balance_wallet_outlined;
    case 'smart_toy':
      return Icons.smart_toy_outlined;
    case 'download':
      return Icons.download_outlined;
    case 'currency_exchange':
      return Icons.currency_exchange_outlined;
    case 'notifications':
      return Icons.notifications_active_outlined;
    case 'category':
      return Icons.category_outlined;
    case 'cloud':
      return Icons.cloud_sync_outlined;
    default:
      return Icons.star_outline;
  }
}

/// Card shown when a premium feature is locked
class PremiumLockedCard extends StatelessWidget {
  final PremiumFeature feature;
  final VoidCallback? onUpgradeTap;

  const PremiumLockedCard({
    super.key,
    required this.feature,
    this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    final info = PremiumFeatureInfo.getInfo(feature);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withAlpha(50),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Premium badge
          const PremiumBadge(size: PremiumBadgeSize.large),
          const Gap(20),

          // Feature icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconFromName(info.iconName),
              size: 32,
              color: Colors.amber.shade700,
            ),
          ),
          const Gap(16),

          // Title
          Text(
            info.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(8),

          // Description
          Text(
            info.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(20),

          // Upgrade button (placeholder - no actual purchase flow)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpgradeTap ?? () => _showUpgradeInfo(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Upgrade to Premium',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeInfo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PremiumScreen()),
    );
  }
}

/// Simple banner for premium features
class PremiumFeatureBanner extends StatelessWidget {
  final String message;

  const PremiumFeatureBanner({
    super.key,
    this.message = 'This is a Premium feature',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber.withAlpha(50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
          const Gap(8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: Colors.amber.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
