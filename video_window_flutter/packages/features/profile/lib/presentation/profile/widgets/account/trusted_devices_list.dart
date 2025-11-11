import 'package:flutter/material.dart';

/// Trusted devices list widget
/// AC1: Account settings tab offers trusted device list management
class TrustedDevicesList extends StatelessWidget {
  final int userId;

  const TrustedDevicesList({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Trusted Devices',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage devices that can access your account without additional verification',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        // TODO: Implement trusted devices list when backend API is available
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No trusted devices configured yet.\n'
              'Trusted devices will appear here after you enable device trust.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
