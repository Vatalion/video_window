part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class RegisterWithEmailEvent extends AuthEvent {
  final String email;
  final String password;
  final bool ageVerified;
  final Map<String, dynamic>? consentData;

  const RegisterWithEmailEvent({
    required this.email,
    required this.password,
    required this.ageVerified,
    this.consentData,
  });

  @override
  List<Object> get props => [email, password, ageVerified];
}

class RegisterWithPhoneEvent extends AuthEvent {
  final String phone;
  final String password;
  final bool ageVerified;
  final Map<String, dynamic>? consentData;

  const RegisterWithPhoneEvent({
    required this.phone,
    required this.password,
    required this.ageVerified,
    this.consentData,
  });

  @override
  List<Object> get props => [phone, password, ageVerified];
}

class SendEmailVerificationEvent extends AuthEvent {
  final String userId;

  const SendEmailVerificationEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class SendPhoneVerificationEvent extends AuthEvent {
  final String userId;

  const SendPhoneVerificationEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class VerifyEmailEvent extends AuthEvent {
  final String userId;
  final String token;

  const VerifyEmailEvent({required this.userId, required this.token});

  @override
  List<Object> get props => [userId, token];
}

class VerifyPhoneEvent extends AuthEvent {
  final String userId;
  final String token;

  const VerifyPhoneEvent({required this.userId, required this.token});

  @override
  List<Object> get props => [userId, token];
}

class ResendVerificationEvent extends AuthEvent {
  final String userId;
  final TokenType tokenType;

  const ResendVerificationEvent({
    required this.userId,
    required this.tokenType,
  });

  @override
  List<Object> get props => [userId, tokenType];
}

class SaveProgressiveProfileEvent extends AuthEvent {
  final String userId;
  final Map<String, dynamic> profileData;

  const SaveProgressiveProfileEvent({
    required this.userId,
    required this.profileData,
  });

  @override
  List<Object> get props => [userId, profileData];
}

class GetProgressiveProfileEvent extends AuthEvent {
  final String userId;

  const GetProgressiveProfileEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class GetCurrentUserEvent extends AuthEvent {
  const GetCurrentUserEvent();
}

class SocialSignInEvent extends AuthEvent {
  final SocialProvider provider;

  const SocialSignInEvent({required this.provider});

  @override
  List<Object> get props => [provider];
}

class LinkSocialAccountEvent extends AuthEvent {
  final SocialProvider provider;
  final String userId;
  final String? providerId;
  final String? accessToken;
  final String? email;
  final String? profilePicture;

  const LinkSocialAccountEvent({
    required this.provider,
    required this.userId,
    this.providerId,
    this.accessToken,
    this.email,
    this.profilePicture,
  });

  @override
  List<Object> get props => [
    provider,
    userId,
    providerId ?? '',
    accessToken ?? '',
    email ?? '',
    profilePicture ?? '',
  ];
}

class UnlinkSocialAccountEvent extends AuthEvent {
  final String socialAccountId;
  final String userId;

  const UnlinkSocialAccountEvent({
    required this.socialAccountId,
    required this.userId,
  });

  @override
  List<Object> get props => [socialAccountId, userId];
}

class GetLinkedSocialAccountsEvent extends AuthEvent {
  final String userId;

  const GetLinkedSocialAccountsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class CheckAccountLockStatusEvent extends AuthEvent {
  final String identifier;

  const CheckAccountLockStatusEvent({required this.identifier});

  @override
  List<Object> get props => [identifier];
}

class UnlockAccountEvent extends AuthEvent {
  final String identifier;

  const UnlockAccountEvent({required this.identifier});

  @override
  List<Object> get props => [identifier];
}

// Recovery Events
class RequestPasswordReset extends AuthEvent {
  final String email;

  const RequestPasswordReset({required this.email});

  @override
  List<Object> get props => [email];
}

class RequestPhoneRecovery extends AuthEvent {
  final String phoneNumber;

  const RequestPhoneRecovery({required this.phoneNumber});

  @override
  List<Object> get props => [phoneNumber];
}

class VerifyRecoveryCode extends AuthEvent {
  final String code;
  final String? phoneNumber;
  final String? userId;
  final String? token;

  const VerifyRecoveryCode({
    required this.code,
    this.phoneNumber,
    this.userId,
    this.token,
  });

  @override
  List<Object> get props => [
    code,
    phoneNumber ?? '',
    userId ?? '',
    token ?? '',
  ];
}

class ResetPassword extends AuthEvent {
  final String token;
  final String newPassword;
  final String? userId;
  final String? code;

  const ResetPassword({
    required this.token,
    required this.newPassword,
    this.userId,
    this.code,
  });

  @override
  List<Object> get props => [token, newPassword, userId ?? '', code ?? ''];
}

class SetupSecurityQuestions extends AuthEvent {
  final String userId;
  final List<Map<String, String>> questions;

  const SetupSecurityQuestions({required this.userId, required this.questions});

  @override
  List<Object> get props => [userId, questions];
}

class VerifySecurityAnswers extends AuthEvent {
  final String userId;
  final List<Map<String, String>> answers;

  const VerifySecurityAnswers({required this.userId, required this.answers});

  @override
  List<Object> get props => [userId, answers];
}

class GetRecoveryOptions extends AuthEvent {
  final String email;

  const GetRecoveryOptions({required this.email});

  @override
  List<Object> get props => [email];
}

// Biometric Authentication Events
class CheckBiometricCapabilityEvent extends AuthEvent {
  const CheckBiometricCapabilityEvent();
}

class SetupBiometricAuthEvent extends AuthEvent {
  const SetupBiometricAuthEvent();
}

class BiometricLoginEvent extends AuthEvent {
  const BiometricLoginEvent();
}

class ToggleBiometricAuthEvent extends AuthEvent {
  final bool enable;

  const ToggleBiometricAuthEvent({required this.enable});

  @override
  List<Object> get props => [enable];
}

class GetBiometricPreferencesEvent extends AuthEvent {
  const GetBiometricPreferencesEvent();
}
