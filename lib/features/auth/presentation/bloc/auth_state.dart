part of 'auth_bloc.dart';

class RecoveryOption {
  final String id;
  final String type;
  final String label;
  final String description;
  final bool isEnabled;

  const RecoveryOption({
    required this.id,
    required this.type,
    required this.label,
    required this.description,
    this.isEnabled = true,
  });
}

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitialState extends AuthState {
  const AuthInitialState();
}

class AuthLoadingState extends AuthState {
  const AuthLoadingState();
}

class AuthenticatedState extends AuthState {
  final UserModel user;

  const AuthenticatedState({required this.user});

  @override
  List<Object> get props => [user];
}

class UnauthenticatedState extends AuthState {
  const UnauthenticatedState();
}

class AuthErrorState extends AuthState {
  final String message;

  const AuthErrorState({required this.message});

  @override
  List<Object> get props => [message];
}

class EmailVerificationSentState extends AuthState {
  final VerificationTokenModel token;

  const EmailVerificationSentState({required this.token});

  @override
  List<Object> get props => [token];
}

class PhoneVerificationSentState extends AuthState {
  final VerificationTokenModel token;

  const PhoneVerificationSentState({required this.token});

  @override
  List<Object> get props => [token];
}

class ProfileSavedState extends AuthState {
  const ProfileSavedState();
}

class ProfileLoadedState extends AuthState {
  final Map<String, dynamic>? profile;

  const ProfileLoadedState({this.profile});

  @override
  List<Object> get props => [profile ?? {}];
}

class SocialAuthLoadingState extends AuthState {
  const SocialAuthLoadingState();
}

class SocialAuthSuccessState extends AuthState {
  final UserModel user;
  final SocialAccountModel socialAccount;
  final bool isNewUser;

  const SocialAuthSuccessState({
    required this.user,
    required this.socialAccount,
    required this.isNewUser,
  });

  @override
  List<Object> get props => [user, socialAccount, isNewUser];
}

class SocialAuthErrorState extends AuthState {
  final String message;
  final SocialProvider provider;

  const SocialAuthErrorState({required this.message, required this.provider});

  @override
  List<Object> get props => [message, provider];
}

class SocialAccountsLoadedState extends AuthState {
  final List<SocialAccountModel> accounts;

  const SocialAccountsLoadedState({required this.accounts});

  @override
  List<Object> get props => [accounts];
}

class SocialAccountLinkedState extends AuthState {
  final SocialAccountModel account;

  const SocialAccountLinkedState({required this.account});

  @override
  List<Object> get props => [account];
}

class SocialAccountUnlinkedState extends AuthState {
  final String socialAccountId;

  const SocialAccountUnlinkedState({required this.socialAccountId});

  @override
  List<Object> get props => [socialAccountId];
}

// Recovery States
class PasswordResetSuccess extends AuthState {
  final String email;
  final String message;

  const PasswordResetSuccess({
    required this.email,
    this.message = 'Password reset link sent successfully',
  });

  @override
  List<Object> get props => [email, message];
}

class PhoneRecoverySuccess extends AuthState {
  final String phoneNumber;
  final String message;

  const PhoneRecoverySuccess({
    required this.phoneNumber,
    this.message = 'Verification code sent successfully',
  });

  @override
  List<Object> get props => [phoneNumber, message];
}

class RecoveryCodeVerified extends AuthState {
  final String userId;
  final RecoveryTokenType type;

  const RecoveryCodeVerified({required this.userId, required this.type});

  @override
  List<Object> get props => [userId, type];
}

class PasswordResetComplete extends AuthState {
  final String message;

  const PasswordResetComplete({this.message = 'Password reset successfully'});

  @override
  List<Object> get props => [message];
}

class SecurityQuestionsSetup extends AuthState {
  final String userId;

  const SecurityQuestionsSetup({required this.userId});

  @override
  List<Object> get props => [userId];
}

class SecurityAnswersVerified extends AuthState {
  final String userId;

  const SecurityAnswersVerified({required this.userId});

  @override
  List<Object> get props => [userId];
}

class RecoveryOptionsLoaded extends AuthState {
  final List<RecoveryOption> options;

  const RecoveryOptionsLoaded({required this.options});

  @override
  List<Object> get props => [options];
}

class AccountLockedState extends AuthState {
  final String reason;
  final DateTime? lockedUntil;

  const AccountLockedState({required this.reason, this.lockedUntil});

  @override
  List<Object> get props => [reason, lockedUntil ?? ''];
}

class RecoveryAttemptFailed extends AuthState {
  final String reason;
  final int remainingAttempts;

  const RecoveryAttemptFailed({
    required this.reason,
    required this.remainingAttempts,
  });

  @override
  List<Object> get props => [reason, remainingAttempts];
}

class RecoveryOptions {
  final bool emailEnabled;
  final bool phoneEnabled;
  final bool securityQuestionsEnabled;
  final bool backupMethodsEnabled;

  const RecoveryOptions({
    this.emailEnabled = true,
    this.phoneEnabled = true,
    this.securityQuestionsEnabled = true,
    this.backupMethodsEnabled = true,
  });
}

// Biometric Authentication States
class BiometricCapabilityChecked extends AuthState {
  final bool isAvailable;
  final String biometricType;
  final String? errorMessage;

  const BiometricCapabilityChecked({
    required this.isAvailable,
    required this.biometricType,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [isAvailable, biometricType, errorMessage];
}

class BiometricAuthSetupComplete extends AuthState {
  final bool success;
  final String? errorMessage;

  const BiometricAuthSetupComplete({required this.success, this.errorMessage});

  @override
  List<Object?> get props => [success, errorMessage];
}

class BiometricAuthSuccess extends AuthState {
  final String biometricType;
  final DateTime authenticatedAt;

  const BiometricAuthSuccess({
    required this.biometricType,
    required this.authenticatedAt,
  });

  @override
  List<Object> get props => [biometricType, authenticatedAt];
}

class BiometricAuthFailed extends AuthState {
  final String reason;
  final int remainingAttempts;

  const BiometricAuthFailed({
    required this.reason,
    required this.remainingAttempts,
  });

  @override
  List<Object> get props => [reason, remainingAttempts];
}

class BiometricPreferencesLoaded extends AuthState {
  final bool isEnabled;
  final String biometricType;
  final DateTime? lastUsed;
  final bool isLockedOut;

  const BiometricPreferencesLoaded({
    required this.isEnabled,
    required this.biometricType,
    this.lastUsed,
    required this.isLockedOut,
  });

  @override
  List<Object?> get props => [isEnabled, biometricType, lastUsed, isLockedOut];
}
