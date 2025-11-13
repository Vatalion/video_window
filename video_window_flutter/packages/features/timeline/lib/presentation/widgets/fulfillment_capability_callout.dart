import 'package:flutter/material.dart';
import 'package:shared/design_system/tokens.dart';

/// Inline callout in fulfillment workspace when capability is missing
///
/// AC2: Fulfillment workspace surfaces FulfillmentCapabilityCallout when !canFulfillOrders
class FulfillmentCapabilityCallout extends StatelessWidget {
  final VoidCallback onEnableFulfillment;
  final VoidCallback? onDismiss;
  final bool isCompact;

  const FulfillmentCapabilityCallout({
    super.key,
    required this.onEnableFulfillment,
    this.onDismiss,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCallout();
    }
    return _buildFullCallout();
  }

  Widget _buildCompactCallout() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.info,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Enable fulfillment to manage orders',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.infoDark,
              ),
            ),
          ),
          TextButton(
            onPressed: onEnableFulfillment,
            child: Text(
              'Enable',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close),
              iconSize: 16,
              onPressed: onDismiss,
              color: AppColors.neutral500,
            ),
        ],
      ),
    );
  }

  Widget _buildFullCallout() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.info,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.neutral200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.info,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fulfillment Not Enabled',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Enable order fulfillment to manage shipping and tracking',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                  color: AppColors.neutral500,
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Requirements
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Prerequisites:',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.neutral900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '• Payment collection must be enabled\n'
                  '• Trusted device registration required',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutral700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onEnableFulfillment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              child: const Text(
                'Enable Fulfillment',
                style: AppTypography.labelLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
