import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../config/app_config.dart';
import '../../models/user_settings.dart' as models;
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/sync_service.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../legal/about_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_screen.dart';
import '../export/export_screen.dart';
import '../import/import_screen.dart';
import '../backup/backup_screen.dart';
import '../auth/auth_screen.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/app_lock_gate.dart';
import '../../widgets/pin_setup_dialog.dart';
import '../../widgets/currency_picker.dart';
import '../../constants/currency_format_options.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (AppConfig.authEnabled) ...[
              _buildAccountSection(),
              const Gap(16),
            ],
            _buildSectionCard('App Preferences', [
              settings.when(
                data: (s) => _buildSwitchTile('Show Balance on Home',
                    'Display balance on home', Icons.visibility, s.showBalanceOnHome,
                    (v) => _toggleShowBalance(v)),
                loading: () => _buildLoadingTile(),
                error: (_, __) => _buildErrorTile(),
              ),
              settings.when(
                data: (s) => _buildSwitchTile('Enable Notifications',
                    'Budget and spending alerts', Icons.notifications, s.enableNotifications,
                    (v) => _toggleNotifications(v)),
                loading: () => _buildLoadingTile(),
                error: (_, __) => _buildErrorTile(),
              ),
              settings.when(
                data: (s) => _buildSwitchTile('Budget Alerts',
                    'Alert when approaching limits', Icons.warning, s.enableBudgetAlerts,
                    (v) => _toggleBudgetAlerts(v)),
                loading: () => _buildLoadingTile(),
                error: (_, __) => _buildErrorTile(),
              ),
            ]),
            const Gap(16),
            _buildSectionCard('Appearance & Locale', [
              settings.when(
                data: (s) => _buildSelectTile(l10n.theme, _getThemeDisplayName(s.themeMode),
                    Icons.palette, () => _showThemePicker(s)),
                loading: () => _buildLoadingTile(),
                error: (_, __) => _buildErrorTile(),
              ),
              settings.when(
                data: (s) => _buildSelectTile(l10n.currency,
                    '${s.primaryCurrency.name} (${s.primaryCurrency.symbol})',
                    Icons.monetization_on, () => _showCurrencyPicker(s)),
                loading: () => _buildLoadingTile(),
                error: (_, __) => _buildErrorTile(),
              ),
              settings.when(
                data: (s) => _buildSelectTile('Currency format', currencyFormatOptions.firstWhere((o) => o.id == s.currencyFormatId, orElse: () => currencyFormatOptions.first).example,
                    Icons.format_list_numbered, () => _showCurrencyFormatPicker(s)),
                loading: () => _buildLoadingTile(),
                error: (_, __) => _buildErrorTile(),
              ),
              settings.when(
                data: (s) => _buildSelectTile(l10n.language, _getLanguageDisplayName(s.locale),
                    Icons.language, () => _showLanguagePicker(s)),
                loading: () => _buildLoadingTile(),
                error: (_, __) => _buildErrorTile(),
              ),
            ]),
            const Gap(16),
            _buildSectionCard('Security', [
              settings.when(
                data: (s) => _buildSwitchTile('Require PIN', 'Protect app with PIN',
                    Icons.lock, s.requirePinForAccess, (v) => _togglePinRequirement(v)),
                loading: () => _buildLoadingTile(),
                error: (_, __) => _buildErrorTile(),
              ),
              settings.when(
                data: (s) => _buildSwitchTile('Use Biometrics', 'Fingerprint or face unlock',
                    Icons.fingerprint, s.useBiometrics, (v) => _toggleBiometrics(v)),
                loading: () => _buildLoadingTile(),
                error: (_, __) => _buildErrorTile(),
              ),
              settings.when(
                data: (s) => _buildSelectTile('Auto-Lock Timeout',
                    _getTimeoutLabel(s.autoLockTimeout), Icons.timer,
                    () => _showTimeoutPicker(s)),
                loading: () => _buildLoadingTile(),
                error: (_, __) => _buildErrorTile(),
              ),
            ]),
            const Gap(16),
            _buildSectionCard('Calendar & Startup', [
              settings.when(
                data: (s) => _buildSelectTile('Week start', s.weekStartDay == 1 ? 'Monday' : 'Sunday', Icons.view_week, () => _showWeekStartPicker(s)),
                loading: () => _buildLoadingTile(),
                error: (_, __) => _buildErrorTile(),
              ),
              settings.when(
                data: (s) => _buildSelectTile('Start screen', _startScreenLabel(s.startScreenIndex), Icons.home, () => _showStartScreenPicker(s)),
                loading: () => _buildLoadingTile(),
                error: (_, __) => _buildErrorTile(),
              ),
              settings.when(
                data: (s) => _buildSelectTile('Start of Month', 'Day ${s.startOfMonthDay}', Icons.calendar_today, () => _showStartOfMonthPicker(s)),
                loading: () => _buildLoadingTile(),
                error: (_, __) => _buildErrorTile(),
              ),
            ]),
            const Gap(16),
            if (kDebugMode) ...[_buildPremiumSection(), const Gap(16)],
            _buildSectionCard('Data Management', [
              _buildTile('Export Data', 'Download as CSV', Icons.download,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportScreen()))),
              _buildTile('Backup Data', 'Full JSON backup', Icons.backup,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen()))),
              _buildTile('Import Data', 'Restore from backup', Icons.upload,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen()))),
              if (kDebugMode)
                _buildTile('Sync now', 'Trigger cloud sync', Icons.sync, () => _onSyncNow()),
              _buildTile('Reset App', 'Clear all data', Icons.refresh,
                  () => _showResetDialog(), isDestructive: true),
            ]),
            const Gap(16),
            _buildSectionCard('About & Legal', [
              _buildTile('About Finsor', 'Version ${AppConstants.appVersion}', Icons.info,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
              _buildTile('Privacy Policy', 'Read our privacy policy', Icons.privacy_tip,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
              _buildTile('Terms of Use', 'Read our terms', Icons.description,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()))),
            ]),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final email = ref.watch(userEmailProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.getCardShadow(isDark: isDark),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Account', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (isAuthenticated) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: Icon(Icons.person, color: AppTheme.primaryColor),
              ),
              title: Text(email ?? 'Signed in'),
              subtitle: const Text('Cloud sync and AI available'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authServiceProvider)?.signOut();
                    if (!context.mounted) return;
                    ref.read(syncServiceProvider.notifier).state = null;
                    ref.read(syncStatusProvider.notifier).state = SyncStatus.offline;
                    ref.invalidate(authStateProvider);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
                    Navigator.popUntil(context, (r) => r.isFirst);
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('Sign out'),
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
                  icon: const Icon(Icons.login, size: 20),
                  label: const Text('Sign in / Create account'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.getCardShadow(isDark: isDark),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: AppTheme.primaryColor),
    );
  }

  Widget _buildTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDestructive ? Colors.red : AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : null)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSelectTile(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildLoadingTile() => const ListTile(leading: CircularProgressIndicator(), title: Text('Loading...'));
  Widget _buildErrorTile() => const ListTile(leading: Icon(Icons.error, color: Colors.red), title: Text('Error'));

  Widget _buildPremiumSection() {
    final premiumState = ref.watch(premiumStateProvider);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: premiumState.isPremium
            ? [Colors.amber.shade50, Colors.orange.shade50]
            : [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: premiumState.isPremium ? Colors.amber.withAlpha(100) : Theme.of(context).colorScheme.outline.withAlpha(25)),
      ),
      child: ListTile(
        leading: Icon(premiumState.isPremium ? Icons.star_rounded : Icons.star_outline,
            color: premiumState.isPremium ? Colors.amber.shade700 : null),
        title: const Text('Premium (Dev)'),
        subtitle: Text(premiumState.isPremium ? 'All features unlocked' : 'Toggle to test'),
        trailing: Switch(
          value: premiumState.isPremium,
          onChanged: (_) => ref.read(premiumStateProvider.notifier).togglePremium(),
          activeColor: Colors.amber.shade700,
        ),
      ),
    );
  }

  // Settings toggle methods
  Future<void> _toggleShowBalance(bool v) async {
    final s = await ref.read(settingsProvider.future);
    await ref.read(settingsNotifierProvider.notifier).updateSettings(s.copyWith(showBalanceOnHome: v, updatedAt: DateTime.now()));
  }

  Future<void> _toggleNotifications(bool v) async {
    final s = await ref.read(settingsProvider.future);
    await ref.read(settingsNotifierProvider.notifier).updateSettings(s.copyWith(enableNotifications: v, updatedAt: DateTime.now()));
  }

  Future<void> _toggleBudgetAlerts(bool v) async {
    final s = await ref.read(settingsProvider.future);
    await ref.read(settingsNotifierProvider.notifier).updateSettings(s.copyWith(enableBudgetAlerts: v, updatedAt: DateTime.now()));
  }

  Future<void> _togglePinRequirement(bool value) async {
    try {
      if (value) {
        final result = await PinSetupDialog.show(context);
        if (result == null || !result.success || result.pin == null) return;
        final ok = await setAppPin(result.pin!);
        if (!ok) return;
        ref.invalidate(hasPinSetProvider);
      } else {
        await clearAppPin();
        ref.invalidate(hasPinSetProvider);
      }
      final s = await ref.read(settingsProvider.future);
      await ref.read(settingsNotifierProvider.notifier).updateSettings(s.copyWith(requirePinForAccess: value, updatedAt: DateTime.now()));
    } catch (_) {}
  }

  Future<void> _toggleBiometrics(bool v) async {
    final s = await ref.read(settingsProvider.future);
    await ref.read(settingsNotifierProvider.notifier).updateSettings(s.copyWith(useBiometrics: v, updatedAt: DateTime.now()));
  }

  String _getThemeDisplayName(models.ThemeMode t) {
    switch (t) { case models.ThemeMode.light: return 'Light'; case models.ThemeMode.dark: return 'Dark'; case models.ThemeMode.system: return 'System'; }
  }

  String _getLanguageDisplayName(String code) {
    final list = AppLocalizations.supportedLanguagesWithNames.where((e) => e['code'] == code);
    if (list.isEmpty) return code;
    return list.first['name']!;
  }

  static const List<String> _startScreenLabels = ['Accounts', 'Categories', 'Operations', 'Budget', 'Overview'];
  String _startScreenLabel(int index) {
    if (index >= 0 && index < _startScreenLabels.length) return _startScreenLabels[index];
    return 'Accounts';
  }

  void _showCurrencyFormatPicker(models.UserSettings s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Currency format', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ...currencyFormatOptions.map((o) => ListTile(
            title: Text(o.name),
            subtitle: Text(o.example),
            trailing: s.currencyFormatId == o.id ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
            onTap: () async {
              Navigator.pop(ctx);
              await ref.read(settingsNotifierProvider.notifier).updateCurrencyFormatId(o.id);
            },
          )),
          const Gap(16),
        ],
      ),
    );
  }

  void _showWeekStartPicker(models.UserSettings s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Gap(16), const Text('Week start', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ListTile(title: const Text('Monday'), trailing: s.weekStartDay == 1 ? const Icon(Icons.check, color: AppTheme.primaryColor) : null, onTap: () async { Navigator.pop(ctx); await ref.read(settingsNotifierProvider.notifier).updateWeekStartDay(1); }),
        ListTile(title: const Text('Sunday'), trailing: s.weekStartDay == 7 ? const Icon(Icons.check, color: AppTheme.primaryColor) : null, onTap: () async { Navigator.pop(ctx); await ref.read(settingsNotifierProvider.notifier).updateWeekStartDay(7); }),
        const Gap(16),
      ]),
    );
  }

  void _showStartScreenPicker(models.UserSettings s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Gap(16), const Text('Start screen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...List.generate(_startScreenLabels.length, (i) => ListTile(
          title: Text(_startScreenLabels[i]),
          trailing: s.startScreenIndex == i ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
          onTap: () async { Navigator.pop(ctx); await ref.read(settingsNotifierProvider.notifier).updateStartScreenIndex(i); },
        )),
        const Gap(16),
      ]),
    );
  }

  void _showThemePicker(models.UserSettings s) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Gap(16), const Text('Choose Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...models.ThemeMode.values.map((t) => ListTile(
          leading: Icon(t == models.ThemeMode.light ? Icons.light_mode : t == models.ThemeMode.dark ? Icons.dark_mode : Icons.auto_mode),
          title: Text(_getThemeDisplayName(t)),
          trailing: s.themeMode == t ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
          onTap: () async { Navigator.pop(ctx); await ref.read(settingsNotifierProvider.notifier).updateSettings(s.copyWith(themeMode: t, updatedAt: DateTime.now())); },
        )),
        const Gap(16),
      ]));
  }

  void _showCurrencyPicker(models.UserSettings s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => CurrencyPicker(
        title: 'Choose Currency',
        selected: s.primaryCurrency,
        includeCrypto: false,
        onSelected: (c) async {
          Navigator.pop(ctx);
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dctx) => AlertDialog(
              title: const Text('Change base currency?'),
              content: const Text(
                'Base currency affects totals and analytics. Wallet currencies will NOT change. '
                'Amounts will be converted for display where exchange rates are available.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dctx, true),
                  child: const Text('Change'),
                ),
              ],
            ),
          );
          if (confirmed == true && mounted) {
            await ref.read(settingsNotifierProvider.notifier).updateSettings(
                  s.copyWith(primaryCurrency: c, updatedAt: DateTime.now()),
                );
          }
        },
      ),
    );
  }

  void _showLanguagePicker(models.UserSettings s) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(16),
          Text(l10n.language, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...AppLocalizations.supportedLanguagesWithNames.map((l) => ListTile(
            title: Text(l['name']!),
            trailing: s.locale == l['code'] ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
            onTap: () async {
              Navigator.pop(ctx);
              await ref.read(settingsNotifierProvider.notifier).updateSettings(
                    s.copyWith(locale: l['code']!, updatedAt: DateTime.now()),
                  );
            },
          )),
          const Gap(16),
        ],
      ),
    );
  }

  String _getTimeoutLabel(int seconds) {
    if (seconds == 0) return 'Immediate';
    if (seconds < 60) return '$seconds seconds';
    return '${seconds ~/ 60} minute${seconds >= 120 ? 's' : ''}';
  }

  void _showTimeoutPicker(models.UserSettings s) {
    final options = [0, 15, 30, 60, 120, 300];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(16),
          const Text('Auto-Lock Timeout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...options.map((sec) => ListTile(
                title: Text(_getTimeoutLabel(sec)),
                trailing: s.autoLockTimeout == sec
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(settingsNotifierProvider.notifier)
                      .updateSettings(s.copyWith(
                          autoLockTimeout: sec, updatedAt: DateTime.now()));
                },
              )),
          const Gap(16),
        ],
      ),
    );
  }

  void _showStartOfMonthPicker(models.UserSettings s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SizedBox(
        height: 400,
        child: Column(
          children: [
            const Gap(16),
            const Text('Start of Month Day',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Gap(4),
            Text('Affects budgets, analytics, and recurring transactions',
                style: Theme.of(context).textTheme.bodySmall),
            const Gap(8),
            Expanded(
              child: ListView.builder(
                itemCount: 28,
                itemBuilder: (ctx, i) {
                  final day = i + 1;
                  return ListTile(
                    title: Text('Day $day'),
                    trailing: s.startOfMonthDay == day
                        ? const Icon(Icons.check, color: AppTheme.primaryColor)
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ref
                          .read(settingsNotifierProvider.notifier)
                          .updateSettings(s.copyWith(
                              startOfMonthDay: day,
                              updatedAt: DateTime.now()));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSyncNow() async {
    final syncService = ref.read(syncServiceProvider);
    if (syncService == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync not available (signed out?)')),
        );
      }
      return;
    }
    try {
      await syncService.sync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }

  void _showResetDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Reset App'),
      content: const Text('Clear ALL data? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await ref.read(settingsNotifierProvider.notifier).resetAllData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data reset')));
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reset'),
        ),
      ],
    ));
  }
}
