import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withAlpha(100)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'This is a placeholder privacy policy. '
                      'A complete policy will be available before public release.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            
            const Gap(24),
            
            _buildSection(
              context,
              'Data Collection',
              'Finsor collects and stores your financial data locally on your device. '
              'This includes transactions, categories, wallets, and app preferences.\n\n'
              'We do not collect any personal information unless you explicitly '
              'enable cloud sync features.',
            ),
            
            _buildSection(
              context,
              'Data Storage',
              'All your data is stored locally on your device using encrypted storage. '
              'Your financial information never leaves your device unless you choose '
              'to enable cloud backup features.',
            ),
            
            _buildSection(
              context,
              'Data Sharing',
              'We do not sell, trade, or share your personal information with third parties. '
              'Your financial data remains private and under your control.',
            ),
            
            _buildSection(
              context,
              'Analytics',
              'We may collect anonymous usage analytics to improve the app experience. '
              'This data does not include any personal or financial information.',
            ),
            
            _buildSection(
              context,
              'Your Rights',
              'You have the right to:\n'
              '• Export all your data at any time\n'
              '• Delete all your data from the app\n'
              '• Disable any optional data collection',
            ),
            
            _buildSection(
              context,
              'Contact',
              'For privacy-related questions, please contact us through the app\'s '
              'feedback feature or visit our website.',
            ),
            
            const Gap(24),
            
            Text(
              'Last updated: ${_formatDate(DateTime.now())}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
