import 'package:flutter/material.dart';
import 'package:shared/design_system/tokens.dart';

/// Widget displaying a capability card with status badge and CTA button
///
/// AC1: Capability Center displays capability cards with status badges and CTAs
class CapabilityCard extends StatelessWidget {
  final String title;
  final String description;
  final CapabilityStatus status;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final List<String> blockers;

  const CapabilityCard({
    super.key,
    required this.title,
    required this.description,
    required this.status,
    this.onActionPressed,
    this.actionLabel,
    this.blockers = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppElevation.sm,
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: _getStatusColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleMedium,
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            SizedBox(height: AppSpacing.sm),

            // Description
            Text(
              description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),

            // Blockers (if any)
            if (blockers.isNotEmpty) ...[
              SizedBox(height: AppSpacing.sm),
              ...blockers.map(
                (blocker) => Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          blocker,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warningDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Action button
            if (onActionPressed != null && actionLabel != null) ...[
              SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getActionButtonColor(),
                    foregroundColor: AppColors.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppTypography.labelLarge,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: _getStatusColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 14,
            color: _getStatusColor(),
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            _getStatusLabel(),
            style: AppTypography.labelSmall.copyWith(
              color: _getStatusColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case CapabilityStatus.ready:
        return AppColors.success;
      case CapabilityStatus.inProgress:
        return AppColors.info;
      case CapabilityStatus.inReview:
        return AppColors.warning;
      case CapabilityStatus.blocked:
        return AppColors.error;
      case CapabilityStatus.inactive:
        return AppColors.neutral500;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case CapabilityStatus.ready:
        return Icons.check_circle;
      case CapabilityStatus.inProgress:
        return Icons.hourglass_empty;
      case CapabilityStatus.inReview:
        return Icons.pending;
      case CapabilityStatus.blocked:
        return Icons.block;
      case CapabilityStatus.inactive:
        return Icons.circle_outlined;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case CapabilityStatus.ready:
        return 'Ready';
      case CapabilityStatus.inProgress:
        return 'In Progress';
      case CapabilityStatus.inReview:
        return 'In Review';
      case CapabilityStatus.blocked:
        return 'Blocked';
      case CapabilityStatus.inactive:
        return 'Inactive';
    }
  }

  Color _getActionButtonColor() {
    switch (status) {
      case CapabilityStatus.inactive:
      case CapabilityStatus.blocked:
        return AppColors.primary;
      case CapabilityStatus.inProgress:
      case CapabilityStatus.inReview:
        return AppColors.neutral500;
      case CapabilityStatus.ready:
        return AppColors.success;
    }
  }
}

/// Capability status enum
enum CapabilityStatus {
  inactive,
  inProgress,
  inReview,
  ready,
  blocked,
}
