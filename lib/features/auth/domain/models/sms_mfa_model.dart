import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sms_mfa_model.g.dart';

@JsonSerializable()
class SmsMfaConfigModel extends Equatable {
  final String id;
  final String userId;
  final String phoneNumber;
  final String countryCode;
  final bool isVerified;
  final bool isEnabled;
  final DateTime lastVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SmsMfaConfigModel({
    required this.id,
    required this.userId,
    required this.phoneNumber,
    required this.countryCode,
    this.isVerified = false,
    this.isEnabled = false,
    required this.lastVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SmsMfaConfigModel.fromJson(Map<String, dynamic> json) =>
      _$SmsMfaConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$SmsMfaConfigModelToJson(this);

  String get fullPhoneNumber => '+$countryCode$phoneNumber';

  bool get canReceiveCodes => isVerified && isEnabled;

  SmsMfaConfigModel copyWith({
    String? id,
    String? userId,
    String? phoneNumber,
    String? countryCode,
    bool? isVerified,
    bool? isEnabled,
    DateTime? lastVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SmsMfaConfigModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      isVerified: isVerified ?? this.isVerified,
      isEnabled: isEnabled ?? this.isEnabled,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    userId,
    phoneNumber,
    countryCode,
    isVerified,
    isEnabled,
    lastVerifiedAt,
    createdAt,
    updatedAt,
  ];
}

@JsonSerializable()
class SmsVerificationModel extends Equatable {
  final String id;
  final String userId;
  final String phoneNumber;
  final String countryCode;
  final String verificationCode;
  final DateTime expiresAt;
  final int attempts;
  final int maxAttempts;
  final bool isVerified;
  final DateTime createdAt;

  const SmsVerificationModel({
    required this.id,
    required this.userId,
    required this.phoneNumber,
    required this.countryCode,
    required this.verificationCode,
    required this.expiresAt,
    this.attempts = 0,
    this.maxAttempts = 3,
    this.isVerified = false,
    required this.createdAt,
  });

  factory SmsVerificationModel.fromJson(Map<String, dynamic> json) =>
      _$SmsVerificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$SmsVerificationModelToJson(this);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isLocked => attempts >= maxAttempts;
  bool get canAttempt => !isExpired && !isLocked && !isVerified;

  String get fullPhoneNumber => '+$countryCode$phoneNumber';

  SmsVerificationModel copyWith({
    String? id,
    String? userId,
    String? phoneNumber,
    String? countryCode,
    String? verificationCode,
    DateTime? expiresAt,
    int? attempts,
    int? maxAttempts,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return SmsVerificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      verificationCode: verificationCode ?? this.verificationCode,
      expiresAt: expiresAt ?? this.expiresAt,
      attempts: attempts ?? this.attempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    userId,
    phoneNumber,
    countryCode,
    verificationCode,
    expiresAt,
    attempts,
    maxAttempts,
    isVerified,
    createdAt,
  ];
}

@JsonSerializable()
class SmsDeliveryStatusModel extends Equatable {
  final String id;
  final String verificationId;
  final String messageId;
  final String phoneNumber;
  final SmsDeliveryStatus status;
  final String? errorMessage;
  final DateTime? deliveredAt;
  final DateTime createdAt;

  const SmsDeliveryStatusModel({
    required this.id,
    required this.verificationId,
    required this.messageId,
    required this.phoneNumber,
    required this.status,
    this.errorMessage,
    this.deliveredAt,
    required this.createdAt,
  });

  factory SmsDeliveryStatusModel.fromJson(Map<String, dynamic> json) =>
      _$SmsDeliveryStatusModelFromJson(json);

  Map<String, dynamic> toJson() => _$SmsDeliveryStatusModelToJson(this);

  bool get isDelivered => status == SmsDeliveryStatus.delivered;
  bool get isFailed => status == SmsDeliveryStatus.failed;

  SmsDeliveryStatusModel copyWith({
    String? id,
    String? verificationId,
    String? messageId,
    String? phoneNumber,
    SmsDeliveryStatus? status,
    String? errorMessage,
    DateTime? deliveredAt,
    DateTime? createdAt,
  }) {
    return SmsDeliveryStatusModel(
      id: id ?? this.id,
      verificationId: verificationId ?? this.verificationId,
      messageId: messageId ?? this.messageId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    verificationId,
    messageId,
    phoneNumber,
    status,
    errorMessage,
    deliveredAt,
    createdAt,
  ];
}

@JsonEnum()
enum SmsDeliveryStatus { pending, sent, delivered, failed, expired }
