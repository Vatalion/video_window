import 'package:flutter/material.dart';
import '../../../app_shell/legal_disclosures.dart';

/// Privacy Policy display page
///
/// Shows the full privacy policy text with proper formatting
/// and GDPR/CCPA disclosures.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const routeName = '/privacy-policy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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

            // Main privacy policy text
            _buildPolicyText(context),
            const SizedBox(height: 32),

            // GDPR disclosures
            _buildGdprDisclosures(context),
            const SizedBox(height: 24),

            // CCPA disclosures
            _buildCcpaDisclosures(context),
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
              'Version ${LegalDisclosures.privacyPolicyVersion}',
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

  Widget _buildPolicyText(BuildContext context) {
    return Text(
      LegalDisclosures.privacyPolicyText,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildGdprDisclosures(BuildContext context) {
    final gdpr = LegalDisclosures.gdprDisclosures;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.euro, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'GDPR Information (EU Users)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              'Data Controller',
              gdpr['data_controller'] as String,
            ),
            _buildInfoRow(
              context,
              'DPO Email',
              gdpr['dpo_email'] as String,
            ),
            _buildInfoRow(
              context,
              'Legal Basis',
              gdpr['legal_basis'] as String,
            ),
            _buildInfoRow(
              context,
              'Data Retention',
              gdpr['data_retention'] as String,
            ),
            const SizedBox(height: 12),
            Text(
              'Your Rights:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...((gdpr['user_rights'] as List).map((right) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(right as String)),
                    ],
                  ),
                ))),
          ],
        ),
      ),
    );
  }

  Widget _buildCcpaDisclosures(BuildContext context) {
    final ccpa = LegalDisclosures.ccpaDisclosures;

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'CCPA Information (California Users)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              'Business Name',
              ccpa['business_name'] as String,
            ),
            _buildInfoRow(
              context,
              'Sale of Data',
              (ccpa['sale_of_data'] as bool)
                  ? 'Yes'
                  : 'No (We do not sell your data)',
            ),
            _buildInfoRow(
              context,
              'Opt-Out Available',
              (ccpa['opt_out_available'] as bool) ? 'Yes' : 'No',
            ),
            const SizedBox(height: 12),
            Text(
              'Categories of Data Collected:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...((ccpa['categories_collected'] as List)
                .map((category) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.fiber_manual_record, size: 12),
                          const SizedBox(width: 8),
                          Expanded(child: Text(category as String)),
                        ],
                      ),
                    ))),
          ],
        ),
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
              'Contact Us',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Privacy Questions',
              LegalDisclosures.dpoEmail,
            ),
            _buildInfoRow(
              context,
              'General Support',
              LegalDisclosures.supportEmail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
