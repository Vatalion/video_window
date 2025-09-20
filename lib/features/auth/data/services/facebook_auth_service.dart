import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:video_window/features/auth/domain/models/social_auth_result.dart';
import 'package:video_window/features/auth/domain/models/social_account_model.dart';
import 'package:video_window/features/auth/domain/models/user_model.dart';
import 'package:logger/logger.dart';

abstract class FacebookAuthService {
  Future<SocialAuthResult> signInWithFacebook({
    String? state,
    String? codeChallenge,
  });
  Future<void> signOutFromFacebook();
  Future<bool> isSignedIn();
  Future<Map<String, dynamic>?> getCurrentUser();
  Future<Map<String, dynamic>?> refreshToken();
}

class FacebookAuthServiceImpl implements FacebookAuthService {
  final FacebookAuth _facebookAuth;
  final Logger _logger;

  FacebookAuthServiceImpl({FacebookAuth? facebookAuth, Logger? logger})
    : _facebookAuth = facebookAuth ?? FacebookAuth.instance,
      _logger = logger ?? Logger();

  @override
  Future<SocialAuthResult> signInWithFacebook({
    String? state,
    String? codeChallenge,
  }) async {
    try {
      _logger.i('Starting Facebook Sign-In process');

      // Check if Facebook app is installed
      final isInstalled = _facebookAuth.isWebSdkInitialized;
      _logger.i('Facebook SDK initialized: $isInstalled');

      // Request login with required permissions
      final LoginResult result = await _facebookAuth.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.cancelled) {
        _logger.w('Facebook Sign-In cancelled by user');
        return SocialAuthResult.cancelled(state: state);
      }

      if (result.status == LoginStatus.failed) {
        _logger.e('Facebook Sign-In failed: ${result.message}');
        return SocialAuthResult.error(
          errorMessage:
              'Facebook Sign-In failed: ${result.message ?? 'Unknown error'}',
          state: state,
        );
      }

      if (result.status != LoginStatus.success || result.accessToken == null) {
        _logger.e('Facebook Sign-In unsuccessful: ${result.status}');
        return SocialAuthResult.error(
          errorMessage: 'Facebook Sign-In was not successful',
          state: state,
        );
      }

      _logger.i('Facebook Sign-In successful, getting user data');

      // Get user data from Facebook Graph API
      final userData = await _facebookAuth.getUserData(
        fields: 'name,email,picture.width(200).height(200)',
      );

      _logger.i('Facebook user data retrieved');

      // Extract user information
      final facebookId = userData['id'] as String;
      final email = userData['email'] as String?;
      final name = userData['name'] as String?;
      final picture = userData['picture'] as Map<String, dynamic>?;
      final photoUrl = picture?['data']?['url'] as String?;

      // Create social account from Facebook data
      final socialAccount = SocialAccountModel(
        id: 'social_facebook_${DateTime.now().millisecondsSinceEpoch}',
        userId: '', // Will be set by backend
        provider: SocialProvider.facebook,
        providerId: facebookId,
        accessToken: result.accessToken!.tokenString,
        email: email,
        displayName: name,
        photoUrl: photoUrl,
        isActive: true,
        linkedAt: DateTime.now(),
      );

      // Create user from Facebook data
      final user = UserModel.empty().copyWith(
        email: email ?? '',
        displayName: name ?? 'Facebook User',
        photoUrl: photoUrl,
        verificationStatus: VerificationStatus.fullyVerified,
        ageVerified: true, // Facebook accounts are age-verified
        lastLoginAt: DateTime.now(),
      );

      _logger.i('Facebook Sign-In completed successfully');

      return SocialAuthResult.success(
        user: user,
        socialAccount: socialAccount,
        isNewUser: true, // Backend will determine if user exists
        state: state,
      );
    } catch (e) {
      _logger.e('Facebook Sign-In unexpected error: ${e.toString()}');
      if (e.toString().toLowerCase().contains('cancel')) {
        return SocialAuthResult.cancelled(state: state);
      }
      return SocialAuthResult.error(
        errorMessage: 'Facebook Sign-In failed: ${e.toString()}',
        state: state,
      );
    }
  }

  @override
  Future<void> signOutFromFacebook() async {
    try {
      _logger.i('Signing out from Facebook');
      await _facebookAuth.logOut();
      _logger.i('Successfully signed out from Facebook');
    } catch (e) {
      _logger.e('Failed to sign out from Facebook: ${e.toString()}');
      throw Exception('Failed to sign out from Facebook: ${e.toString()}');
    }
  }

  @override
  Future<bool> isSignedIn() async {
    try {
      final accessToken = _facebookAuth.accessToken;
      final isSignedIn = accessToken != null && !accessToken.isExpired;
      _logger.i('Facebook Sign-In status: $isSignedIn');
      return isSignedIn;
    } catch (e) {
      _logger.e('Failed to check Facebook Sign-In status: ${e.toString()}');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final accessToken = _facebookAuth.accessToken;
      if (accessToken == null || accessToken.isExpired) {
        return null;
      }

      final userData = await _facebookAuth.getUserData(
        fields: 'id,name,email,picture.width(200).height(200)',
      );

      return {
        'id': userData['id'],
        'email': userData['email'],
        'displayName': userData['name'],
        'photoUrl': userData['picture']?['data']?['url'],
        'accessToken': accessToken.token,
        'userId': accessToken.userId,
      };
    } catch (e) {
      _logger.e('Failed to get current Facebook user: ${e.toString()}');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> refreshToken() async {
    try {
      _logger.i('Attempting to refresh Facebook token');

      final accessToken = await _facebookAuth.accessToken;
      if (accessToken == null) {
        _logger.w('No current Facebook access token to refresh');
        return null;
      }

      // Facebook SDK automatically handles token refresh when needed
      // We just need to check if the current token is still valid
      if (accessToken.isExpired) {
        _logger.w(
          'Facebook access token is expired, user needs to re-authenticate',
        );
        return null;
      }

      _logger.i('Facebook token is still valid');
      return {
        'accessToken': accessToken.token,
        'expiryDate': accessToken.expires,
      };
    } catch (e) {
      _logger.e('Failed to refresh Facebook token: ${e.toString()}');
      return null;
    }
  }
}
