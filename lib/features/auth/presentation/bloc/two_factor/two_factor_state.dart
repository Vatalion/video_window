part of 'two_factor_bloc.dart';

class TwoFactorState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final TwoFactorConfig? config;
  final List<String> backupCodes;
  final bool isGracePeriodActive;
  final bool isAccountLocked;
  final TwoFactorVerification? currentVerification;

  const TwoFactorState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.config,
    this.backupCodes = const [],
    this.isGracePeriodActive = false,
    this.isAccountLocked = false,
    this.currentVerification,
  });

  TwoFactorState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    TwoFactorConfig? config,
    List<String>? backupCodes,
    bool? isGracePeriodActive,
    bool? isAccountLocked,
    TwoFactorVerification? currentVerification,
  }) {
    return TwoFactorState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      config: config ?? this.config,
      backupCodes: backupCodes ?? this.backupCodes,
      isGracePeriodActive: isGracePeriodActive ?? this.isGracePeriodActive,
      isAccountLocked: isAccountLocked ?? this.isAccountLocked,
      currentVerification: currentVerification ?? this.currentVerification,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    successMessage,
    config,
    backupCodes,
    isGracePeriodActive,
    isAccountLocked,
    currentVerification,
  ];

  bool get isTwoFactorEnabled => config?.isEnabled ?? false;
  bool get isSmsEnabled =>
      config?.method == TwoFactorMethod.sms && config?.isEnabled == true;
  bool get isTotpEnabled =>
      config?.method == TwoFactorMethod.totp && config?.isEnabled == true;
  bool get hasError => errorMessage != null;
  bool get hasSuccess => successMessage != null;
}
