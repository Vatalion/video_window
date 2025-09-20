import 'package:equatable/equatable.dart';

class SocialAccountModel extends Equatable {
  final String id;
  final String userId;
  final SocialProvider provider;
  final String providerId;
  final String? accessToken;
  final String? idToken;
  final String? refreshToken;
  final DateTime? tokenExpiresAt;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isActive;
  final DateTime linkedAt;
  final DateTime? lastUsedAt;

  const SocialAccountModel({
    required this.id,
    required this.userId,
    required this.provider,
    required this.providerId,
    this.accessToken,
    this.idToken,
    this.refreshToken,
    this.tokenExpiresAt,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.isActive,
    required this.linkedAt,
    this.lastUsedAt,
  });

  factory SocialAccountModel.fromJson(Map<String, dynamic> json) {
    return SocialAccountModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      provider: SocialProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => SocialProvider.google,
      ),
      providerId: json['provider_id'] as String,
      accessToken: json['access_token'] as String?,
      idToken: json['id_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      tokenExpiresAt: json['token_expires_at'] != null
          ? DateTime.parse(json['token_expires_at'] as String)
          : null,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      isActive: json['is_active'] as bool,
      linkedAt: DateTime.parse(json['linked_at'] as String),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider': provider.name,
      'provider_id': providerId,
      'access_token': accessToken,
      'id_token': idToken,
      'refresh_token': refreshToken,
      'token_expires_at': tokenExpiresAt?.toIso8601String(),
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'is_active': isActive,
      'linked_at': linkedAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
    };
  }

  bool get isTokenExpired {
    if (tokenExpiresAt == null) return true;
    return DateTime.now().isAfter(tokenExpiresAt!);
  }

  SocialAccountModel copyWith({
    String? id,
    String? userId,
    SocialProvider? provider,
    String? providerId,
    String? accessToken,
    String? idToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isActive,
    DateTime? linkedAt,
    DateTime? lastUsedAt,
  }) {
    return SocialAccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
      accessToken: accessToken ?? this.accessToken,
      idToken: idToken ?? this.idToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      linkedAt: linkedAt ?? this.linkedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    userId,
    provider,
    providerId,
    accessToken ?? '',
    idToken ?? '',
    refreshToken ?? '',
    tokenExpiresAt ?? DateTime.now(),
    email ?? '',
    displayName ?? '',
    photoUrl ?? '',
    isActive,
    linkedAt,
    lastUsedAt ?? DateTime.now(),
  ];
}

enum SocialProvider { google, apple, facebook }

enum SocialAuthStatus { notLinked, linked, expired, error }
