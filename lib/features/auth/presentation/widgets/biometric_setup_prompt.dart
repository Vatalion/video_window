import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/models/biometric_models.dart';
import '../bloc/auth_bloc.dart';

class BiometricSetupPrompt extends StatelessWidget {
  final BiometricType biometricType;
  final VoidCallback onSetupComplete;
  final VoidCallback onSkip;

  const BiometricSetupPrompt({
    super.key,
    required this.biometricType,
    required this.onSetupComplete,
    required this.onSkip,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                _biometricIcon,
                width: 48,
                height: 48,
                colorFilter: ColorFilter.mode(
                  Colors.blue.shade700,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Enable ${_biometricName}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            'Use ${_biometricName} for faster, more secure access to your account. Your biometric data never leaves your device.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Benefits
          _buildBenefitItem(
            icon: Icons.speed,
            title: 'Lightning Fast',
            description: 'Access your account in under a second',
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            icon: Icons.security,
            title: 'Highly Secure',
            description: 'Military-grade encryption protection',
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            icon: Icons.phonelink_lock,
            title: 'Device Only',
            description: 'Biometric data stays on your device',
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSkip,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Skip for Now'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final authBloc = context.read<AuthBloc>();
                    authBloc.add(SetupBiometricAuthEvent());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Enable ${_biometricName}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.green.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
