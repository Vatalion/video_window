import 'package:video_window/features/auth/domain/models/user_model.dart';
import 'package:video_window/features/auth/domain/models/verification_token_model.dart';
import 'package:video_window/features/auth/domain/models/consent_record_model.dart';
import 'package:video_window/features/auth/domain/models/social_account_model.dart';
import 'package:video_window/features/auth/domain/models/social_auth_result.dart';
import 'package:video_window/features/auth/domain/models/two_factor_config_model.dart';
import 'package:video_window/features/auth/domain/models/two_factor_audit_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required bool ageVerified,
    Map<String, dynamic>? consentData,
  });

  Future<UserModel> registerWithPhone({
    required String phone,
    required String password,
    required bool ageVerified,
    Map<String, dynamic>? consentData,
  });

  Future<bool> verifyEmail(String userId, String token);
  Future<bool> verifyPhone(String userId, String token);
  Future<VerificationTokenModel> sendEmailVerification(String userId);
  Future<VerificationTokenModel> sendPhoneVerification(String userId);
  Future<VerificationTokenModel> resendVerification(
    String userId,
    TokenType tokenType,
  );
  Future<ConsentRecordModel> recordConsent({
    required String userId,
    required ConsentType consentType,
    required String ipAddress,
    String? userAgent,
    Map<String, dynamic>? consentData,
  });
  Future<SocialAuthResult> authenticateWithSocialProvider({
    required SocialProvider provider,
    required String accessToken,
    required String idToken,
    String? state,
    String? codeVerifier,
  });
  Future<SocialAccountModel> linkSocialAccount({
    required String userId,
    required SocialProvider provider,
    required String providerId,
    required String accessToken,
    String? email,
    String? profilePicture,
  });
  Future<bool> unlinkSocialAccount({
    required String userId,
    required String socialAccountId,
  });
  Future<List<SocialAccountModel>> getLinkedSocialAccounts(String userId);
  Future<SocialAccountModel?> getSocialAccountByProvider({
    required String userId,
    required SocialProvider provider,
  });
  Future<void> updateSocialAccountToken({
    required String socialAccountId,
    required String accessToken,
    DateTime? expiryDate,
  });

  // Two-Factor Authentication Methods
  Future<TwoFactorConfig> getTwoFactorConfig(String userId);
  Future<TwoFactorConfig> updateTwoFactorConfig(TwoFactorConfig config);
  Future<void> disableTwoFactor(String userId);
  Future<List<TwoFactorAudit>> getTwoFactorAuditLog(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    TwoFactorAuditAction? action,
  });
  Future<void> logTwoFactorAuditEvent(TwoFactorAudit audit);
  Future<void> lockTwoFactorAccount(String userId, String reason);
  Future<void> unlockTwoFactorAccount(String userId);
}
