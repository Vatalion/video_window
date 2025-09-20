import 'package:video_window/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:video_window/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:video_window/features/auth/domain/models/user_model.dart';
import 'package:video_window/features/auth/domain/models/verification_token_model.dart';
import 'package:video_window/features/auth/domain/models/consent_record_model.dart';
import 'package:video_window/features/auth/domain/models/login_attempt_model.dart';
import 'package:video_window/features/auth/domain/models/social_account_model.dart';
import 'package:video_window/features/auth/domain/models/social_auth_result.dart';
import 'package:video_window/features/auth/domain/repositories/auth_repository.dart';
import 'package:video_window/features/auth/data/services/account_lockout_service.dart';
import 'package:video_window/features/auth/data/services/password_service.dart';
import 'package:video_window/features/auth/data/services/coppa_compliance_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final AccountLockoutService lockoutService;
  final PasswordService passwordService;
  final COPPAComplianceService coppaService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    AccountLockoutService? lockoutService,
    PasswordService? passwordService,
    COPPAComplianceService? coppaService,
  }) : lockoutService = lockoutService ?? AccountLockoutService(),
       passwordService = passwordService ?? PasswordService(),
       coppaService = coppaService ?? COPPAComplianceService();

  @override
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required bool ageVerified,
    Map<String, dynamic>? consentData,
  }) async {
    final user = await remoteDataSource.registerWithEmail(
      email: email,
      password: password,
      ageVerified: ageVerified,
      consentData: consentData,
    );

    await localDataSource.cacheUser(user);
    return user;
  }

  @override
  Future<UserModel> registerWithPhone({
    required String phone,
    required String password,
    required bool ageVerified,
    Map<String, dynamic>? consentData,
  }) async {
    final user = await remoteDataSource.registerWithPhone(
      phone: phone,
      password: password,
      ageVerified: ageVerified,
      consentData: consentData,
    );

    await localDataSource.cacheUser(user);
    return user;
  }

  @override
  Future<VerificationTokenModel> sendEmailVerification(String userId) async {
    return await remoteDataSource.sendEmailVerification(userId);
  }

  @override
  Future<VerificationTokenModel> sendPhoneVerification(String userId) async {
    return await remoteDataSource.sendPhoneVerification(userId);
  }

  @override
  Future<bool> verifyEmail(String userId, String token) async {
    final isVerified = await remoteDataSource.verifyEmail(userId, token);
    if (isVerified) {
      final user = await localDataSource.getCachedUser();
      if (user != null && user.id == userId) {
        final updatedUser = user.copyWith(
          verificationStatus: VerificationStatus.emailVerified,
        );
        await localDataSource.cacheUser(updatedUser);
      }
    }
    return isVerified;
  }

  @override
  Future<bool> verifyPhone(String userId, String token) async {
    final isVerified = await remoteDataSource.verifyPhone(userId, token);
    if (isVerified) {
      final user = await localDataSource.getCachedUser();
      if (user != null && user.id == userId) {
        final updatedUser = user.copyWith(
          verificationStatus: VerificationStatus.phoneVerified,
        );
        await localDataSource.cacheUser(updatedUser);
      }
    }
    return isVerified;
  }

  @override
  Future<VerificationTokenModel> resendVerification(
    String userId,
    TokenType tokenType,
  ) async {
    return await remoteDataSource.resendVerification(userId, tokenType);
  }

  @override
  Future<ConsentRecordModel> recordConsent({
    required String userId,
    required ConsentType consentType,
    required String ipAddress,
    String? userAgent,
    Map<String, dynamic>? consentData,
  }) async {
    return await remoteDataSource.recordConsent(
      userId: userId,
      consentType: consentType,
      ipAddress: ipAddress,
      userAgent: userAgent,
      consentData: consentData,
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return await localDataSource.getCachedUser();
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearCachedUser();
  }

  @override
  Future<void> saveProgressiveProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    await localDataSource.saveProgressiveProfile(userId, profileData);
  }

  @override
  Future<Map<String, dynamic>?> getProgressiveProfile(String userId) async {
    return await localDataSource.getProgressiveProfile(userId);
  }

  @override
  Future<bool> isAccountLocked(String identifier) async {
    return lockoutService.isAccountLocked(identifier);
  }

  @override
  Future<DateTime?> getLockoutEndTime(String identifier) async {
    return lockoutService.getLockoutEndTime(identifier);
  }

  @override
  Future<int> getRemainingFailedAttempts(String identifier) async {
    return lockoutService.getRemainingFailedAttempts(identifier);
  }

  @override
  Future<void> recordLoginAttempt({
    required String? email,
    required String? phone,
    required String ipAddress,
    required String userAgent,
    required bool wasSuccessful,
    String? failureReason,
    String? userId,
  }) async {
    await lockoutService.recordLoginAttempt(
      email: email,
      phone: phone,
      ipAddress: ipAddress,
      userAgent: userAgent,
      wasSuccessful: wasSuccessful,
      failureReason: failureReason,
      userId: userId,
    );
  }

  @override
  Future<void> unlockAccount(String identifier) async {
    await lockoutService.unlockAccount(identifier);
  }

  @override
  Future<Map<String, dynamic>> getAccountStatus(String identifier) async {
    return lockoutService.getAccountStatus(identifier);
  }

  @override
  String hashPassword(String password) {
    return passwordService.hashPassword(password);
  }

  @override
  bool verifyPassword(String password, String storedHash) {
    return passwordService.verifyPassword(password, storedHash);
  }

  @override
  PasswordStrength validatePasswordStrength(String password) {
    return passwordService.validatePasswordStrength(password);
  }

  @override
  String generateSecurePassword({int length = 16}) {
    return passwordService.generateSecurePassword(length: length);
  }

  @override
  COPPAResult validateAgeVerification({
    required DateTime birthDate,
    required String ipAddress,
    required String userAgent,
    String? parentalEmail,
    String? parentId,
    Map<String, dynamic>? consentData,
  }) {
    return coppaService.validateAgeVerification(
      birthDate: birthDate,
      ipAddress: ipAddress,
      userAgent: userAgent,
      parentalEmail: parentalEmail,
      parentId: parentId,
      consentData: consentData,
    );
  }

  @override
  Future<COPPAResult> validateUserCompliance({
    required String userId,
    required DateTime birthDate,
    required String ipAddress,
    required String userAgent,
    String? parentalEmail,
    String? parentId,
    Map<String, dynamic>? consentData,
  }) async {
    return await coppaService.validateUserCompliance(
      userId: userId,
      birthDate: birthDate,
      ipAddress: ipAddress,
      userAgent: userAgent,
      parentalEmail: parentalEmail,
      parentId: parentId,
      consentData: consentData,
    );
  }

  @override
  Future<ParentalConsentRecord> recordParentalConsent({
    required String userId,
    required String childUserId,
    required String parentalEmail,
    required String parentId,
    required ConsentMethod consentMethod,
    required String ipAddress,
    required String userAgent,
    Map<String, dynamic>? consentData,
  }) async {
    return await coppaService.recordParentalConsent(
      userId: userId,
      childUserId: childUserId,
      parentalEmail: parentalEmail,
      parentId: parentId,
      consentMethod: consentMethod,
      ipAddress: ipAddress,
      userAgent: userAgent,
      consentData: consentData,
    );
  }

  @override
  Future<bool> isParentalConsentValid(String userId) async {
    return await coppaService.isParentalConsentValid(userId);
  }

  @override
  AgeVerificationRequest generateAgeVerificationRequest({
    required String userId,
    required String email,
    String? ipAddress,
    String? userAgent,
  }) {
    return coppaService.generateAgeVerificationRequest(
      userId: userId,
      email: email,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
  }

  @override
  COPPAResult validateAgeVerificationResponse({
    required String verificationToken,
    required DateTime birthDate,
    required String ipAddress,
    required String userAgent,
  }) {
    return coppaService.validateAgeVerificationResponse(
      verificationToken: verificationToken,
      birthDate: birthDate,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
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
      // Call backend API to authenticate with social provider
      final result = await remoteDataSource.authenticateWithSocialProvider(
        provider: provider,
        accessToken: accessToken,
        idToken: idToken,
        state: state,
        codeVerifier: codeVerifier,
      );

      if (result.user != null) {
        await localDataSource.cacheUser(result.user!);
      }

      return result;
    } catch (e) {
      return SocialAuthResult.error(
        errorMessage: 'Social authentication failed: ${e.toString()}',
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
      return await remoteDataSource.linkSocialAccount(
        userId: userId,
        provider: provider,
        providerId: providerId,
        accessToken: accessToken,
        email: email,
        profilePicture: profilePicture,
      );
    } catch (e) {
      throw SocialAuthException(
        'Failed to link social account: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> unlinkSocialAccount({
    required String userId,
    required String socialAccountId,
  }) async {
    try {
      return await remoteDataSource.unlinkSocialAccount(
        userId: userId,
        socialAccountId: socialAccountId,
      );
    } catch (e) {
      throw SocialAuthException(
        'Failed to unlink social account: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<SocialAccountModel>> getLinkedSocialAccounts(
    String userId,
  ) async {
    try {
      return await remoteDataSource.getLinkedSocialAccounts(userId);
    } catch (e) {
      throw SocialAuthException(
        'Failed to get linked social accounts: ${e.toString()}',
      );
    }
  }

  @override
  Future<SocialAccountModel?> getSocialAccountByProvider({
    required String userId,
    required SocialProvider provider,
  }) async {
    try {
      return await remoteDataSource.getSocialAccountByProvider(
        userId: userId,
        provider: provider,
      );
    } catch (e) {
      throw SocialAuthException(
        'Failed to get social account by provider: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> updateSocialAccountToken({
    required String socialAccountId,
    required String accessToken,
    DateTime? expiryDate,
  }) async {
    try {
      await remoteDataSource.updateSocialAccountToken(
        socialAccountId: socialAccountId,
        accessToken: accessToken,
        expiryDate: expiryDate,
      );
    } catch (e) {
      throw SocialAuthException(
        'Failed to update social account token: ${e.toString()}',
      );
    }
  }
}

class SocialAuthException implements Exception {
  final String message;

  SocialAuthException(this.message);

  @override
  String toString() => 'SocialAuthException: $message';
}
