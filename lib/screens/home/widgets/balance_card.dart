import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../models/transaction.dart';
import '../../../widgets/add_transaction_bottom_sheet.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/currency_formatter.dart';
import '../../../providers/settings_provider.dart';
import '../../../models/user_settings.dart';

/// Balance display card with gradient background
class BalanceCard extends ConsumerWidget {
  final double balance;
  final bool showBalance;
  final VoidCallback onToggleVisibility;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.showBalance,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currency = settings.when(
      data: (userSettings) => userSettings.primaryCurrency,
      loading: () => DefaultCurrencies.popular.first,
      error: (_, __) => DefaultCurrencies.popular.first,
    );
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        gradient: AppTheme.getPrimaryGradient(isDark: isDark),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: AppTheme.getCardShadow(isDark: isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Total Balance',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  showBalance ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                  size: 20,
                ),
                splashRadius: 20,
              ),
            ],
          ),
          const Gap(AppTheme.spacing8),
          Text(
            showBalance
                ? CurrencyFormatter.formatBalance(balance, currency)
                : '••••••',
            style: AppTheme.amountLarge.copyWith(
              color: Colors.white,
            ),
          ),
          const Gap(AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  icon: Icons.add,
                  label: 'Add Income',
                  onPressed: () {
                    _showAddTransactionModal(context, TransactionType.income);
                  },
                ),
              ),
              const Gap(AppTheme.spacing12),
              Expanded(
                child: ActionButton(
                  icon: Icons.remove,
                  label: 'Add Expense',
                  onPressed: () {
                    _showAddTransactionModal(context, TransactionType.expense);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Enhanced action button for balance card with animations
class ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacing16, 
                horizontal: AppTheme.spacing20,
              ),
              decoration: BoxDecoration(
                color: _isPressed 
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon, 
                    color: Colors.white, 
                    size: 20,
                  ),
                  const Gap(AppTheme.spacing8),
                  Text(
                    widget.label,
                    style: AppTheme.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

/// Helper function to show add transaction modal
void _showAddTransactionModal(BuildContext context, TransactionType type) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddTransactionBottomSheet(
      initialType: type,
    ),
  );
}
