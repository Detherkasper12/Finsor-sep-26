import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../providers/premium_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../premium/premium_features.dart';
import 'dart:convert';
import '../../services/export/export_strategy.dart';
import '../../services/export/csv_export_strategy.dart';
import '../../services/observability_service.dart';
import '../../widgets/premium/premium_gate.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _includeWallets = false;
  bool _includeCategories = false;
  bool _isExporting = false;
  ExportResult? _lastExport;

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(isFeatureLockedProvider(PremiumFeature.exportData));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: isLocked
          ? const Center(child: PremiumLockedCard(feature: PremiumFeature.exportData))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.download,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Export your transaction data to CSV format for backup or analysis.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),

          const Gap(24),

          // Date Range
          Text(
            'Date Range (Optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8),
          Text(
            'Leave empty to export all transactions',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(12),

          Row(
            children: [
              Expanded(child: _buildDatePicker('Start Date', _startDate, (d) => setState(() => _startDate = d))),
              const Gap(16),
              Expanded(child: _buildDatePicker('End Date', _endDate, (d) => setState(() => _endDate = d))),
            ],
          ),

          const Gap(24),

          // Options
          Text(
            'Include',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(12),

          _buildOption(
            'Transactions',
            'Export all your transactions',
            true,
            null, // Always included
          ),
          _buildOption(
            'Wallets Summary',
            'Include wallet information',
            _includeWallets,
            (v) => setState(() => _includeWallets = v),
          ),
          _buildOption(
            'Categories',
            'Include category definitions',
            _includeCategories,
            (v) => setState(() => _includeCategories = v),
          ),

          const Gap(32),

          // Export Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportData,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isExporting ? 'Exporting...' : 'Export to CSV'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Last Export Result
          if (_lastExport != null) ...[
            const Gap(24),
            _buildExportResult(),
          ],

          const Gap(32),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? value, ValueChanged<DateTime?> onChanged) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        onChanged(date);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(50),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    value != null ? DateFormat('MMM d, yyyy').format(value) : 'Not set',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            if (value != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => onChanged(null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              Icon(
                Icons.calendar_today,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String title, String subtitle, bool value, ValueChanged<bool>? onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(30),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged != null ? (v) => onChanged(v ?? false) : null,
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  Widget _buildExportResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const Gap(12),
              Text(
                'Export Ready!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            '${_lastExport!.transactionCount} transactions exported',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'Filename: ${_lastExport!.filename}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy CSV'),
                ),
              ),
              const Gap(12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showPreview,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Preview'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    ObservabilityService.trackExportAttempted();
    setState(() => _isExporting = true);

    try {
      final transactions = await ref.read(transactionsProvider.future);
      final wallets = await ref.read(walletsProvider.future);
      final categories = await ref.read(categoriesProvider.future);

      final payload = ExportPayload(
        transactions: transactions,
        wallets: wallets,
        categories: categories,
        options: ExportOptions(
          startDate: _startDate,
          endDate: _endDate,
          includeWallets: _includeWallets,
          includeCategories: _includeCategories,
        ),
      );
      final strategy = CsvExportStrategy();
      final result = await strategy.generate(payload);

      setState(() {
        _lastExport = result;
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${result.transactionCount} transactions'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, st) {
      ObservabilityService.captureException(e, st, extras: {'feature': 'export'});
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard() {
    if (_lastExport != null && _lastExport!.filename.endsWith('.csv')) {
      Clipboard.setData(ClipboardData(text: utf8.decode(_lastExport!.bytes)));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showPreview() {
    if (_lastExport == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'CSV Preview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _lastExport!.filename.endsWith('.csv')
                      ? utf8.decode(_lastExport!.bytes)
                      : 'Binary export (preview not available)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
