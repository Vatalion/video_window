import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/models/biometric_models.dart';
import '../bloc/auth_bloc.dart';

class BiometricLoginButton extends StatelessWidget {
  final BiometricType biometricType;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? errorMessage;

  const BiometricLoginButton({
    super.key,
    required this.biometricType,
    this.onPressed,
    this.isLoading = false,
    this.errorMessage,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Biometric Login Button
        Container(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed ?? _handleBiometricLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        _biometricIcon,
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sign in with $_biometricName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _handleBiometricLogin() {
    // This will be handled by the parent widget through onPressed callback
  }
}
