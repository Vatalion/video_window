import 'package:flutter/material.dart';
import '../../../app_shell/legal_disclosures.dart';

/// Terms of Service display page
///
/// Shows the full terms of service with proper formatting
/// and acceptance tracking.
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  static const routeName = '/terms-of-service';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version and last updated info
            _buildInfoCard(context),
            const SizedBox(height: 24),

            // Main terms text
            _buildTermsText(context),
            const SizedBox(height: 32),

            // Important notices
            _buildImportantNotices(context),
            const SizedBox(height: 32),

            // Contact information
            _buildContactSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${LegalDisclosures.termsOfServiceVersion}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Last Updated: ${LegalDisclosures.lastUpdated}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsText(BuildContext context) {
    return Text(
      LegalDisclosures.termsOfServiceText,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildImportantNotices(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Text(
                  'Important Notices',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildNotice(
              context,
              'Age Requirement',
              'You must be at least 18 years old to use this service.',
            ),
            _buildNotice(
              context,
              'Account Responsibility',
              'You are responsible for all activity under your account.',
            ),
            _buildNotice(
              context,
              'Content Guidelines',
              'Illegal, harmful, or offensive content is prohibited.',
            ),
            _buildNotice(
              context,
              'Binding Arbitration',
              'Disputes are resolved through binding arbitration (where permitted by law).',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotice(BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questions About Terms?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'For questions about these Terms of Service, contact us at:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              LegalDisclosures.supportEmail,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
