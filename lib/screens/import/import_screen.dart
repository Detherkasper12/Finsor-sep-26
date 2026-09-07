import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/database_provider.dart';
import '../../providers/transaction_provider.dart' hide recentTransactionsProvider;
import '../../providers/repository_providers.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restore Backup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select a Finsor backup file (.json) to restore your data. '
              'This will replace your current data.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            if (_error != null) const SizedBox(height: 16),
            if (_success != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_success!, style: const TextStyle(color: Colors.green))),
                  ],
                ),
              ),
            if (_success != null) const SizedBox(height: 16),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndImport,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file),
              label: Text(_isLoading ? 'Importing...' : 'Select backup file'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndImport() async {
    setState(() {
      _error = null;
      _success = null;
      _isLoading = true;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      final file = result.files.single;
      final rawBytes = file.bytes;
      if (rawBytes == null || rawBytes.isEmpty) {
        setState(() {
          _error = 'Could not read file. Try selecting again.';
          _isLoading = false;
        });
        return;
      }
      String contents;
      try {
        contents = utf8.decode(rawBytes);
      } catch (_) {
        setState(() {
          _error = 'File is not valid text encoding.';
          _isLoading = false;
        });
        return;
      }
      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(contents);
        if (decoded is! Map<String, dynamic>) {
          setState(() {
            _error = 'Invalid backup file format.';
            _isLoading = false;
          });
          return;
        }
        data = decoded;
      } catch (_) {
        setState(() {
          _error = 'Invalid or corrupted backup file. Check the file and try again.';
          _isLoading = false;
        });
        return;
      }
      final version = data['version'];
      final versionOk = version == 1 || version == '1' || (version is num && version.toInt() == 1);
      if (!versionOk) {
        setState(() {
          _error = 'Unsupported backup version. Use a backup from this app.';
          _isLoading = false;
        });
        return;
      }
      final hasData = data['wallets'] != null ||
          data['transactions'] != null ||
          data['categories'] != null;
      if (!hasData) {
        setState(() {
          _error = 'Invalid backup file: no data to restore.';
          _isLoading = false;
        });
        return;
      }
      final db = ref.read(databaseServiceProvider);
      await db.importDataReplace(data);

      ref.invalidate(transactionsProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(budgetsProvider);
      ref.invalidate(periodSummaryProvider);
      ref.invalidate(settingsProvider);

      final syncService = ref.read(syncServiceProvider);
      Future.microtask(() => syncService?.sync());

      if (mounted) {
        setState(() {
          _success = 'Backup restored successfully';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to restore: $e';
          _isLoading = false;
        });
      }
    }
  }
}
