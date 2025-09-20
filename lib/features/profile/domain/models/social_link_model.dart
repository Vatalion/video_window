import 'package:equatable/equatable.dart';

class SocialLinkModel extends Equatable {
  final String id;
  final String userId;
  final SocialPlatform platform;
  final String url;
  final String? username;
  final bool isVerified;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SocialLinkModel({
    required this.id,
    required this.userId,
    required this.platform,
    required this.url,
    this.username,
    this.isVerified = false,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SocialLinkModel.fromJson(Map<String, dynamic> json) {
    return SocialLinkModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      platform: SocialPlatform.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => SocialPlatform.website,
      ),
      url: json['url'] as String,
      username: json['username'] as String?,
      isVerified: json['is_verified'] as bool,
      displayOrder: json['display_order'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'platform': platform.name,
      'url': url,
      'username': username,
      'is_verified': isVerified,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SocialLinkModel copyWith({
    String? id,
    String? userId,
    SocialPlatform? platform,
    String? url,
    String? username,
    bool? isVerified,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SocialLinkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      platform: platform ?? this.platform,
      url: url ?? this.url,
      username: username ?? this.username,
      isVerified: isVerified ?? this.isVerified,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    return username ?? platform.displayName;
  }

  String get displayUrl {
    if (platform == SocialPlatform.website) {
      return url;
    }
    return platform.urlTemplate.replaceAll('{username}', username ?? '');
  }

  @override
  List<Object> get props => [
        id,
        userId,
        platform,
        url,
        username ?? '',
        isVerified,
        displayOrder,
        createdAt,
        updatedAt,
      ];
}

enum SocialPlatform {
  twitter,
  instagram,
  facebook,
  linkedin,
  youtube,
  tiktok,
  github,
  website,
  discord,
  telegram,
}

extension SocialPlatformExtension on SocialPlatform {
  String get displayName {
    switch (this) {
      case SocialPlatform.twitter:
        return 'Twitter';
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.linkedin:
        return 'LinkedIn';
      case SocialPlatform.youtube:
        return 'YouTube';
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.github:
        return 'GitHub';
      case SocialPlatform.website:
        return 'Website';
      case SocialPlatform.discord:
        return 'Discord';
      case SocialPlatform.telegram:
        return 'Telegram';
    }
  }

  String get urlTemplate {
    switch (this) {
      case SocialPlatform.twitter:
        return 'https://twitter.com/{username}';
      case SocialPlatform.instagram:
        return 'https://instagram.com/{username}';
      case SocialPlatform.facebook:
        return 'https://facebook.com/{username}';
      case SocialPlatform.linkedin:
        return 'https://linkedin.com/in/{username}';
      case SocialPlatform.youtube:
        return 'https://youtube.com/{username}';
      case SocialPlatform.tiktok:
        return 'https://tiktok.com/@{username}';
      case SocialPlatform.github:
        return 'https://github.com/{username}';
      case SocialPlatform.website:
        return '{url}';
      case SocialPlatform.discord:
        return 'https://discord.gg/{username}';
      case SocialPlatform.telegram:
        return 'https://t.me/{username}';
    }
  }

  String get icon {
    switch (this) {
      case SocialPlatform.twitter:
        return '𝕏';
      case SocialPlatform.instagram:
        return '📷';
      case SocialPlatform.facebook:
        return '📘';
      case SocialPlatform.linkedin:
        return '💼';
      case SocialPlatform.youtube:
        return '📺';
      case SocialPlatform.tiktok:
        return '🎵';
      case SocialPlatform.github:
        return '💻';
      case SocialPlatform.website:
        return '🌐';
      case SocialPlatform.discord:
        return '💬';
      case SocialPlatform.telegram:
        return '✈️';
    }
  }
}