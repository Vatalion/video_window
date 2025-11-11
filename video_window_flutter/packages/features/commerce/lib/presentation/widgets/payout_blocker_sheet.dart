import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared/design_system/tokens.dart';

/// Bottom sheet displayed when payment collection capability is blocked
///
/// AC1: Opens modal summarizing payout prerequisites and provides Stripe Express onboarding CTA
class PayoutBlockerSheet extends StatelessWidget {
  final VoidCallback onEnablePayments;
  final VoidCallback? onCancel;
  final List<String> requirements;
  final String? stripeOnboardingUrl;

  const PayoutBlockerSheet({
    super.key,
    required this.onEnablePayments,
    this.onCancel,
    this.requirements = const [
      'Connect Stripe payout account',
      'Verify identity',
      'Provide tax information',
    ],
    this.stripeOnboardingUrl,
  });

  /// Show the bottom sheet
  ///
  /// AC1: Displays payout prerequisites and Stripe Express onboarding link
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onEnablePayments,
    VoidCallback? onCancel,
    List<String>? requirements,
    String? stripeOnboardingUrl,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PayoutBlockerSheet(
        onEnablePayments: onEnablePayments,
        onCancel: onCancel,
        requirements: requirements ?? const [],
        stripeOnboardingUrl: stripeOnboardingUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.lg),
          topRight: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Header with icon
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.payment_outlined,
                    color: AppColors.error,
                    size: 32,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Setup Required',
                        style: AppTypography.headlineSmall,
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Set up payments to start selling',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSpacing.lg),

            // Requirements
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete These Steps:',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.neutral900,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  ...requirements.map(
                    (requirement) => Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              requirement,
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.lg),

            // Action buttons
            Row(
              children: [
                if (onCancel != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        side: BorderSide(color: AppColors.neutral300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTypography.labelLarge,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // AC1: Launch Stripe Express onboarding if URL provided
                      if (stripeOnboardingUrl != null &&
                          stripeOnboardingUrl!.isNotEmpty) {
                        final uri = Uri.parse(stripeOnboardingUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          // Fallback to callback
                          onEnablePayments();
                        }
                      } else {
                        onEnablePayments();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Text(
                      stripeOnboardingUrl != null
                          ? 'Complete Stripe Setup'
                          : 'Set Up Payments',
                      style: AppTypography.labelLarge,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
