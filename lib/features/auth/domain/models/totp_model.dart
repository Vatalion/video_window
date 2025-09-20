import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:otp/otp.dart';

part 'totp_model.g.dart';

@JsonSerializable()
class TotpConfigModel extends Equatable {
  final String id;
  final String userId;
  final String secret;
  final String issuer;
  final String accountName;
  final int algorithm;
  final int digits;
  final int period;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TotpConfigModel({
    required this.id,
    required this.userId,
    required this.secret,
    required this.issuer,
    required this.accountName,
    this.algorithm = OTPAlgorithm.SHA1,
    this.digits = 6,
    this.period = 30,
    this.isEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TotpConfigModel.fromJson(Map<String, dynamic> json) =>
      _$TotpConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$TotpConfigModelToJson(this);

  TotpConfigModel copyWith({
    String? id,
    String? userId,
    String? secret,
    String? issuer,
    String? accountName,
    int? algorithm,
    int? digits,
    int? period,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TotpConfigModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      secret: secret ?? this.secret,
      issuer: issuer ?? this.issuer,
      accountName: accountName ?? this.accountName,
      algorithm: algorithm ?? this.algorithm,
      digits: digits ?? this.digits,
      period: period ?? this.period,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String generateUri() {
    return OTP.generateTOTPUri(
      secret: secret,
      label: '$issuer:$accountName',
      issuer: issuer,
      algorithm: algorithm,
      digits: digits,
      period: period,
    );
  }

  String generateCurrentCode() {
    return OTP.generateTOTPCode(
      secret: secret,
      algorithm: algorithm,
      digits: digits,
      period: period,
    );
  }

  bool verifyCode(String code, {int? time}) {
    final currentTime = time ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Check current code and adjacent codes to account for clock drift
    for (int i = -1; i <= 1; i++) {
      final checkTime = currentTime + (i * period);
      final expectedCode = OTP.generateTOTPCode(
        secret: secret,
        algorithm: algorithm,
        digits: digits,
        period: period,
        time: checkTime,
      );

      if (expectedCode == code) {
        return true;
      }
    }

    return false;
  }

  @override
  List<Object> get props => [
    id,
    userId,
    secret,
    issuer,
    accountName,
    algorithm,
    digits,
    period,
    isEnabled,
    createdAt,
    updatedAt,
  ];
}

@JsonSerializable()
class TotpSetupModel extends Equatable {
  final String id;
  final String userId;
  final String secret;
  final String qrCodeUri;
  final String manualSetupKey;
  final List<String> backupCodes;
  final DateTime expiresAt;
  final bool isCompleted;
  final DateTime createdAt;

  const TotpSetupModel({
    required this.id,
    required this.userId,
    required this.secret,
    required this.qrCodeUri,
    required this.manualSetupKey,
    required this.backupCodes,
    required this.expiresAt,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory TotpSetupModel.fromJson(Map<String, dynamic> json) =>
      _$TotpSetupModelFromJson(json);

  Map<String, dynamic> toJson() => _$TotpSetupModelToJson(this);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  TotpSetupModel copyWith({
    String? id,
    String? userId,
    String? secret,
    String? qrCodeUri,
    String? manualSetupKey,
    List<String>? backupCodes,
    DateTime? expiresAt,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TotpSetupModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      secret: secret ?? this.secret,
      qrCodeUri: qrCodeUri ?? this.qrCodeUri,
      manualSetupKey: manualSetupKey ?? this.manualSetupKey,
      backupCodes: backupCodes ?? this.backupCodes,
      expiresAt: expiresAt ?? this.expiresAt,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    userId,
    secret,
    qrCodeUri,
    manualSetupKey,
    backupCodes,
    expiresAt,
    isCompleted,
    createdAt,
  ];
}
