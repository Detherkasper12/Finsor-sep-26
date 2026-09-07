import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/sync_provider.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/export/export_screen.dart';
import '../screens/backup/backup_screen.dart';
import '../screens/import/import_screen.dart';
import '../screens/legal/about_screen.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/legal/terms_screen.dart';
import '../screens/premium/premium_screen.dart';
import '../screens/recurring/manage_recurring_screen.dart';
import '../screens/goals/goals_screen.dart';
import '../services/sync_service.dart';
import '../utils/app_localizations.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumState = ref.watch(premiumStateProvider);
    final isAuth = ref.watch(isAuthenticatedProvider);
    final email = ref.watch(userEmailProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingOpsCountProvider);
    final lastSync = ref.watch(lastSyncAtProvider);
    final l10n = AppLocalizations.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, premiumState.isPremium),
            const Divider(height: 1),
            if (AppConfig.authEnabled && isAuth) ...[
              _SyncStatusTile(
                email: email,
                status: syncStatus,
                pendingCount: pendingCount,
                lastSyncAt: lastSync,
                onSyncNow: () {
                  final svc = ref.read(syncServiceProvider);
                  svc?.sync();
                },
                onLogout: () async {
                  await ref.read(authServiceProvider)?.signOut();
                  if (!context.mounted) return;
                  ref.read(syncServiceProvider.notifier).state = null;
                  ref.read(syncStatusProvider.notifier).state = SyncStatus.offline;
                  ref.invalidate(authStateProvider);
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1),
            ] else if (AppConfig.authEnabled) ...[
              ListTile(
                dense: true,
                leading: const Icon(Icons.cloud_outlined, size: 22),
                title: const Text('Sign in to sync'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                },
              ),
              const Divider(height: 1),
            ],
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Gap(8),
                  _DrawerItem(
                    icon: Icons.settings,
                    label: l10n.settings,
                    onTap: () => _navigate(context, const SettingsScreen()),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  _buildSectionLabel(context, 'Features'),
                  _DrawerItem(
                    icon: Icons.repeat,
                    label: 'Recurring Transactions',
                    onTap: () => _navigate(context, const ManageRecurringScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.savings,
                    label: 'Goals & Debts',
                    onTap: () => _navigate(context, const GoalsScreen()),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  _buildSectionLabel(context, 'Data Management'),
                  _DrawerItem(
                    icon: Icons.download,
                    label: 'Export CSV',
                    onTap: () => _navigate(context, const ExportScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.backup,
                    label: 'Backup',
                    onTap: () => _navigate(context, const BackupScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.upload,
                    label: 'Import / Restore',
                    onTap: () => _navigate(context, const ImportScreen()),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  _buildSectionLabel(context, 'About & Legal'),
                  _DrawerItem(
                    icon: Icons.info_outline,
                    label: 'About Finsor',
                    subtitle: 'Version ${AppConstants.appVersion}',
                    onTap: () => _navigate(context, const AboutScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () => _navigate(context, const PrivacyPolicyScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.description_outlined,
                    label: 'Terms of Use',
                    onTap: () => _navigate(context, const TermsScreen()),
                  ),
                  if (kDebugMode) ...[
                    const Divider(indent: 16, endIndent: 16),
                    _DrawerItem(
                      icon: Icons.star_outline,
                      label: 'Premium (Dev)',
                      subtitle: premiumState.isPremium ? 'Active' : 'Inactive',
                      onTap: () => _navigate(context, const PremiumScreen()),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isPremium) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primaryColor.withAlpha(30),
            child: const Icon(Icons.account_balance_wallet,
                color: AppTheme.primaryColor, size: 28),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.appName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold)),
                const Gap(2),
                Text(
                  isPremium ? 'Premium' : AppConstants.appTagline,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isPremium
                          ? Colors.amber.shade700
                          : Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5)),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context); // close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(label),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      onTap: onTap,
    );
  }
}

class _SyncStatusTile extends StatelessWidget {
  final String? email;
  final SyncStatus status;
  final int pendingCount;
  final DateTime? lastSyncAt;
  final VoidCallback onSyncNow;
  final VoidCallback onLogout;

  const _SyncStatusTile({
    required this.email,
    required this.status,
    required this.pendingCount,
    required this.lastSyncAt,
    required this.onSyncNow,
    required this.onLogout,
  });

  String get _statusLabel {
    switch (status) {
      case SyncStatus.idle:
        return lastSyncAt != null
            ? 'Last sync: ${_timeAgo(lastSyncAt!)}'
            : 'Idle';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.error:
        return 'Sync error';
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case SyncStatus.idle:
        return Icons.cloud_done;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.offline:
        return Icons.cloud_off;
      case SyncStatus.error:
        return Icons.error_outline;
    }
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const Gap(8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (email != null)
                      Text(email!, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600)),
                    Text(_statusLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$pendingCount', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const Gap(6),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: status == SyncStatus.syncing ? null : onSyncNow,
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Sync now', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ),
              const Gap(8),
              SizedBox(
                height: 32,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Logout', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
