import 'package:flutter/material.dart';
import 'package:shared/design_system/tokens.dart';
import 'package:intl/intl.dart';

/// Widget displaying a device card with trust score and revoke option
///
/// AC3: Device management screen lists registered devices with trust score, last seen timestamp, and options to revoke
class DeviceCard extends StatelessWidget {
  final Map<String, dynamic> device;
  final VoidCallback onRevoke;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final trustScore = (device['trustScore'] as num?)?.toDouble() ?? 0.0;
    final lastSeenAt = device['lastSeenAt'] as String?;
    final deviceType = device['deviceType'] as String? ?? 'Unknown';
    final platform = device['platform'] as String? ?? 'Unknown';
    final deviceId = device['deviceId'] as String? ?? 'Unknown';

    // Format last seen timestamp
    String lastSeenText = 'Never';
    if (lastSeenAt != null) {
      try {
        final dateTime = DateTime.parse(lastSeenAt);
        final now = DateTime.now();
        final difference = now.difference(dateTime);

        if (difference.inDays > 0) {
          lastSeenText =
              '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
        } else if (difference.inHours > 0) {
          lastSeenText =
              '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
        } else if (difference.inMinutes > 0) {
          lastSeenText =
              '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
        } else {
          lastSeenText = 'Just now';
        }
      } catch (e) {
        lastSeenText = 'Unknown';
      }
    }

    // Determine trust score color
    Color trustScoreColor;
    if (trustScore >= 0.7) {
      trustScoreColor = AppColors.success;
    } else if (trustScore >= 0.5) {
      trustScoreColor = AppColors.warning;
    } else {
      trustScoreColor = AppColors.error;
    }

    // Get platform icon
    IconData platformIcon;
    switch (platform.toLowerCase()) {
      case 'ios':
        platformIcon = Icons.phone_iphone;
        break;
      case 'android':
        platformIcon = Icons.phone_android;
        break;
      case 'macos':
        platformIcon = Icons.laptop_mac;
        break;
      case 'windows':
        platformIcon = Icons.laptop_windows;
        break;
      case 'linux':
        platformIcon = Icons.computer;
        break;
      default:
        platformIcon = Icons.devices_other;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device header
            Row(
              children: [
                Icon(
                  platformIcon,
                  size: 32,
                  color: AppColors.primary,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDeviceName(deviceType, platform),
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        platform.toUpperCase(),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Trust score badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: trustScoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: trustScoreColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield,
                        size: 16,
                        color: trustScoreColor,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        '${(trustScore * 100).toInt()}%',
                        style: AppTypography.bodySmall.copyWith(
                          color: trustScoreColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSpacing.md),

            // Device details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last seen',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        lastSeenText,
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
                // Revoke button
                OutlinedButton.icon(
                  onPressed: onRevoke,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Revoke'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                  ),
                ),
              ],
            ),

            // Device ID (collapsed by default)
            SizedBox(height: AppSpacing.sm),
            Text(
              'Device ID: ${deviceId.substring(0, deviceId.length > 20 ? 20 : deviceId.length)}...',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutral500,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDeviceName(String deviceType, String platform) {
    // Format device name for display
    if (deviceType.toLowerCase().contains('iphone')) {
      return 'iPhone';
    } else if (deviceType.toLowerCase().contains('android')) {
      return 'Android Phone';
    } else if (deviceType.toLowerCase().contains('mac')) {
      return 'Mac';
    } else if (deviceType.toLowerCase().contains('windows')) {
      return 'Windows PC';
    } else if (deviceType.toLowerCase().contains('linux')) {
      return 'Linux PC';
    }
    return deviceType;
  }
}
