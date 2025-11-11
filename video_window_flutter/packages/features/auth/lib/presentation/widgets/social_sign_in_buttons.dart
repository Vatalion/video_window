import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../lib/presentation/bloc/auth_bloc.dart';
import 'social_sign_in_service.dart';

/// Apple Sign-In button following Apple Human Interface Guidelines
class AppleSignInButton extends StatelessWidget {
  final SocialSignInService socialSignInService;
  final VoidCallback? onFallbackToEmail;

  const AppleSignInButton({
    super.key,
    required this.socialSignInService,
    this.onFallbackToEmail,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: socialSignInService.isAppleSignInAvailable(),
      builder: (context, snapshot) {
        // Only show Apple Sign-In button if available on this platform
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _handleAppleSignIn(context),
            icon: const Icon(Icons.apple, size: 24),
            label: const Text(
              'Sign in with Apple',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAppleSignIn(BuildContext context) async {
    try {
      // Show loading state
      // Note: AuthBloc will emit AuthLoading

      // Initiate Apple Sign-In flow
      final idToken = await socialSignInService.signInWithApple();

      if (idToken == null) {
        // User cancelled or error occurred
        // Optionally show fallback to email OTP
        if (onFallbackToEmail != null) {
          onFallbackToEmail!();
        }
        return;
      }

      if (!context.mounted) return;

      // Send token to backend via BLoC
      context.read<AuthBloc>().add(
            AuthAppleSignInRequested(idToken: idToken),
          );
    } catch (e) {
      // Handle error - fallback to email OTP
      if (onFallbackToEmail != null) {
        onFallbackToEmail!();
      }
    }
  }
}

/// Google Sign-In button following Google Brand Guidelines
class GoogleSignInButton extends StatelessWidget {
  final SocialSignInService socialSignInService;
  final VoidCallback? onFallbackToEmail;

  const GoogleSignInButton({
    super.key,
    required this.socialSignInService,
    this.onFallbackToEmail,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _handleGoogleSignIn(context),
        icon: Image.asset(
          'assets/images/google-logo.png',
          height: 24,
          width: 24,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image not found
            return const Icon(Icons.g_mobiledata, size: 24);
          },
        ),
        label: const Text(
          'Sign in with Google',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      // Initiate Google Sign-In flow
      final idToken = await socialSignInService.signInWithGoogle();

      if (idToken == null) {
        // User cancelled or error occurred
        // Optionally show fallback to email OTP
        if (onFallbackToEmail != null) {
          onFallbackToEmail!();
        }
        return;
      }

      if (!context.mounted) return;

      // Send token to backend via BLoC
      context.read<AuthBloc>().add(
            AuthGoogleSignInRequested(idToken: idToken),
          );
    } catch (e) {
      // Handle error - fallback to email OTP
      if (onFallbackToEmail != null) {
        onFallbackToEmail!();
      }
    }
  }
}

/// Combined social sign-in widget with both Apple and Google buttons
class SocialSignInButtons extends StatelessWidget {
  final SocialSignInService socialSignInService;
  final VoidCallback? onFallbackToEmail;

  const SocialSignInButtons({
    super.key,
    required this.socialSignInService,
    this.onFallbackToEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Apple Sign-In button (only shown on supported platforms)
        AppleSignInButton(
          socialSignInService: socialSignInService,
          onFallbackToEmail: onFallbackToEmail,
        ),
        const SizedBox(height: 12),
        // Google Sign-In button
        GoogleSignInButton(
          socialSignInService: socialSignInService,
          onFallbackToEmail: onFallbackToEmail,
        ),
        const SizedBox(height: 16),
        // Divider with "OR" text
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
