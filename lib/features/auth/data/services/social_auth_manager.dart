import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import 'package:video_window/features/auth/data/services/google_auth_service.dart';
import 'package:video_window/features/auth/data/services/apple_auth_service.dart';
import 'package:video_window/features/auth/data/services/facebook_auth_service.dart';
import 'package:video_window/features/auth/data/services/secure_token_storage.dart';
import 'package:video_window/features/auth/domain/models/social_auth_result.dart';
import 'package:video_window/features/auth/domain/models/social_account_model.dart';
import 'package:video_window/features/auth/domain/models/user_model.dart';
import 'package:video_window/features/auth/domain/repositories/auth_repository.dart';

class SocialAuthManager {
  final GoogleAuthService googleAuthService;
  final AppleAuthService appleAuthService;
  final FacebookAuthService facebookAuthService;
  final AuthRepository authRepository;
  final SecureTokenStorage secureTokenStorage;
  final Uuid _uuid;
  final Logger _logger;

  SocialAuthManager({
    required this.googleAuthService,
    required this.appleAuthService,
    required this.facebookAuthService,
    required this.authRepository,
    required this.secureTokenStorage,
    Logger? logger,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid(),
       _logger = logger ?? Logger();

  Future<SocialAuthResult> signInWithProvider(SocialProvider provider) async {
    // Generate and store CSRF state for security
    final state = _uuid.v4();
    await secureTokenStorage.storeCSRFState(state: state, provider: provider);

    switch (provider) {
      case SocialProvider.google:
        return await _handleGoogleSignIn(state);
      case SocialProvider.apple:
        return await _handleAppleSignIn(state);
      case SocialProvider.facebook:
        return await _handleFacebookSignIn(state);
    }
  }

  Future<SocialAuthResult> _handleGoogleSignIn(String state) async {
    try {
      final authResult = await googleAuthService.signInWithGoogle(state: state);

      if (!authResult.isSuccess) {
        return authResult;
      }

      // Validate CSRF state if returned by provider
      if (authResult.state != null &&
          !await secureTokenStorage.validateCSRFState(
            state: authResult.state!,
            provider: SocialProvider.google,
          )) {
        return SocialAuthResult.error(
          errorMessage: 'CSRF validation failed for Google Sign-In',
        );
      }

      // Process the social authentication result with backend
      return await _processSocialAuthResult(authResult, state);
    } catch (e) {
      _logger.e('Google Sign-In error: $e');
      return SocialAuthResult.error(
        errorMessage: 'Google Sign-In error: ${e.toString()}',
      );
    }
  }

  Future<SocialAuthResult> _handleAppleSignIn(String state) async {
    try {
      final authResult = await appleAuthService.signInWithApple(state: state);

      if (!authResult.isSuccess) {
        return authResult;
      }

      // Validate CSRF state if returned by provider
      if (authResult.state != null &&
          !await secureTokenStorage.validateCSRFState(
            state: authResult.state!,
            provider: SocialProvider.apple,
          )) {
        return SocialAuthResult.error(
          errorMessage: 'CSRF validation failed for Apple Sign-In',
        );
      }

      // Process the social authentication result with backend
      return await _processSocialAuthResult(authResult, state);
    } catch (e) {
      _logger.e('Apple Sign-In error: $e');
      return SocialAuthResult.error(
        errorMessage: 'Apple Sign-In error: ${e.toString()}',
      );
    }
  }

  Future<SocialAuthResult> _handleFacebookSignIn(String state) async {
    try {
      // Generate PKCE code verifier and challenge for Facebook
      final codeVerifier = _uuid.v4();
      final codeChallenge = _generatePKCEChallenge(codeVerifier);

      await secureTokenStorage.storePKCECodeVerifier(
        state: state,
        codeVerifier: codeVerifier,
      );

      final authResult = await facebookAuthService.signInWithFacebook(
        state: state,
        codeChallenge: codeChallenge,
      );

      if (!authResult.isSuccess) {
        return authResult;
      }

      // Validate CSRF state
      if (!await secureTokenStorage.validateCSRFState(
        state: state,
        provider: SocialProvider.facebook,
      )) {
        return SocialAuthResult.error(
          errorMessage: 'CSRF validation failed for Facebook Sign-In',
        );
      }

      // Process the social authentication result with backend
      return await _processSocialAuthResult(authResult, state);
    } catch (e) {
      _logger.e('Facebook Sign-In error: $e');
      return SocialAuthResult.error(
        errorMessage: 'Facebook Sign-In error: ${e.toString()}',
      );
    }
  }

  Future<SocialAuthResult> _processSocialAuthResult(
    SocialAuthResult authResult,
    String state,
  ) async {
    try {
      if (authResult.socialAccount == null || authResult.user == null) {
        return SocialAuthResult.error(
          errorMessage: 'Invalid social authentication result',
        );
      }

      // Call backend API to authenticate with social provider
      final backendResult = await authRepository.authenticateWithSocialProvider(
        provider: authResult.socialAccount!.provider,
        accessToken: authResult.socialAccount!.accessToken!,
        idToken: authResult.socialAccount!.idToken ?? '',
        state: state,
        codeVerifier: await secureTokenStorage.getPKCECodeVerifier(
          state: state,
        ),
      );

      if (!backendResult.isSuccess) {
        return SocialAuthResult.error(
          errorMessage:
              backendResult.errorMessage ?? 'Backend authentication failed',
        );
      }

      // Store tokens securely
      await secureTokenStorage.storeSocialAccessToken(
        userId: backendResult.user.id,
        provider: authResult.socialAccount!.provider,
        accessToken: authResult.socialAccount!.accessToken!,
        expiryDate: authResult.socialAccount!.tokenExpiresAt,
      );

      return backendResult;
    } catch (e) {
      _logger.e('Backend authentication error: $e');
      return SocialAuthResult.error(
        errorMessage: 'Backend authentication error: ${e.toString()}',
      );
    }
  }

  String _generatePKCEChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  Future<bool> unlinkSocialAccount({
    required String userId,
    required String socialAccountId,
  }) async {
    try {
      final success = await authRepository.unlinkSocialAccount(
        userId: userId,
        socialAccountId: socialAccountId,
      );

      if (success) {
        _logger.i('Successfully unlinked social account: $socialAccountId');
      } else {
        _logger.w('Failed to unlink social account: $socialAccountId');
      }

      return success;
    } catch (e) {
      _logger.e('Error unlinking social account: $e');
      return false;
    }
  }

  Future<List<SocialAccountModel>> getLinkedSocialAccounts(
    String userId,
  ) async {
    try {
      return await authRepository.getLinkedSocialAccounts(userId);
    } catch (e) {
      _logger.e('Error getting linked social accounts: $e');
      return [];
    }
  }

  Future<void> signOutFromProvider(SocialProvider provider) async {
    switch (provider) {
      case SocialProvider.google:
        await googleAuthService.signOutFromGoogle();
        break;
      case SocialProvider.apple:
        await appleAuthService.signOutFromApple();
        break;
      case SocialProvider.facebook:
        await facebookAuthService.signOutFromFacebook();
        break;
    }
  }

  Future<bool> isProviderSignedIn(SocialProvider provider) async {
    switch (provider) {
      case SocialProvider.google:
        return await googleAuthService.isSignedIn();
      case SocialProvider.apple:
        return await appleAuthService.isSignedIn();
      case SocialProvider.facebook:
        return await facebookAuthService.isSignedIn();
    }
  }

  Future<Map<String, dynamic>?> getProviderCurrentUser(
    SocialProvider provider,
  ) async {
    switch (provider) {
      case SocialProvider.google:
        return await googleAuthService.getCurrentUser();
      case SocialProvider.apple:
        return await appleAuthService.getCurrentUser();
      case SocialProvider.facebook:
        return await facebookAuthService.getCurrentUser();
    }
  }

  Future<bool> refreshSocialToken({
    required String userId,
    required SocialProvider provider,
  }) async {
    try {
      // Check if current token exists and is valid
      final currentToken = await secureTokenStorage.getSocialAccessToken(
        userId: userId,
        provider: provider,
      );

      if (currentToken != null) {
        _logger.i('Token for $provider is still valid');
        return true;
      }

      // Attempt to refresh the token based on provider
      final newToken = await _refreshTokenForProvider(provider);

      if (newToken != null) {
        // Store the new token securely
        await secureTokenStorage.storeSocialAccessToken(
          userId: userId,
          provider: provider,
          accessToken: newToken['accessToken'] as String,
          expiryDate: newToken['expiryDate'] as DateTime?,
        );

        // Update the token in the repository
        final socialAccount = await authRepository.getSocialAccountByProvider(
          userId: userId,
          provider: provider,
        );

        if (socialAccount != null) {
          await authRepository.updateSocialAccountToken(
            socialAccountId: socialAccount.id,
            accessToken: newToken['accessToken'] as String,
            expiryDate: newToken['expiryDate'] as DateTime?,
          );
        }

        _logger.i('Successfully refreshed token for $provider');
        return true;
      }

      _logger.w('Failed to refresh token for $provider');
      return false;
    } catch (e) {
      _logger.e('Error refreshing token for $provider: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _refreshTokenForProvider(
    SocialProvider provider,
  ) async {
    try {
      switch (provider) {
        case SocialProvider.google:
          return await googleAuthService.refreshToken();
        case SocialProvider.apple:
          return await appleAuthService.refreshToken();
        case SocialProvider.facebook:
          return await facebookAuthService.refreshToken();
      }
    } catch (e) {
      _logger.e('Error refreshing $provider token: $e');
      return null;
    }
  }

  Future<bool> validateAndRefreshTokens(String userId) async {
    try {
      final linkedAccounts = await authRepository.getLinkedSocialAccounts(
        userId,
      );
      bool allTokensValid = true;

      for (final account in linkedAccounts) {
        if (account.isTokenExpired) {
          _logger.i(
            'Token expired for ${account.provider}, attempting refresh',
          );
          final refreshed = await refreshSocialToken(
            userId: userId,
            provider: account.provider,
          );

          if (!refreshed) {
            allTokensValid = false;
            _logger.w('Failed to refresh token for ${account.provider}');
          }
        }
      }

      return allTokensValid;
    } catch (e) {
      _logger.e('Error validating and refreshing tokens: $e');
      return false;
    }
  }
}

extension SocialAuthResultExtension on SocialAuthResult {
  SocialAuthResult copyWith({
    UserModel? user,
    SocialAccountModel? socialAccount,
    bool? isNewUser,
    SocialAuthResultType? resultType,
    String? errorMessage,
    String? state,
  }) {
    return SocialAuthResult(
      user: user ?? this.user,
      socialAccount: socialAccount ?? this.socialAccount,
      isNewUser: isNewUser ?? this.isNewUser,
      resultType: resultType ?? this.resultType,
      errorMessage: errorMessage ?? this.errorMessage,
      state: state ?? this.state,
    );
  }
}
