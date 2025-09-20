import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/models/biometric_models.dart';
import '../bloc/auth_bloc.dart';

class BiometricSettingsToggle extends StatelessWidget {
  final BiometricType biometricType;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback? onToggle;
  final String? lockoutMessage;

  const BiometricSettingsToggle({
    super.key,
    required this.biometricType,
    required this.isEnabled,
    this.isLoading = false,
    this.onToggle,
    this.lockoutMessage,
  });

  String get _biometricName {
    switch (biometricType) {
      case BiometricType.faceId:
        return 'Face ID';
      case BiometricType.touchId:
        return 'Touch ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      default:
        return 'Biometrics';
    }
  }

  String get _biometricIcon {
    switch (biometricType) {
      case BiometricType.faceId:
        return 'assets/icons/face_id.svg';
      case BiometricType.touchId:
        return 'assets/icons/touch_id.svg';
      case BiometricType.fingerprint:
        return 'assets/icons/fingerprint.svg';
      default:
        return 'assets/icons/biometric.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isEnabled ? Colors.blue.shade50 : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    _biometricIcon,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      isEnabled ? Colors.blue.shade700 : Colors.grey.shade600,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _biometricName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      isEnabled ? 'Enabled' : 'Disabled',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isEnabled
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(
                  value: isEnabled,
                  onChanged: lockoutMessage != null ? null : onToggle,
                  activeColor: Colors.blue.shade700,
                ),
            ],
          ),

          if (lockoutMessage != null) ...[
            const SizedBox(height: 12),
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
                    Icons.lock_clock,
                    color: Colors.orange.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lockoutMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            // Description
            Text(
              'Use $_biometricName for quick and secure access to your account.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            // Security info
            Row(
              children: [
                Icon(Icons.shield, color: Colors.green.shade700, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Your biometric data never leaves your device',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
