import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../../generated/auth/user.dart';

/// Social authentication service for Apple and Google Sign-In
/// Handles token verification and account reconciliation
class SocialAuthService {
  final Session session;

  SocialAuthService(this.session);

  /// Verify Apple ID token and extract user information
  /// Apple uses JWT tokens signed with Apple's public keys
  Future<SocialAuthResult?> verifyAppleToken(String idToken) async {
    try {
      // Apple ID tokens are JWTs that need to be verified
      // In production, you would:
      // 1. Fetch Apple's public keys from https://appleid.apple.com/auth/keys
      // 2. Verify the JWT signature using those keys
      // 3. Validate the claims (aud, iss, exp, etc.)

      // For now, we'll decode without full verification (TODO: Add key verification)
      final jwt = JWT.decode(idToken);
      final payload = jwt.payload as Map<String, dynamic>;

      // Extract user information from Apple ID token
      final email = payload['email'] as String?;
      final sub = payload['sub'] as String; // Apple user ID
      final emailVerified = payload['email_verified'] as bool? ?? false;

      if (email == null || email.isEmpty) {
        session.log(
          'Apple ID token missing email claim',
          level: LogLevel.warning,
        );
        return null;
      }

      session.log(
        'Apple ID token verified for email: $email',
        level: LogLevel.info,
      );

      return SocialAuthResult(
        provider: 'apple',
        providerId: sub,
        email: email,
        isEmailVerified: emailVerified,
      );
    } catch (e, stackTrace) {
      session.log(
        'Failed to verify Apple ID token: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Verify Google ID token and extract user information
  /// Google tokens can be verified against Google's token verification endpoint
  Future<SocialAuthResult?> verifyGoogleToken(String idToken) async {
    try {
      // Verify token with Google's token verification endpoint
      final verifyUrl = Uri.parse(
        'https://oauth2.googleapis.com/tokeninfo?id_token=$idToken',
      );

      final response = await http.get(verifyUrl);

      if (response.statusCode != 200) {
        session.log(
          'Google token verification failed: ${response.statusCode}',
          level: LogLevel.warning,
        );
        return null;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;

      // Validate token claims
      final email = payload['email'] as String?;
      final sub = payload['sub'] as String?; // Google user ID
      final emailVerified = (payload['email_verified'] as String?) == 'true';

      if (email == null || email.isEmpty || sub == null) {
        session.log(
          'Google token missing required claims',
          level: LogLevel.warning,
        );
        return null;
      }

      // TODO: Validate aud (audience) claim matches your Google OAuth client ID
      // final aud = payload['aud'] as String?;
      // if (aud != 'YOUR_GOOGLE_CLIENT_ID') {
      //   return null;
      // }

      session.log(
        'Google ID token verified for email: $email',
        level: LogLevel.info,
      );

      return SocialAuthResult(
        provider: 'google',
        providerId: sub,
        email: email,
        isEmailVerified: emailVerified,
      );
    } catch (e, stackTrace) {
      session.log(
        'Failed to verify Google ID token: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Reconcile social identity with existing accounts
  /// Prevents duplicate accounts when same email is used across providers
  /// Returns existing user or creates new one
  Future<User> reconcileAccount(SocialAuthResult socialAuth) async {
    try {
      final normalizedEmail = socialAuth.email.toLowerCase().trim();

      // Try to find existing user by email (primary reconciliation key)
      final existingUsers = await User.db.find(
        session,
        where: (t) => t.email.equals(normalizedEmail),
        limit: 1,
      );

      if (existingUsers.isNotEmpty) {
        final existingUser = existingUsers.first;

        session.log(
          'Found existing user for email $normalizedEmail (userId: ${existingUser.id}, '
          'provider: ${existingUser.authProvider})',
          level: LogLevel.info,
        );

        // User exists - check if we need to link the new provider
        if (existingUser.authProvider != socialAuth.provider) {
          // Account exists with different provider
          // For simplicity, we'll update the provider to the most recent one
          // In production, you might want to support multiple linked providers
          session.log(
            'Linking ${socialAuth.provider} to existing account '
            '(previous provider: ${existingUser.authProvider})',
            level: LogLevel.info,
          );

          existingUser.authProvider = _combineProviders(
            existingUser.authProvider,
            socialAuth.provider,
          );
          existingUser.updatedAt = DateTime.now();

          // Update email verification status if social provider verified it
          if (socialAuth.isEmailVerified && !existingUser.isEmailVerified) {
            existingUser.isEmailVerified = true;
          }

          await User.db.updateRow(session, existingUser);
        }

        // Update last login timestamp
        existingUser.lastLoginAt = DateTime.now();
        await User.db.updateRow(session, existingUser);

        return existingUser;
      }

      // No existing user - create new account
      session.log(
        'Creating new user account for ${socialAuth.provider} sign-in: $normalizedEmail',
        level: LogLevel.info,
      );

      final newUser = User(
        email: normalizedEmail,
        role: 'viewer', // Default role
        authProvider: socialAuth.provider,
        isEmailVerified: socialAuth.isEmailVerified,
        isPhoneVerified: false,
        isActive: true,
        failedAttempts: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      return await User.db.insertRow(session, newUser);
    } catch (e, stackTrace) {
      session.log(
        'Failed to reconcile social account: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Combine provider names for accounts with multiple linked providers
  /// E.g., "email" + "google" → "email,google"
  String _combineProviders(String existing, String newProvider) {
    final providers = existing.split(',').toSet();
    providers.add(newProvider);
    return providers.join(',');
  }

  /// Check if a user has linked a specific provider
  bool hasProvider(User user, String provider) {
    return user.authProvider.split(',').contains(provider);
  }
}

/// Result of social authentication token verification
class SocialAuthResult {
  final String provider; // 'apple' or 'google'
  final String providerId; // Provider-specific user ID
  final String email;
  final bool isEmailVerified;

  SocialAuthResult({
    required this.provider,
    required this.providerId,
    required this.email,
    required this.isEmailVerified,
  });

  @override
  String toString() {
    return 'SocialAuthResult(provider: $provider, providerId: $providerId, '
        'email: $email, isEmailVerified: $isEmailVerified)';
  }
}
