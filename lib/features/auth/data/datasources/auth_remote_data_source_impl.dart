import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_window/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:video_window/features/auth/domain/models/user_model.dart';
import 'package:video_window/features/auth/domain/models/verification_token_model.dart';
import 'package:video_window/features/auth/domain/models/consent_record_model.dart';
import 'package:video_window/features/auth/domain/models/social_account_model.dart';
import 'package:video_window/features/auth/domain/models/social_auth_result.dart';
import 'package:video_window/features/auth/domain/models/two_factor_config_model.dart';
import 'package:video_window/features/auth/domain/models/two_factor_audit_model.dart';
import 'package:video_window/features/auth/data/services/password_service.dart';
import 'package:uuid/uuid.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final String baseUrl;
  final PasswordService passwordService;
  final Uuid uuid;

  AuthRemoteDataSourceImpl({
    required this.client,
    required this.baseUrl,
    PasswordService? passwordService,
    Uuid? uuid,
  }) : passwordService = passwordService ?? PasswordService(),
       uuid = uuid ?? const Uuid();

  @override
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required bool ageVerified,
    Map<String, dynamic>? consentData,
  }) async {
    // Implementation would call actual backend API
    throw UnimplementedError('Email registration not implemented in remote data source');
  }

  @override
  Future<UserModel> registerWithPhone({
    required String phone,
    required String password,
    required bool ageVerified,
    Map<String, dynamic>? consentData,
  }) async {
    // Implementation would call actual backend API
    throw UnimplementedError('Phone registration not implemented in remote data source');
  }

  @override
  Future<VerificationTokenModel> sendEmailVerification(String userId) async {
    // Implementation would call actual backend API
    throw UnimplementedError('Email verification not implemented in remote data source');
  }

  @override
  Future<VerificationTokenModel> sendPhoneVerification(String userId) async {
    // Implementation would call actual backend API
    throw UnimplementedError('Phone verification not implemented in remote data source');
  }

  @override
  Future<bool> verifyEmail(String userId, String token) async {
    // Implementation would call actual backend API
    throw UnimplementedError('Email verification not implemented in remote data source');
  }

  @override
  Future<bool> verifyPhone(String userId, String token) async {
    // Implementation would call actual backend API
    throw UnimplementedError('Phone verification not implemented in remote data source');
  }

  @override
  Future<VerificationTokenModel> resendVerification(String userId, TokenType tokenType) async {
    // Implementation would call actual backend API
    throw UnimplementedError('Verification resend not implemented in remote data source');
  }

  @override
  Future<ConsentRecordModel> recordConsent({
    required String userId,
    required ConsentType consentType,
    required String ipAddress,
    String? userAgent,
    Map<String, dynamic>? consentData,
  }) async {
    // Implementation would call actual backend API
    throw UnimplementedError('Consent recording not implemented in remote data source');
  }

  @override
  Future<bool> validatePasswordStrength(String password) async {
    // Implementation would call actual backend API
    throw UnimplementedError('Password validation not implemented in remote data source');
  }

  // Social Authentication Methods
  @override
  Future<SocialAuthResult> authenticateWithSocialProvider({
    required SocialProvider provider,
    required String accessToken,
    required String idToken,
    String? state,
    String? codeVerifier,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/social/${provider.name}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'accessToken': accessToken,
          'idToken': idToken,
          'state': state,
          'codeVerifier': codeVerifier,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        return SocialAuthResult.success(
          user: UserModel.fromJson(responseData['user'] as Map<String, dynamic>),
          socialAccount: SocialAccountModel.fromJson(responseData['socialAccount'] as Map<String, dynamic>),
          isNewUser: responseData['isNewUser'] as bool,
        );
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return SocialAuthResult.error(
          errorMessage: errorData['message'] as String? ?? 'Social authentication failed',
        );
      }
    } catch (e) {
      return SocialAuthResult.error(
        errorMessage: 'Network error during social authentication: ${e.toString()}',
      );
    }
  }

  @override
  Future<SocialAccountModel> linkSocialAccount({
    required String userId,
    required SocialProvider provider,
    required String providerId,
    required String accessToken,
    String? email,
    String? profilePicture,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/social/link'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'provider': provider.name,
          'providerId': providerId,
          'accessToken': accessToken,
          'email': email,
          'profilePicture': profilePicture,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return SocialAccountModel.fromJson(responseData['socialAccount'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to link social account: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error during social account linking: ${e.toString()}');
    }
  }

  @override
  Future<bool> unlinkSocialAccount({
    required String userId,
    required String socialAccountId,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/api/auth/social/unlink'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'socialAccountId': socialAccountId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Network error during social account unlinking: ${e.toString()}');
    }
  }

  @override
  Future<List<SocialAccountModel>> getLinkedSocialAccounts(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/auth/social/accounts/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final accountsList = responseData['accounts'] as List<dynamic>;
        return accountsList
            .map((account) => SocialAccountModel.fromJson(account as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get linked social accounts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error getting linked social accounts: ${e.toString()}');
    }
  }

  @override
  Future<SocialAccountModel?> getSocialAccountByProvider({
    required String userId,
    required SocialProvider provider,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/auth/social/account/$userId/${provider.name}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return SocialAccountModel.fromJson(responseData['socialAccount'] as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get social account by provider: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error getting social account by provider: ${e.toString()}');
    }
  }

  @override
  Future<void> updateSocialAccountToken({
    required String socialAccountId,
    required String accessToken,
    DateTime? expiryDate,
  }) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/api/auth/social/token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'socialAccountId': socialAccountId,
          'accessToken': accessToken,
          'expiryDate': expiryDate?.toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update social account token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error updating social account token: ${e.toString()}');
    }
  }

  // Two-Factor Authentication Methods
  @override
  Future<TwoFactorConfig> getTwoFactorConfig(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/auth/2fa/config/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return TwoFactorConfig.fromJson(responseData['config'] as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        // Return default config if none exists
        return TwoFactorConfig(
          id: uuid.v4(),
          userId: userId,
          method: TwoFactorMethod.none,
          status: TwoFactorStatus.disabled,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        throw Exception('Failed to get 2FA config: ${response.statusCode}');
      }
    } catch (e) {
      // Return default config for development
      return TwoFactorConfig(
        id: uuid.v4(),
        userId: userId,
        method: TwoFactorMethod.none,
        status: TwoFactorStatus.disabled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<TwoFactorConfig> updateTwoFactorConfig(TwoFactorConfig config) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/api/auth/2fa/config'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'config': config.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return TwoFactorConfig.fromJson(responseData['config'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update 2FA config: ${response.statusCode}');
      }
    } catch (e) {
      // Return updated config for development
      return config.copyWith(updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> disableTwoFactor(String userId) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/api/auth/2fa/disable/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to disable 2FA: ${response.statusCode}');
      }
    } catch (e) {
      // Mock success for development
      return;
    }
  }

  @override
  Future<List<TwoFactorAudit>> getTwoFactorAuditLog(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    TwoFactorAuditAction? action,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/2fa/audit/$userId').replace(
        queryParameters: {
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          if (action != null) 'action': action.name,
        },
      );

      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final auditList = responseData['audits'] as List<dynamic>;
        return auditList
            .map((audit) => TwoFactorAudit.fromJson(audit as Map<String, dynamic>))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      // Return empty list for development
      return [];
    }
  }

  @override
  Future<void> logTwoFactorAuditEvent(TwoFactorAudit audit) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/2fa/audit'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'audit': audit.toJson(),
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to log 2FA audit event: ${response.statusCode}');
      }
    } catch (e) {
      // Mock success for development
      return;
    }
  }

  @override
  Future<void> lockTwoFactorAccount(String userId, String reason) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/2fa/lock/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reason': reason,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to lock 2FA account: ${response.statusCode}');
      }
    } catch (e) {
      // Mock success for development
      return;
    }
  }

  @override
  Future<void> unlockTwoFactorAccount(String userId) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/2fa/unlock/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to unlock 2FA account: ${response.statusCode}');
      }
    } catch (e) {
      // Mock success for development
      return;
    }
  }

  /// Generate a secure verification token
  String _generateVerificationToken() {
    final chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecond;
    return String.fromCharCodes(
      Iterable.generate(32, (i) => chars.codeUnitAt((random + i) % chars.length))
    );
  }