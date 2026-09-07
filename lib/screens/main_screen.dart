import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wallets/wallets_screen.dart';
import 'categories/categories_overview_screen.dart';
import 'transactions/transactions_screen.dart';
import 'budgets/budgets_screen.dart';
import 'analytics/analytics_screen.dart';
import 'ai/ai_screen.dart';
import '../widgets/app_drawer.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';
import '../services/sync_service.dart';

/// Global key so child screens can open the drawer
final mainScaffoldKey = GlobalKey<ScaffoldState>();

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  bool _initialTabApplied = false;

  final List<Widget> _screens = const [
    WalletsScreen(),
    CategoriesOverviewScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
    AnalyticsScreen(),
    AIScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider, (_, next) {
      next.whenData((s) {
        if (!_initialTabApplied && mounted && s.startScreenIndex >= 0 && s.startScreenIndex < _screens.length) {
          _initialTabApplied = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentIndex = s.startScreenIndex);
          });
        }
      });
    });
    final syncStatus = ref.watch(syncStatusProvider);
    return Scaffold(
      key: mainScaffoldKey,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          if (syncStatus != SyncStatus.idle) _SyncStatusBar(status: syncStatus),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(75)
                : Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
        ],
      ),
    );
  }
}

class _SyncStatusBar extends StatelessWidget {
  final SyncStatus status;

  const _SyncStatusBar({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      SyncStatus.syncing => (Icons.sync, 'Syncing...', Colors.blue),
      SyncStatus.offline => (Icons.cloud_off, 'Offline', Colors.grey),
      SyncStatus.error => (Icons.error_outline, 'Sync error', Colors.red),
      SyncStatus.idle => (Icons.check_circle, 'Synced', Colors.green),
    };
    return Material(
      elevation: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: color.withAlpha(25),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
