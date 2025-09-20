import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_window/features/auth/presentation/bloc/auth_bloc.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback? onGoogleLogin;
  final VoidCallback? onAppleLogin;
  final VoidCallback? onFacebookLogin;
  final bool isLoading;

  const SocialLoginButtons({
    super.key,
    this.onGoogleLogin,
    this.onAppleLogin,
    this.onFacebookLogin,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Or continue with'),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSocialButton(
              context: context,
              icon: Icons.search,
              color: Colors.red,
              onPressed: isLoading ? null : onGoogleLogin,
              label: 'Google',
            ),
            _buildSocialButton(
              context: context,
              icon: Icons.apple,
              color: Colors.black,
              onPressed: isLoading ? null : onAppleLogin,
              label: 'Apple',
            ),
            _buildSocialButton(
              context: context,
              icon: Icons.facebook,
              color: Colors.blue,
              onPressed: isLoading ? null : onFacebookLogin,
              label: 'Facebook',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: onPressed,
              child: Icon(icon, color: color, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleLoginButton({super.key, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return _buildSocialSignInButton(
      context: context,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: Icons.search,
      label: 'Continue with Google',
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      borderColor: Colors.grey.shade300,
    );
  }
}

class AppleLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppleLoginButton({super.key, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return _buildSocialSignInButton(
      context: context,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: Icons.apple,
      label: 'Continue with Apple',
      backgroundColor: Colors.black,
      textColor: Colors.white,
      borderColor: Colors.black,
    );
  }
}

class FacebookLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const FacebookLoginButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSocialSignInButton(
      context: context,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: Icons.facebook,
      label: 'Continue with Facebook',
      backgroundColor: const Color(0xFF1877F2),
      textColor: Colors.white,
      borderColor: const Color(0xFF1877F2),
    );
  }
}

Widget _buildSocialSignInButton({
  required BuildContext context,
  required VoidCallback? onPressed,
  required bool isLoading,
  required IconData icon,
  required String label,
  required Color backgroundColor,
  required Color textColor,
  required Color borderColor,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
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
                Icon(icon, size: 24),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    ),
  );
}
