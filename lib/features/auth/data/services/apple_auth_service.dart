import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:video_window/features/auth/domain/models/social_auth_result.dart';
import 'package:video_window/features/auth/domain/models/social_account_model.dart';
import 'package:video_window/features/auth/domain/models/user_model.dart';
import 'package:logger/logger.dart';

abstract class AppleAuthService {
  Future<SocialAuthResult> signInWithApple({String? state});
  Future<void> signOutFromApple();
  Future<bool> isSignedIn();
  Future<Map<String, dynamic>?> getCurrentUser();
  Future<Map<String, dynamic>?> refreshToken();
}

class AppleAuthServiceImpl implements AppleAuthService {
  final Logger _logger;

  AppleAuthServiceImpl({Logger? logger}) : _logger = logger ?? Logger();

  @override
  Future<SocialAuthResult> signInWithApple({String? state}) async {
    try {
      _logger.i('Starting Apple Sign-In process');

      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        _logger.w('Apple Sign-In is not available on this device');
        return SocialAuthResult.error(
          errorMessage: 'Apple Sign-In is not available on this device',
          state: state,
        );
      }

      // Generate a nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Trigger the Apple Sign-In flow
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      if (credential.identityToken == null) {
        _logger.e('Apple identity token is null');
        return SocialAuthResult.error(
          errorMessage: 'Failed to get identity token from Apple',
          state: state,
        );
      }

      _logger.i(
        'Apple Sign-In successful for user: ${credential.email ?? 'unknown'}',
      );

      // Extract user information
      final email = credential.email;
      final givenName = credential.givenName;
      final familyName = credential.familyName;
      final displayName = givenName != null || familyName != null
          ? '${givenName ?? ''} ${familyName ?? ''}'.trim()
          : 'Apple User';

      // Create social account from Apple data
      final socialAccount = SocialAccountModel(
        id: 'social_apple_${DateTime.now().millisecondsSinceEpoch}',
        userId: '', // Will be set by backend
        provider: SocialProvider.apple,
        providerId: credential.userIdentifier ?? '',
        accessToken: credential.authorizationCode,
        idToken: credential.identityToken,
        email: email,
        displayName: displayName.isNotEmpty ? displayName : null,
        photoUrl: null, // Apple doesn't provide profile photos
        isActive: true,
        linkedAt: DateTime.now(),
      );

      // Create user from Apple data
      final user = UserModel.empty().copyWith(
        email: email ?? '',
        displayName: displayName.isNotEmpty ? displayName : 'Apple User',
        verificationStatus: VerificationStatus.fullyVerified,
        ageVerified: true, // Apple accounts are age-verified
        lastLoginAt: DateTime.now(),
      );

      _logger.i('Apple Sign-In completed successfully');

      return SocialAuthResult.success(
        user: user,
        socialAccount: socialAccount,
        isNewUser: true, // Backend will determine if user exists
        state: state,
      );
    } on SignInWithAppleException catch (e) {
      _logger.e('Apple Sign-In exception: ${e.toString()}');
      // Check if the error is a user cancellation
      if (e.toString().toLowerCase().contains('cancel') ||
          e.toString().toLowerCase().contains('user')) {
        return SocialAuthResult.cancelled(state: state);
      }
      return SocialAuthResult.error(
        errorMessage: 'Apple Sign-In failed: ${e.toString()}',
        state: state,
      );
    } catch (e) {
      _logger.e('Apple Sign-In unexpected error: ${e.toString()}');
      return SocialAuthResult.error(
        errorMessage: 'Apple Sign-In failed: ${e.toString()}',
        state: state,
      );
    }
  }

  @override
  Future<void> signOutFromApple() async {
    try {
      _logger.i('Signing out from Apple');
      // Apple Sign-In doesn't require explicit sign-out as credentials are session-based
      _logger.i('Apple Sign-Out completed (session-based)');
    } catch (e) {
      _logger.e('Failed to sign out from Apple: ${e.toString()}');
      throw Exception('Failed to sign out from Apple: ${e.toString()}');
    }
  }

  @override
  Future<bool> isSignedIn() async {
    try {
      // Apple Sign-In doesn't maintain persistent sign-in state
      // We would need to check stored credentials or tokens
      _logger.i('Apple Sign-In status: false (session-based)');
      return false;
    } catch (e) {
      _logger.e('Failed to check Apple Sign-In status: ${e.toString()}');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      // Apple Sign-In doesn't provide current user info without re-authentication
      _logger.i('Apple current user: null (session-based)');
      return null;
    } catch (e) {
      _logger.e('Failed to get current Apple user: ${e.toString()}');
      return null;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join('');
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<Map<String, dynamic>?> refreshToken() async {
    try {
      _logger.i('Attempting to refresh Apple token');

      // Apple Sign-In doesn't support token refresh in the traditional sense
      // Users need to re-authenticate to get fresh credentials
      _logger.w(
        'Apple Sign-In does not support token refresh - re-authentication required',
      );
      return null;
    } catch (e) {
      _logger.e('Failed to refresh Apple token: ${e.toString()}');
      return null;
    }
  }
}
