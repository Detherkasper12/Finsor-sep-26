import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/wallet.dart';
import '../models/user_settings.dart';
import '../utils/currency_formatter.dart';
import '../constants/app_theme.dart';

/// Enhanced wallet card with smooth animations and haptic feedback
class AnimatedWalletCard extends StatefulWidget {
  final Wallet wallet;
  final Currency currency;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AnimatedWalletCard({
    super.key,
    required this.wallet,
    required this.currency,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<AnimatedWalletCard> createState() => _AnimatedWalletCardState();
}

class _AnimatedWalletCardState extends State<AnimatedWalletCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Start shimmer animation if selected
    if (widget.isSelected) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedWalletCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle selection state change
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _shimmerController.repeat();
        HapticFeedback.selectionClick();
      } else {
        _shimmerController.stop();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    widget.onLongPress?.call();
  }

  Color get _walletColor {
    return Color(
        int.parse((widget.wallet.color ?? '#4CAF50').replaceAll('#', '0xFF')));
  }

  IconData get _walletIcon {
    switch (widget.wallet.type) {
      case WalletType.cash:
        return Icons.payments;
      case WalletType.bank:
        return Icons.account_balance;
      case WalletType.card:
        return Icons.credit_card;
      case WalletType.savings:
        return Icons.savings;
      case WalletType.investment:
        return Icons.trending_up;
      case WalletType.crypto:
        return Icons.currency_bitcoin; //
      case WalletType.other:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: _onTapCancel,
      onLongPress: _onLongPress,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _shimmerAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 140,
              height: 100,
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _walletColor,
                          _walletColor.withOpacity(0.8),
                        ],
                      )
                    : null,
                color: widget.isSelected
                    ? null
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected
                      ? _walletColor
                      : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: _walletColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: _walletColor.withOpacity(0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : AppTheme.getCardShadow(isDark: isDark),
              ),
              child: Stack(
                children: [
                  // Shimmer effect for selected card
                  if (widget.isSelected)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.2),
                                Colors.transparent,
                              ],
                              stops: [
                                (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                                _shimmerAnimation.value.clamp(0.0, 1.0),
                                (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
                              ],
                            ).createShader(bounds);
                          },
                          child: Container(color: Colors.white),
                        ),
                      ),
                    ),

                  // Card content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon and type indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : _walletColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _walletIcon,
                                color: widget.isSelected
                                    ? Colors.white
                                    : _walletColor,
                                size: 16,
                              ),
                            ),
                            if (widget.wallet.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.isSelected
                                      ? Colors.white.withOpacity(0.2)
                                      : AppTheme.successColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'DEFAULT',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isSelected
                                        ? Colors.white
                                        : AppTheme.successColor,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const Spacer(),

                        // Wallet name
                        Text(
                          widget.wallet.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: widget.isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 2),

                        // Balance (wallet's own currency)
                        Text(
                          CurrencyFormatter.formatWalletBalance(widget.wallet),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: widget.isSelected
                                        ? Colors.white.withOpacity(0.9)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// "All Wallets" special card
class AllWalletsCard extends StatefulWidget {
  final double totalBalance;
  final Currency currency;
  final bool isSelected;
  final VoidCallback onTap;

  const AllWalletsCard({
    super.key,
    required this.totalBalance,
    required this.currency,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<AllWalletsCard> createState() => _AllWalletsCardState();
}

class _AllWalletsCardState extends State<AllWalletsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
        if (widget.isSelected) {
          HapticFeedback.selectionClick();
        }
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 140,
              height: 100,
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withOpacity(0.1),
                          primaryColor.withOpacity(0.05),
                        ],
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected
                      ? primaryColor
                      : primaryColor.withOpacity(0.3),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : AppTheme.getCardShadow(isDark: isDark),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? Colors.white.withOpacity(0.2)
                            : primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: widget.isSelected ? Colors.white : primaryColor,
                        size: 16,
                      ),
                    ),

                    const Spacer(),

                    // Title
                    Text(
                      'All Wallets',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color:
                                widget.isSelected ? Colors.white : primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),

                    const SizedBox(height: 2),

                    // Total balance
                    Text(
                      CurrencyFormatter.formatBalance(
                        widget.totalBalance,
                        widget.currency,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.isSelected
                                ? Colors.white.withOpacity(0.9)
                                : primaryColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
