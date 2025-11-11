import 'package:flutter/material.dart';
import 'package:shared/design_system/tokens.dart';

/// Inline prompt card in publish flow when capability is missing
///
/// AC2: Publish flow inserts PublishCapabilityCard gate when !canPublish
/// Opens guided checklist modal with context (draft ID, entry point)
class PublishCapabilityCard extends StatelessWidget {
  final String? draftId;
  final VoidCallback onRequestCapability;
  final VoidCallback? onDismiss;
  final List<String> requirements;

  const PublishCapabilityCard({
    super.key,
    this.draftId,
    required this.onRequestCapability,
    this.onDismiss,
    this.requirements = const [
      'Complete identity verification',
      'Accept creator terms',
      'Verify contact information',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppElevation.md,
      margin: EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.warning,
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: AppColors.warning,
                    size: 32,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Publishing Locked',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.neutral900,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Complete these steps to publish your story',
                        style: AppTypography.bodyMedium.copyWith(
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

            SizedBox(height: AppSpacing.lg),

            // Requirements checklist
            Text(
              'Requirements:',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            SizedBox(height: AppSpacing.sm),

            ...requirements.map(
              (requirement) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: AppColors.neutral500,
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

            SizedBox(height: AppSpacing.lg),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRequestCapability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: Text(
                  'Enable Publishing',
                  style: AppTypography.labelLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
