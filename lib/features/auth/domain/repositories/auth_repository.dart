import 'package:video_window/features/auth/domain/models/user_model.dart';
import 'package:video_window/features/auth/domain/models/verification_token_model.dart';
import 'package:video_window/features/auth/domain/models/consent_record_model.dart';
import 'package:video_window/features/auth/domain/models/login_attempt_model.dart';
import 'package:video_window/features/auth/domain/models/social_account_model.dart';
import 'package:video_window/features/auth/domain/models/social_auth_result.dart';
import 'package:video_window/features/auth/data/services/password_service.dart';
import 'package:video_window/features/auth/data/services/coppa_compliance_service.dart';

abstract class AuthRepository {
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

  Future<VerificationTokenModel> sendEmailVerification(String userId);
  Future<VerificationTokenModel> sendPhoneVerification(String userId);
  Future<bool> verifyEmail(String userId, String token);
  Future<bool> verifyPhone(String userId, String token);
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
  Future<UserModel?> getCurrentUser();
  Future<void> logout();
  Future<void> saveProgressiveProfile(
    String userId,
    Map<String, dynamic> profileData,
  );
  Future<Map<String, dynamic>?> getProgressiveProfile(String userId);

  // Account lockout methods
  Future<bool> isAccountLocked(String identifier);
  Future<DateTime?> getLockoutEndTime(String identifier);
  Future<int> getRemainingFailedAttempts(String identifier);
  Future<void> recordLoginAttempt({
    required String? email,
    required String? phone,
    required String ipAddress,
    required String userAgent,
    required bool wasSuccessful,
    String? failureReason,
    String? userId,
  });
  Future<void> unlockAccount(String identifier);
  Future<Map<String, dynamic>> getAccountStatus(String identifier);

  // Password hashing methods
  String hashPassword(String password);
  bool verifyPassword(String password, String storedHash);
  PasswordStrength validatePasswordStrength(String password);
  String generateSecurePassword({int length});

  // COPPA compliance methods
  COPPAResult validateAgeVerification({
    required DateTime birthDate,
    required String ipAddress,
    required String userAgent,
    String? parentalEmail,
    String? parentId,
    Map<String, dynamic>? consentData,
  });
  Future<COPPAResult> validateUserCompliance({
    required String userId,
    required DateTime birthDate,
    required String ipAddress,
    required String userAgent,
    String? parentalEmail,
    String? parentId,
    Map<String, dynamic>? consentData,
  });
  Future<ParentalConsentRecord> recordParentalConsent({
    required String userId,
    required String childUserId,
    required String parentalEmail,
    required String parentId,
    required ConsentMethod consentMethod,
    required String ipAddress,
    required String userAgent,
    Map<String, dynamic>? consentData,
  });
  Future<bool> isParentalConsentValid(String userId);
  AgeVerificationRequest generateAgeVerificationRequest({
    required String userId,
    required String email,
    String? ipAddress,
    String? userAgent,
  });
  COPPAResult validateAgeVerificationResponse({
    required String verificationToken,
    required DateTime birthDate,
    required String ipAddress,
    required String userAgent,
  });

  // Social Authentication Methods
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
}
