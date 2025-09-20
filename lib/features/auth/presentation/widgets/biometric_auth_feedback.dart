import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/models/biometric_models.dart';

class BiometricAuthFeedback extends StatelessWidget {
  final BiometricAuthStatus status;
  final String? message;
  final BiometricType biometricType;
  final VoidCallback? onRetry;

  const BiometricAuthFeedback({
    super.key,
    required this.status,
    this.message,
    required this.biometricType,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon and Message
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor(),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(_getIcon(), color: _getIconColor(), size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitle(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getTextColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message ?? _getDefaultMessage(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: _getTextColor()),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Additional actions or info
          if (status == BiometricAuthStatus.lockedOut ||
              status == BiometricAuthStatus.temporarilyLocked) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please try again later or use an alternative authentication method',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Retry button for failures
          if (status == BiometricAuthStatus.error && onRetry != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (status) {
      case BiometricAuthStatus.available:
        return Colors.green.shade50;
      case BiometricAuthStatus.notAvailable:
      case BiometricAuthStatus.notEnrolled:
        return Colors.grey.shade50;
      case BiometricAuthStatus.lockedOut:
      case BiometricAuthStatus.temporarilyLocked:
        return Colors.orange.shade50;
      case BiometricAuthStatus.error:
        return Colors.red.shade50;
    }
  }

  Color _getBorderColor() {
    switch (status) {
      case BiometricAuthStatus.available:
        return Colors.green.shade200;
      case BiometricAuthStatus.notAvailable:
      case BiometricAuthStatus.notEnrolled:
        return Colors.grey.shade200;
      case BiometricAuthStatus.lockedOut:
      case BiometricAuthStatus.temporarilyLocked:
        return Colors.orange.shade200;
      case BiometricAuthStatus.error:
        return Colors.red.shade200;
    }
  }

  Color _getIconBackgroundColor() {
    switch (status) {
      case BiometricAuthStatus.available:
        return Colors.green.shade100;
      case BiometricAuthStatus.notAvailable:
      case BiometricAuthStatus.notEnrolled:
        return Colors.grey.shade100;
      case BiometricAuthStatus.lockedOut:
      case BiometricAuthStatus.temporarilyLocked:
        return Colors.orange.shade100;
      case BiometricAuthStatus.error:
        return Colors.red.shade100;
    }
  }

  Color _getIconColor() {
    switch (status) {
      case BiometricAuthStatus.available:
        return Colors.green.shade700;
      case BiometricAuthStatus.notAvailable:
      case BiometricAuthStatus.notEnrolled:
        return Colors.grey.shade700;
      case BiometricAuthStatus.lockedOut:
      case BiometricAuthStatus.temporarilyLocked:
        return Colors.orange.shade700;
      case BiometricAuthStatus.error:
        return Colors.red.shade700;
    }
  }

  IconData _getIcon() {
    switch (status) {
      case BiometricAuthStatus.available:
        return Icons.check_circle;
      case BiometricAuthStatus.notAvailable:
        return Icons.device_unknown;
      case BiometricAuthStatus.notEnrolled:
        return Icons.fingerprint;
      case BiometricAuthStatus.lockedOut:
      case BiometricAuthStatus.temporarilyLocked:
        return Icons.lock;
      case BiometricAuthStatus.error:
        return Icons.error;
    }
  }

  String _getTitle() {
    switch (status) {
      case BiometricAuthStatus.available:
        return 'Biometric Authentication Available';
      case BiometricAuthStatus.notAvailable:
        return 'Biometric Authentication Not Available';
      case BiometricAuthStatus.notEnrolled:
        return 'No Biometrics Enrolled';
      case BiometricAuthStatus.lockedOut:
      case BiometricAuthStatus.temporarilyLocked:
        return 'Biometric Authentication Locked';
      case BiometricAuthStatus.error:
        return 'Authentication Error';
    }
  }

  String _getDefaultMessage() {
    switch (status) {
      case BiometricAuthStatus.available:
        return 'You can use biometric authentication for faster access';
      case BiometricAuthStatus.notAvailable:
        return 'This device does not support biometric authentication';
      case BiometricAuthStatus.notEnrolled:
        return 'Please enroll biometrics in your device settings first';
      case BiometricAuthStatus.lockedOut:
        return 'Too many failed attempts. Biometric authentication is disabled';
      case BiometricAuthStatus.temporarilyLocked:
        return 'Biometric authentication is temporarily locked';
      case BiometricAuthStatus.error:
        return 'An error occurred during biometric authentication';
    }
  }
}
