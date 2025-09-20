import 'package:equatable/equatable.dart';
import 'package:video_window/features/auth/domain/models/user_model.dart';
import 'package:video_window/features/auth/domain/models/social_account_model.dart';

class SocialAuthResult extends Equatable {
  final UserModel user;
  final SocialAccountModel socialAccount;
  final bool isNewUser;
  final SocialAuthResultType resultType;
  final String? errorMessage;
  final String? state;

  const SocialAuthResult({
    required this.user,
    required this.socialAccount,
    required this.isNewUser,
    required this.resultType,
    this.errorMessage,
    this.state,
  });

  factory SocialAuthResult.success({
    required UserModel user,
    required SocialAccountModel socialAccount,
    bool isNewUser = false,
    String? state,
  }) {
    return SocialAuthResult(
      user: user,
      socialAccount: socialAccount,
      isNewUser: isNewUser,
      resultType: SocialAuthResultType.success,
      state: state,
    );
  }

  factory SocialAuthResult.error({
    required String errorMessage,
    SocialAuthResultType resultType = SocialAuthResultType.error,
    String? state,
  }) {
    return SocialAuthResult(
      user: UserModelExtension.empty(),
      socialAccount: SocialAccountModelExtension.empty(),
      isNewUser: false,
      resultType: resultType,
      errorMessage: errorMessage,
      state: state,
    );
  }

  factory SocialAuthResult.cancelled({String? state}) {
    return SocialAuthResult(
      user: UserModelExtension.empty(),
      socialAccount: SocialAccountModelExtension.empty(),
      isNewUser: false,
      resultType: SocialAuthResultType.cancelled,
      errorMessage: 'Authentication cancelled by user',
      state: state,
    );
  }

  bool get isSuccess => resultType == SocialAuthResultType.success;
  bool get isError => resultType == SocialAuthResultType.error;
  bool get isCancelled => resultType == SocialAuthResultType.cancelled;
  bool get isAccountExists => resultType == SocialAuthResultType.accountExists;

  @override
  List<Object> get props => [
    user,
    socialAccount,
    isNewUser,
    resultType,
    errorMessage ?? '',
    state ?? '',
  ];
}

enum SocialAuthResultType { success, error, cancelled, accountExists }

extension UserModelExtension on UserModel {
  static UserModel empty() {
    return UserModel(
      id: '',
      email: '',
      passwordHash: '',
      verificationStatus: VerificationStatus.pending,
      ageVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

extension SocialAccountModelExtension on SocialAccountModel {
  static SocialAccountModel empty() {
    return SocialAccountModel(
      id: '',
      userId: '',
      provider: SocialProvider.google,
      providerId: '',
      isActive: false,
      linkedAt: DateTime.now(),
    );
  }
}
