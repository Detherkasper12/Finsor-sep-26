import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Use'),
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
                      'This is a placeholder terms of use document. '
                      'Complete terms will be available before public release.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            
            const Gap(24),
            
            _buildSection(
              context,
              'Acceptance of Terms',
              'By downloading, installing, or using Finsor, you agree to be bound by these '
              'Terms of Use. If you do not agree to these terms, please do not use the app.',
            ),
            
            _buildSection(
              context,
              'Use of the App',
              'Finsor is a personal finance management tool designed for individual use. '
              'You agree to use the app only for lawful purposes and in accordance with '
              'these terms.',
            ),
            
            _buildSection(
              context,
              'User Data',
              'You are responsible for the accuracy of the data you enter into the app. '
              'Finsor is not a replacement for professional financial advice.',
            ),
            
            _buildSection(
              context,
              'Premium Features',
              'Some features require a Premium subscription. Premium features are provided '
              'on an "as is" basis. Subscription terms and pricing are subject to change.',
            ),
            
            _buildSection(
              context,
              'Disclaimer',
              'Finsor is provided "as is" without warranties of any kind. We do not guarantee '
              'the accuracy of calculations or financial insights provided by the app.\n\n'
              'This app is not intended to provide financial, investment, or tax advice.',
            ),
            
            _buildSection(
              context,
              'Limitation of Liability',
              'To the fullest extent permitted by law, Finsor shall not be liable for any '
              'indirect, incidental, or consequential damages arising from your use of the app.',
            ),
            
            _buildSection(
              context,
              'Changes to Terms',
              'We may update these terms from time to time. Continued use of the app after '
              'changes constitutes acceptance of the new terms.',
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
