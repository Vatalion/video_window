import 'package:flutter/material.dart';
import '../../domain/entities/device_entity.dart';

class DeviceCard extends StatelessWidget {
  final DeviceEntity device;

  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: device.isCurrentDevice
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/device-details',
            arguments: device,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getDeviceIcon(device.type),
                              size: 24,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (device.isCurrentDevice)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Current Device',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.type.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  DeviceTrustIndicator(trustScore: device.trustScore),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Last activity: ${_formatLastActivity(device.lastActivity)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              if (device.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        device.location!.country,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (!device.isCurrentDevice) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _showLogoutConfirmation(context);
                        },
                        child: const Text('Remote Logout'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        _showEditDeviceDialog(context);
                      },
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit Device',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      case 'web':
        return Icons.language;
      case 'desktop':
        return Icons.desktop_windows;
      case 'tablet':
        return Icons.tablet;
      default:
        return Icons.devices_other;
    }
  }

  String _formatLastActivity(DateTime lastActivity) {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remote Logout'),
        content: Text(
          'Are you sure you want to logout from "${device.name}"? '
          'This will immediately end all active sessions on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // This would be handled by the BLoC
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logout functionality would be implemented')),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showEditDeviceDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: device.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Device Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Device Name',
            hintText: 'Enter a name for this device',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                // This would be handled by the BLoC
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Device name update would be implemented')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Duplicate definition - this should be removed and imported from device_trust_indicator.dart
class DeviceTrustIndicator extends StatelessWidget {
  final int trustScore;

  const DeviceTrustIndicator({super.key, required this.trustScore});

  @override
  Widget build(BuildContext context) {
    final trustLevel = _getTrustLevel(trustScore);
    final color = _getTrustColor(trustLevel);
    final text = _getTrustText(trustLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTrustIcon(trustLevel),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$trustScore% $text',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  TrustLevel _getTrustLevel(int score) {
    if (score >= 80) return TrustLevel.high;
    if (score >= 50) return TrustLevel.medium;
    return TrustLevel.low;
  }

  Color _getTrustColor(TrustLevel level) {
    switch (level) {
      case TrustLevel.high:
        return Colors.green;
      case TrustLevel.medium:
        return Colors.orange;
      case TrustLevel.low:
        return Colors.red;
    }
  }

  String _getTrustText(TrustLevel level) {
    switch (level) {
      case TrustLevel.high:
        return 'Trusted';
      case TrustLevel.medium:
        return 'Medium';
      case TrustLevel.low:
        return 'Low';
    }
  }

  IconData _getTrustIcon(TrustLevel level) {
    switch (level) {
      case TrustLevel.high:
        return Icons.verified;
      case TrustLevel.medium:
        return Icons.warning_amber;
      case TrustLevel.low:
        return Icons.error_outline;
    }
  }
}