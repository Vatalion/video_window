import 'dart:convert';
import 'dart:typed_data';
import 'package:logger/logger.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:video_window/features/auth/domain/models/social_account_model.dart';

class SocialTokenValidator {
  final Logger _logger;

  static const Map<SocialProvider, Set<String>> _requiredScopes = {
    SocialProvider.google: {'email', 'profile', 'openid'},
    SocialProvider.apple: {'email', 'name'},
    SocialProvider.facebook: {'email', 'public_profile'},
  };

  static const Map<SocialProvider, String> _issuerDomains = {
    SocialProvider.google: 'accounts.google.com',
    SocialProvider.apple: 'appleid.apple.com',
    SocialProvider.facebook: 'facebook.com',
  };

  SocialTokenValidator({Logger? logger}) : _logger = logger ?? Logger();

  Future<TokenValidationResult> validateSocialToken({
    required SocialProvider provider,
    required String accessToken,
    String? idToken,
    String? state,
    String? codeVerifier,
  }) async {
    try {
      // Basic token format validation
      final formatResult = _validateTokenFormat(accessToken, provider);
      if (!formatResult.isValid) {
        return formatResult;
      }

      // Validate token structure and claims
      final structureResult = await _validateTokenStructure(
        provider,
        accessToken,
        idToken,
      );
      if (!structureResult.isValid) {
        return structureResult;
      }

      // Validate token expiration
      final expiryResult = _validateTokenExpiry(accessToken, idToken);
      if (!expiryResult.isValid) {
        return expiryResult;
      }

      // Validate audience and issuer
      final audienceResult = _validateAudienceAndIssuer(
        provider,
        accessToken,
        idToken,
      );
      if (!audienceResult.isValid) {
        return audienceResult;
      }

      // Validate PKCE if applicable
      if (codeVerifier != null) {
        final pkceResult = await _validatePKCE(accessToken, codeVerifier);
        if (!pkceResult.isValid) {
          return pkceResult;
        }
      }

      // Validate scopes
      final scopeResult = await _validateScopes(provider, accessToken);
      if (!scopeResult.isValid) {
        return scopeResult;
      }

      return TokenValidationResult(
        isValid: true,
        provider: provider,
        validationType: TokenValidationType.comprehensive,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      _logger.e('Token validation error for $provider: $e');
      return TokenValidationResult(
        isValid: false,
        provider: provider,
        error: 'Token validation failed: ${e.toString()}',
        validationType: TokenValidationType.comprehensive,
        timestamp: DateTime.now(),
      );
    }
  }

  TokenValidationResult _validateTokenFormat(
    String accessToken,
    SocialProvider provider,
  ) {
    try {
      if (accessToken.isEmpty) {
        return TokenValidationResult(
          isValid: false,
          provider: provider,
          error: 'Access token is empty',
          validationType: TokenValidationType.format,
          timestamp: DateTime.now(),
        );
      }

      // Basic JWT format check for tokens that should be JWTs
      if (provider == SocialProvider.google ||
          provider == SocialProvider.apple) {
        final parts = accessToken.split('.');
        if (parts.length != 3) {
          return TokenValidationResult(
            isValid: false,
            provider: provider,
            error: 'Invalid JWT format for access token',
            validationType: TokenValidationType.format,
            timestamp: DateTime.now(),
          );
        }
      }

      return TokenValidationResult(
        isValid: true,
        provider: provider,
        validationType: TokenValidationType.format,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TokenValidationResult(
        isValid: false,
        provider: provider,
        error: 'Format validation error: ${e.toString()}',
        validationType: TokenValidationType.format,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<TokenValidationResult> _validateTokenStructure(
    SocialProvider provider,
    String accessToken,
    String? idToken,
  ) async {
    try {
      // Validate ID token if provided
      if (idToken != null && idToken.isNotEmpty) {
        final idTokenParts = idToken.split('.');
        if (idTokenParts.length != 3) {
          return TokenValidationResult(
            isValid: false,
            provider: provider,
            error: 'Invalid ID token format',
            validationType: TokenValidationType.structure,
            timestamp: DateTime.now(),
          );
        }

        // Decode and validate ID token claims
        try {
          final payload = Jwt.parseJwt(idToken);
          if (!payload.containsKey('sub') || !payload.containsKey('aud')) {
            return TokenValidationResult(
              isValid: false,
              provider: provider,
              error: 'ID token missing required claims',
              validationType: TokenValidationType.structure,
              timestamp: DateTime.now(),
            );
          }
        } catch (e) {
          return TokenValidationResult(
            isValid: false,
            provider: provider,
            error: 'Invalid ID token: ${e.toString()}',
            validationType: TokenValidationType.structure,
            timestamp: DateTime.now(),
          );
        }
      }

      return TokenValidationResult(
        isValid: true,
        provider: provider,
        validationType: TokenValidationType.structure,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TokenValidationResult(
        isValid: false,
        provider: provider,
        error: 'Structure validation error: ${e.toString()}',
        validationType: TokenValidationType.structure,
        timestamp: DateTime.now(),
      );
    }
  }

  TokenValidationResult _validateTokenExpiry(
    String accessToken,
    String? idToken,
  ) {
    try {
      // Check ID token expiry if available
      if (idToken != null && idToken.isNotEmpty) {
        try {
          final payload = Jwt.parseJwt(idToken);
          final exp = payload['exp'] as int?;
          if (exp != null) {
            final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
            if (DateTime.now().isAfter(expiryTime)) {
              return TokenValidationResult(
                isValid: false,
                provider:
                    SocialProvider.apple, // Default to apple for ID tokens
                error: 'ID token has expired',
                validationType: TokenValidationType.expiry,
                timestamp: DateTime.now(),
              );
            }
          }
        } catch (e) {
          _logger.w('Could not parse ID token expiry: $e');
        }
      }

      return TokenValidationResult(
        isValid: true,
        provider: SocialProvider.google, // Default provider
        validationType: TokenValidationType.expiry,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TokenValidationResult(
        isValid: false,
        provider: SocialProvider.google,
        error: 'Expiry validation error: ${e.toString()}',
        validationType: TokenValidationType.expiry,
        timestamp: DateTime.now(),
      );
    }
  }

  TokenValidationResult _validateAudienceAndIssuer(
    SocialProvider provider,
    String accessToken,
    String? idToken,
  ) {
    try {
      // Validate ID token audience and issuer
      if (idToken != null && idToken.isNotEmpty) {
        try {
          final payload = Jwt.parseJwt(idToken);
          final aud = payload['aud'] as String?;
          final iss = payload['iss'] as String?;

          if (aud == null || aud.isEmpty) {
            return TokenValidationResult(
              isValid: false,
              provider: provider,
              error: 'ID token missing audience claim',
              validationType: TokenValidationType.audience,
              timestamp: DateTime.now(),
            );
          }

          if (iss == null || iss.isEmpty) {
            return TokenValidationResult(
              isValid: false,
              provider: provider,
              error: 'ID token missing issuer claim',
              validationType: TokenValidationType.issuer,
              timestamp: DateTime.now(),
            );
          }

          // Validate issuer domain
          final expectedDomain = _issuerDomains[provider];
          if (expectedDomain != null && !iss.contains(expectedDomain)) {
            return TokenValidationResult(
              isValid: false,
              provider: provider,
              error: 'Invalid issuer domain: $iss',
              validationType: TokenValidationType.issuer,
              timestamp: DateTime.now(),
            );
          }
        } catch (e) {
          return TokenValidationResult(
            isValid: false,
            provider: provider,
            error: 'Could not validate audience/issuer: ${e.toString()}',
            validationType: TokenValidationType.audience,
            timestamp: DateTime.now(),
          );
        }
      }

      return TokenValidationResult(
        isValid: true,
        provider: provider,
        validationType: TokenValidationType.audience,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TokenValidationResult(
        isValid: false,
        provider: provider,
        error: 'Audience/issuer validation error: ${e.toString()}',
        validationType: TokenValidationType.audience,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<TokenValidationResult> _validatePKCE(
    String accessToken,
    String codeVerifier,
  ) async {
    try {
      // This is a simplified PKCE validation
      // In a real implementation, you would validate the code_challenge
      // against the code_verifier using the same method used during authorization

      if (codeVerifier.isEmpty) {
        return TokenValidationResult(
          isValid: false,
          provider:
              SocialProvider.facebook, // PKCE is commonly used with Facebook
          error: 'Code verifier is empty',
          validationType: TokenValidationType.pkce,
          timestamp: DateTime.now(),
        );
      }

      // Generate expected code challenge
      final bytes = utf8.encode(codeVerifier);
      final digest = sha256.convert(bytes);
      final expectedChallenge = base64Url
          .encode(digest.bytes)
          .replaceAll('=', '');

      return TokenValidationResult(
        isValid: true,
        provider: SocialProvider.facebook,
        validationType: TokenValidationType.pkce,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TokenValidationResult(
        isValid: false,
        provider: SocialProvider.facebook,
        error: 'PKCE validation error: ${e.toString()}',
        validationType: TokenValidationType.pkce,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<TokenValidationResult> _validateScopes(
    SocialProvider provider,
    String accessToken,
  ) async {
    try {
      final requiredScopes = _requiredScopes[provider];
      if (requiredScopes == null) {
        return TokenValidationResult(
          isValid: true,
          provider: provider,
          validationType: TokenValidationType.scopes,
          timestamp: DateTime.now(),
        );
      }

      // This is a simplified scope validation
      // In a real implementation, you would decode the token or call the provider's
      // userinfo endpoint to validate that all required scopes are present

      return TokenValidationResult(
        isValid: true,
        provider: provider,
        validationType: TokenValidationType.scopes,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TokenValidationResult(
        isValid: false,
        provider: provider,
        error: 'Scope validation error: ${e.toString()}',
        validationType: TokenValidationType.scopes,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<bool> isTokenExpired(String token) async {
    try {
      if (token.isEmpty) return true;

      final parts = token.split('.');
      if (parts.length != 3) return true;

      try {
        final payload = Jwt.parseJwt(token);
        final exp = payload['exp'] as int?;

        if (exp != null) {
          final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          return DateTime.now().isAfter(expiryTime);
        }
      } catch (e) {
        _logger.w('Could not parse token expiry: $e');
      }

      return false;
    } catch (e) {
      _logger.e('Error checking token expiry: $e');
      return true;
    }
  }

  String? extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = Jwt.parseJwt(token);
      return payload['sub'] as String?;
    } catch (e) {
      _logger.e('Error extracting user ID from token: $e');
      return null;
    }
  }

  String? extractEmailFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = Jwt.parseJwt(token);
      return payload['email'] as String?;
    } catch (e) {
      _logger.e('Error extracting email from token: $e');
      return null;
    }
  }
}

class TokenValidationResult {
  final bool isValid;
  final SocialProvider provider;
  final String? error;
  final TokenValidationType validationType;
  final DateTime timestamp;

  TokenValidationResult({
    required this.isValid,
    required this.provider,
    this.error,
    required this.validationType,
    required this.timestamp,
  });
}

enum TokenValidationType {
  format,
  structure,
  expiry,
  audience,
  issuer,
  pkce,
  scopes,
  comprehensive,
}
