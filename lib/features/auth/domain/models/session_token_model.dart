import 'package:equatable/equatable.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:uuid/uuid.dart';

class SessionTokenModel extends Equatable {
  final String id;
  final String userId;
  final String deviceId;
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final DateTime refreshTokenExpiresAt;
  final DateTime issuedAt;
  final String? ipAddress;
  final String? userAgent;
  final bool isActive;
  final TokenType tokenType;
  final int tokenVersion;

  const SessionTokenModel({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
    required this.issuedAt,
    this.ipAddress,
    this.userAgent,
    this.isActive = true,
    this.tokenType = TokenType.bearer,
    this.tokenVersion = 1,
  });

  factory SessionTokenModel.fromJson(Map<String, dynamic> json) {
    return SessionTokenModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      deviceId: json['device_id'] as String,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessTokenExpiresAt: DateTime.parse(
        json['access_token_expires_at'] as String,
      ),
      refreshTokenExpiresAt: DateTime.parse(
        json['refresh_token_expires_at'] as String,
      ),
      issuedAt: DateTime.parse(json['issued_at'] as String),
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      isActive: json['is_active'] as bool,
      tokenType: TokenType.values.firstWhere(
        (e) => e.name == json['token_type'],
        orElse: () => TokenType.bearer,
      ),
      tokenVersion: json['token_version'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'access_token_expires_at': accessTokenExpiresAt.toIso8601String(),
      'refresh_token_expires_at': refreshTokenExpiresAt.toIso8601String(),
      'issued_at': issuedAt.toIso8601String(),
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'is_active': isActive,
      'token_type': tokenType.name,
      'token_version': tokenVersion,
    };
  }

  SessionTokenModel copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? accessToken,
    String? refreshToken,
    DateTime? accessTokenExpiresAt,
    DateTime? refreshTokenExpiresAt,
    DateTime? issuedAt,
    String? ipAddress,
    String? userAgent,
    bool? isActive,
    TokenType? tokenType,
    int? tokenVersion,
  }) {
    return SessionTokenModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      refreshTokenExpiresAt:
          refreshTokenExpiresAt ?? this.refreshTokenExpiresAt,
      issuedAt: issuedAt ?? this.issuedAt,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      isActive: isActive ?? this.isActive,
      tokenType: tokenType ?? this.tokenType,
      tokenVersion: tokenVersion ?? this.tokenVersion,
    );
  }

  bool get isAccessTokenExpired => DateTime.now().isAfter(accessTokenExpiresAt);
  bool get isRefreshTokenExpired =>
      DateTime.now().isAfter(refreshTokenExpiresAt);
  bool get isValid => isActive && !isRefreshTokenExpired;
  bool get needsRefresh => !isAccessTokenExpired && isValid;
  bool get isExpired => isAccessTokenExpired || !isActive;

  Map<String, dynamic> getAccessTokenPayload() {
    try {
      return Jwt.parseJwt(accessToken);
    } catch (e) {
      return {};
    }
  }

  String? getAccessTokenClaim(String claim) {
    return getAccessTokenPayload()[claim] as String?;
  }

  Duration get accessTokenRemainingTime {
    return accessTokenExpiresAt.difference(DateTime.now());
  }

  Duration get refreshTokenRemainingTime {
    return refreshTokenExpiresAt.difference(DateTime.now());
  }

  static SessionTokenModel create({
    required String userId,
    required String deviceId,
    required String accessToken,
    required String refreshToken,
    Duration accessTokenDuration = const Duration(minutes: 30),
    Duration refreshTokenDuration = const Duration(days: 7),
    String? ipAddress,
    String? userAgent,
  }) {
    final now = DateTime.now();
    return SessionTokenModel(
      id: const Uuid().v4(),
      userId: userId,
      deviceId: deviceId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: now.add(accessTokenDuration),
      refreshTokenExpiresAt: now.add(refreshTokenDuration),
      issuedAt: now,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
  }

  @override
  List<Object> get props => [
    id,
    userId,
    deviceId,
    accessToken,
    refreshToken,
    accessTokenExpiresAt,
    refreshTokenExpiresAt,
    issuedAt,
    ipAddress ?? '',
    userAgent ?? '',
    isActive,
    tokenType,
    tokenVersion,
  ];
}

enum TokenType { bearer, mac, jwt }

extension TokenTypeExtension on TokenType {
  String get headerValue {
    switch (this) {
      case TokenType.bearer:
        return 'Bearer';
      case TokenType.mac:
        return 'MAC';
      case TokenType.jwt:
        return 'JWT';
    }
  }
}
