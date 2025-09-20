import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:video_window/features/auth/domain/models/social_auth_result.dart';
import 'package:video_window/features/auth/domain/models/social_account_model.dart';
import 'package:video_window/features/auth/domain/models/user_model.dart';
import 'package:logger/logger.dart';

abstract class GoogleAuthService {
  Future<SocialAuthResult> signInWithGoogle({String? state});
  Future<void> signOutFromGoogle();
  Future<bool> isSignedIn();
  Future<Map<String, dynamic>?> getCurrentUser();
  Future<Map<String, dynamic>?> refreshToken();
}

class GoogleAuthServiceImpl implements GoogleAuthService {
  final GoogleSignIn _googleSignIn;
  final Logger _logger;

  GoogleAuthServiceImpl({GoogleSignIn? googleSignIn, Logger? logger})
    : _googleSignIn = googleSignIn ?? GoogleSignIn(),
      _logger = logger ?? Logger();

  @override
  Future<SocialAuthResult> signInWithGoogle({String? state}) async {
    try {
      _logger.i('Starting Google Sign-In process');

      // Sign out from any existing session first
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _logger.w('Google Sign-In cancelled by user');
        return SocialAuthResult.cancelled(state: state);
      }

      _logger.i('Google Sign-In successful for user: ${googleUser.email}');

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        _logger.e('Google authentication tokens are null');
        return SocialAuthResult.error(
          errorMessage: 'Failed to get authentication tokens from Google',
          state: state,
        );
      }

      // Create social account from Google data
      final socialAccount = SocialAccountModel(
        id: 'social_google_${DateTime.now().millisecondsSinceEpoch}',
        userId: '', // Will be set by backend
        provider: SocialProvider.google,
        providerId: googleUser.id,
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
        email: googleUser.email,
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
        isActive: true,
        linkedAt: DateTime.now(),
      );

      // Create user from Google data
      final user = UserModel.empty().copyWith(
        email: googleUser.email,
        displayName: googleUser.displayName ?? 'Google User',
        photoUrl: googleUser.photoUrl,
        verificationStatus: VerificationStatus.fullyVerified,
        ageVerified: true, // Google accounts are age-verified
        lastLoginAt: DateTime.now(),
      );

      _logger.i('Google Sign-In completed successfully');

      return SocialAuthResult.success(
        user: user,
        socialAccount: socialAccount,
        isNewUser: true, // Backend will determine if user exists
        state: state,
      );
    } on PlatformException catch (e) {
      _logger.e('Google Sign-In platform error: ${e.toString()}');
      return SocialAuthResult.error(
        errorMessage:
            'Google Sign-In failed: ${e.message ?? 'Unknown platform error'}',
        state: state,
      );
    } catch (e) {
      _logger.e('Google Sign-In unexpected error: ${e.toString()}');
      return SocialAuthResult.error(
        errorMessage: 'Google Sign-In failed: ${e.toString()}',
        state: state,
      );
    }
  }

  @override
  Future<void> signOutFromGoogle() async {
    try {
      _logger.i('Signing out from Google');
      await _googleSignIn.signOut();
      _logger.i('Successfully signed out from Google');
    } catch (e) {
      _logger.e('Failed to sign out from Google: ${e.toString()}');
      throw Exception('Failed to sign out from Google: ${e.toString()}');
    }
  }

  @override
  Future<bool> isSignedIn() async {
    try {
      final isSignedIn = await _googleSignIn.isSignedIn();
      _logger.i('Google Sign-In status: $isSignedIn');
      return isSignedIn;
    } catch (e) {
      _logger.e('Failed to check Google Sign-In status: ${e.toString()}');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final currentUser = _googleSignIn.currentUser;
      if (currentUser == null) {
        return null;
      }

      final auth = await currentUser.authentication;

      return {
        'id': currentUser.id,
        'email': currentUser.email,
        'displayName': currentUser.displayName,
        'photoUrl': currentUser.photoUrl,
        'accessToken': auth.accessToken,
        'idToken': auth.idToken,
      };
    } catch (e) {
      _logger.e('Failed to get current Google user: ${e.toString()}');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> refreshToken() async {
    try {
      _logger.i('Attempting to refresh Google token');

      final currentUser = _googleSignIn.currentUser;
      if (currentUser == null) {
        _logger.w('No current Google user to refresh token for');
        return null;
      }

      // Get fresh authentication tokens
      final auth = await currentUser.authentication;

      if (auth.accessToken != null) {
        _logger.i('Successfully refreshed Google token');
        return {
          'accessToken': auth.accessToken,
          'idToken': auth.idToken,
          'expiryDate': null, // Google doesn't provide expiration date directly
        };
      }

      _logger.w('Failed to refresh Google token - no access token available');
      return null;
    } catch (e) {
      _logger.e('Failed to refresh Google token: ${e.toString()}');
      return null;
    }
  }
}
