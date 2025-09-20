import 'package:equatable/equatable.dart';

enum SocialProvider {
  google,
  apple,
  facebook,
}

enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong,
}

enum TokenType {
  email,
  phone,
}

enum ConsentType {
  ageVerification,
  termsOfService,
  privacyPolicy,
  marketing,
  dataProcessing,
}

enum VerificationStatus {
  pending,
  emailVerified,
  phoneVerified,
  fullyVerified,
}

enum SocialAuthResultType {
  success,
  error,
  cancelled,
  accountExists,
}

enum ConsentMethod {
  emailVerification,
  documentUpload,
  idVerification,
  parentalAccount,
  thirdPartyService,
}

enum AgeVerificationStatus {
  pending,
  verified,
  expired,
  failed,
}

enum RecoveryTokenType {
  email,
  phone,
  securityQuestion,
  backupCode,
}

enum BiometricType {
  fingerprint,
  face,
  iris,
  voice,
}

enum TwoFactorType {
  sms,
  totp,
  email,
  backupCodes,
}

extension RecoveryTokenTypeExtension on RecoveryTokenType {
  String get displayName {
    switch (this) {
      case RecoveryTokenType.email:
        return 'Email';
      case RecoveryTokenType.phone:
        return 'Phone';
      case RecoveryTokenType.securityQuestion:
        return 'Security Question';
      case RecoveryTokenType.backupCodes:
        return 'Backup Codes';
    }
  }
}

extension BiometricTypeExtension on BiometricType {
  String get displayName {
    switch (this) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.voice:
        return 'Voice Recognition';
    }
  }
}

extension TwoFactorTypeExtension on TwoFactorType {
  String get displayName {
    switch (this) {
      case TwoFactorType.sms:
        return 'SMS';
      case TwoFactorType.totp:
        return 'Authenticator App';
      case TwoFactorType.email:
        return 'Email';
      case TwoFactorType.backupCodes:
        return 'Backup Codes';
    }
  }
}