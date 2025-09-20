import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:video_window/features/auth/domain/models/user_model.dart';
import 'package:video_window/features/auth/domain/models/verification_token_model.dart';
import 'package:video_window/features/auth/domain/models/consent_record_model.dart';
import 'package:video_window/features/auth/domain/models/social_account_model.dart';
import 'package:video_window/features/auth/domain/models/social_auth_result.dart';
import 'package:video_window/features/auth/domain/models/recovery_token_model.dart';
import 'package:video_window/features/auth/domain/models/biometric_models.dart';
import 'package:video_window/features/auth/domain/repositories/auth_repository.dart';
import 'package:video_window/features/auth/data/services/google_auth_service.dart';
import 'package:video_window/features/auth/data/services/apple_auth_service.dart';
import 'package:video_window/features/auth/data/services/facebook_auth_service.dart';
import 'package:video_window/features/auth/data/services/social_auth_manager.dart';
import 'package:video_window/features/auth/data/services/secure_token_storage.dart';
import 'package:video_window/features/auth/data/services/biometric_auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final SocialAuthManager socialAuthManager;
  final BiometricAuthService biometricAuthService;
  final Logger _logger;

  AuthBloc({
    required this.authRepository,
    required this.socialAuthManager,
    required this.biometricAuthService,
    Logger? logger,
  }) : _logger = logger ?? Logger(),
       super(const AuthInitialState()) {
    on<RegisterWithEmailEvent>(_onRegisterWithEmail);
    on<RegisterWithPhoneEvent>(_onRegisterWithPhone);
    on<SendEmailVerificationEvent>(_onSendEmailVerification);
    on<SendPhoneVerificationEvent>(_onSendPhoneVerification);
    on<VerifyEmailEvent>(_onVerifyEmail);
    on<VerifyPhoneEvent>(_onVerifyPhone);
    on<ResendVerificationEvent>(_onResendVerification);
    on<SaveProgressiveProfileEvent>(_onSaveProgressiveProfile);
    on<GetProgressiveProfileEvent>(_onGetProgressiveProfile);
    on<LogoutEvent>(_onLogout);
    on<GetCurrentUserEvent>(_onGetCurrentUser);
    on<SocialSignInEvent>(_onSocialSignIn);
    on<LinkSocialAccountEvent>(_onLinkSocialAccount);
    on<UnlinkSocialAccountEvent>(_onUnlinkSocialAccount);
    on<GetLinkedSocialAccountsEvent>(_onGetLinkedSocialAccounts);
    on<CheckAccountLockStatusEvent>(_onCheckAccountLockStatus);
    on<UnlockAccountEvent>(_onUnlockAccount);
    on<CheckBiometricCapabilityEvent>(_onCheckBiometricCapability);
    on<SetupBiometricAuthEvent>(_onSetupBiometricAuth);
    on<BiometricLoginEvent>(_onBiometricLogin);
    on<ToggleBiometricAuthEvent>(_onToggleBiometricAuth);
    on<GetBiometricPreferencesEvent>(_onGetBiometricPreferences);
  }

  Future<void> _onRegisterWithEmail(
    RegisterWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      // Check if email is locked
      final isLocked = await authRepository.isAccountLocked(event.email);
      if (isLocked) {
        final lockEndTime = await authRepository.getLockoutEndTime(event.email);
        emit(
          AccountLockedState(
            reason:
                'Account temporarily locked due to too many failed attempts',
            lockedUntil: lockEndTime,
          ),
        );
        return;
      }

      final user = await authRepository.registerWithEmail(
        email: event.email,
        password: event.password,
        ageVerified: event.ageVerified,
        consentData: event.consentData,
      );

      // Record successful attempt
      await authRepository.recordLoginAttempt(
        email: event.email,
        phone: null,
        ipAddress: 'unknown', // Would get from actual request
        userAgent: 'unknown', // Would get from actual request
        wasSuccessful: true,
        userId: user.id,
      );

      emit(AuthenticatedState(user: user));
    } catch (e) {
      // Record failed attempt
      await authRepository.recordLoginAttempt(
        email: event.email,
        phone: null,
        ipAddress: 'unknown',
        userAgent: 'unknown',
        wasSuccessful: false,
        failureReason: e.toString(),
      );

      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onRegisterWithPhone(
    RegisterWithPhoneEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      // Check if phone is locked
      final isLocked = await authRepository.isAccountLocked(event.phone);
      if (isLocked) {
        final lockEndTime = await authRepository.getLockoutEndTime(event.phone);
        emit(
          AccountLockedState(
            reason:
                'Account temporarily locked due to too many failed attempts',
            lockedUntil: lockEndTime,
          ),
        );
        return;
      }

      final user = await authRepository.registerWithPhone(
        phone: event.phone,
        password: event.password,
        ageVerified: event.ageVerified,
        consentData: event.consentData,
      );

      // Record successful attempt
      await authRepository.recordLoginAttempt(
        email: null,
        phone: event.phone,
        ipAddress: 'unknown',
        userAgent: 'unknown',
        wasSuccessful: true,
        userId: user.id,
      );

      emit(AuthenticatedState(user: user));
    } catch (e) {
      // Record failed attempt
      await authRepository.recordLoginAttempt(
        email: null,
        phone: event.phone,
        ipAddress: 'unknown',
        userAgent: 'unknown',
        wasSuccessful: false,
        failureReason: e.toString(),
      );

      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onSendEmailVerification(
    SendEmailVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final token = await authRepository.sendEmailVerification(event.userId);
      emit(EmailVerificationSentState(token: token));
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onSendPhoneVerification(
    SendPhoneVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final token = await authRepository.sendPhoneVerification(event.userId);
      emit(PhoneVerificationSentState(token: token));
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onVerifyEmail(
    VerifyEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final isVerified = await authRepository.verifyEmail(
        event.userId,
        event.token,
      );
      if (isVerified) {
        final user = await authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthenticatedState(user: user));
        } else {
          emit(
            const AuthErrorState(message: 'User not found after verification'),
          );
        }
      } else {
        emit(const AuthErrorState(message: 'Invalid verification token'));
      }
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onVerifyPhone(
    VerifyPhoneEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final isVerified = await authRepository.verifyPhone(
        event.userId,
        event.token,
      );
      if (isVerified) {
        final user = await authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthenticatedState(user: user));
        } else {
          emit(
            const AuthErrorState(message: 'User not found after verification'),
          );
        }
      } else {
        emit(const AuthErrorState(message: 'Invalid verification code'));
      }
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onResendVerification(
    ResendVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final token = await authRepository.resendVerification(
        event.userId,
        event.tokenType,
      );
      if (event.tokenType == TokenType.email) {
        emit(EmailVerificationSentState(token: token));
      } else {
        emit(PhoneVerificationSentState(token: token));
      }
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onSaveProgressiveProfile(
    SaveProgressiveProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authRepository.saveProgressiveProfile(
        event.userId,
        event.profileData,
      );
      emit(ProfileSavedState());
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onGetProgressiveProfile(
    GetProgressiveProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final profile = await authRepository.getProgressiveProfile(event.userId);
      emit(ProfileLoadedState(profile: profile));
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await authRepository.logout();
      emit(const UnauthenticatedState());
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onGetCurrentUser(
    GetCurrentUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthenticatedState(user: user));
      } else {
        emit(const UnauthenticatedState());
      }
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onSocialSignIn(
    SocialSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const SocialAuthLoadingState());
    try {
      // Use SocialAuthManager for secure social authentication
      final authResult = await socialAuthManager.signInWithProvider(
        event.provider,
      );

      if (authResult.isSuccess) {
        emit(
          SocialAuthSuccessState(
            user: authResult.user,
            socialAccount: authResult.socialAccount,
            isNewUser: authResult.isNewUser,
          ),
        );
      } else {
        emit(
          SocialAuthErrorState(
            message: authResult.errorMessage ?? 'Social authentication failed',
            provider: event.provider,
          ),
        );
      }
    } catch (e) {
      _logger.e('Social authentication error: $e');
      emit(
        SocialAuthErrorState(
          message: 'Social authentication error: ${e.toString()}',
          provider: event.provider,
        ),
      );
    }
  }

  Future<void> _onLinkSocialAccount(
    LinkSocialAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final linkedAccount = await authRepository.linkSocialAccount(
        userId: event.userId,
        provider: event.provider,
        providerId: event.providerId ?? '',
        accessToken: event.accessToken ?? '',
        email: event.email,
        profilePicture: event.profilePicture,
      );

      emit(SocialAccountLinkedState(account: linkedAccount));
    } catch (e) {
      _logger.e('Social account linking error: $e');
      emit(
        SocialAuthErrorState(
          message: 'Social account linking error: ${e.toString()}',
          provider: event.provider,
        ),
      );
    }
  }

  Future<void> _onUnlinkSocialAccount(
    UnlinkSocialAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Use SocialAuthManager for secure account unlinking
      final success = await socialAuthManager.unlinkSocialAccount(
        userId: event.userId,
        socialAccountId: event.socialAccountId,
      );

      if (success) {
        emit(
          SocialAccountUnlinkedState(socialAccountId: event.socialAccountId),
        );
      } else {
        emit(AuthErrorState(message: 'Failed to unlink social account'));
      }
    } catch (e) {
      _logger.e('Social account unlinking error: $e');
      emit(
        AuthErrorState(
          message: 'Social account unlinking error: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onGetLinkedSocialAccounts(
    GetLinkedSocialAccountsEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Use SocialAuthManager to get linked accounts
      final accounts = await socialAuthManager.getLinkedSocialAccounts(
        event.userId,
      );

      emit(SocialAccountsLoadedState(accounts: accounts));
    } catch (e) {
      _logger.e('Error getting linked social accounts: $e');
      emit(
        AuthErrorState(
          message: 'Error getting linked social accounts: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onCheckAccountLockStatus(
    CheckAccountLockStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isLocked = await authRepository.isAccountLocked(event.identifier);
      if (isLocked) {
        final lockEndTime = await authRepository.getLockoutEndTime(
          event.identifier,
        );
        final remainingAttempts = await authRepository
            .getRemainingFailedAttempts(event.identifier);

        emit(
          AccountLockedState(
            reason: 'Too many failed attempts',
            lockedUntil: lockEndTime,
          ),
        );
      } else {
        final remainingAttempts = await authRepository
            .getRemainingFailedAttempts(event.identifier);
        // Could emit a state with remaining attempts info if needed
        emit(const AuthInitialState());
      }
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onUnlockAccount(
    UnlockAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authRepository.unlockAccount(event.identifier);
      emit(const AuthInitialState());
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  // Biometric Authentication Event Handlers
  Future<void> _onCheckBiometricCapability(
    CheckBiometricCapabilityEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoadingState());

      final capability = await biometricAuthService.checkBiometricCapability();

      emit(
        BiometricCapabilityChecked(
          isAvailable: capability.isAvailable,
          biometricType: capability.type.name,
          errorMessage: capability.errorMessage,
        ),
      );
    } catch (e) {
      _logger.e('Error checking biometric capability: $e');
      emit(
        AuthErrorState(
          message: 'Failed to check biometric capability: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onSetupBiometricAuth(
    SetupBiometricAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoadingState());

      final success = await biometricAuthService.enableBiometricAuth();

      emit(
        BiometricAuthSetupComplete(
          success: success,
          errorMessage: success
              ? null
              : 'Failed to setup biometric authentication',
        ),
      );
    } catch (e) {
      _logger.e('Error setting up biometric auth: $e');
      emit(
        BiometricAuthSetupComplete(
          success: false,
          errorMessage: e.toString().contains('BiometricException')
              ? e.toString().replaceFirst('BiometricException: ', '')
              : 'Failed to setup biometric authentication',
        ),
      );
    }
  }

  Future<void> _onBiometricLogin(
    BiometricLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoadingState());

      final authResult = await biometricAuthService.authenticate(
        reason: 'Sign in with biometrics',
      );

      if (authResult.success) {
        emit(
          BiometricAuthSuccess(
            biometricType: authResult.biometricType.name,
            authenticatedAt: authResult.timestamp,
          ),
        );
      } else {
        final preferences = await biometricAuthService
            .getBiometricPreferences();
        emit(
          BiometricAuthFailed(
            reason:
                authResult.errorMessage ?? 'Biometric authentication failed',
            remainingAttempts: preferences.failedAttempts,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error during biometric login: $e');
      emit(
        BiometricAuthFailed(
          reason: e.toString().contains('BiometricException')
              ? e.toString().replaceFirst('BiometricException: ', '')
              : 'Biometric authentication error',
          remainingAttempts: 0,
        ),
      );
    }
  }

  Future<void> _onToggleBiometricAuth(
    ToggleBiometricAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoadingState());

      if (event.enable) {
        await biometricAuthService.enableBiometricAuth();
      } else {
        await biometricAuthService.disableBiometricAuth();
      }

      final preferences = await biometricAuthService.getBiometricPreferences();
      emit(
        BiometricPreferencesLoaded(
          isEnabled: preferences.isEnabled,
          biometricType: preferences.preferredBiometricType.name,
          lastUsed: preferences.lastSuccessfulAuth,
          isLockedOut: preferences.isLockedOut,
        ),
      );
    } catch (e) {
      _logger.e('Error toggling biometric auth: $e');
      emit(
        AuthErrorState(
          message: 'Failed to toggle biometric authentication: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onGetBiometricPreferences(
    GetBiometricPreferencesEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoadingState());

      final preferences = await biometricAuthService.getBiometricPreferences();

      emit(
        BiometricPreferencesLoaded(
          isEnabled: preferences.isEnabled,
          biometricType: preferences.preferredBiometricType.name,
          lastUsed: preferences.lastSuccessfulAuth,
          isLockedOut: preferences.isLockedOut,
        ),
      );
    } catch (e) {
      _logger.e('Error getting biometric preferences: $e');
      emit(
        AuthErrorState(
          message: 'Failed to get biometric preferences: ${e.toString()}',
        ),
      );
    }
  }
}
