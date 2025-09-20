enum SocialPlatform {
  twitter,
  instagram,
  facebook,
  linkedin,
  youtube,
  tiktok,
  github,
  website,
}

class SocialLink {
  final String userId;
  final SocialPlatform platform;
  final String url;
  final bool verified;
  final int displayOrder;

  SocialLink({
    required this.userId,
    required this.platform,
    required this.url,
    this.verified = false,
    this.displayOrder = 0,
  });

  SocialLink copyWith({
    SocialPlatform? platform,
    String? url,
    bool? verified,
    int? displayOrder,
  }) {
    return SocialLink(
      userId: userId,
      platform: platform ?? this.platform,
      url: url ?? this.url,
      verified: verified ?? this.verified,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  String get displayName {
    switch (platform) {
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
    }
  }

  String get icon {
    switch (platform) {
      case SocialPlatform.twitter:
        return '🐦';
      case SocialPlatform.instagram:
        return '📷';
      case SocialPlatform.facebook:
        return '📘';
      case SocialPlatform.linkedin:
        return '💼';
      case SocialPlatform.youtube:
        return '🎥';
      case SocialPlatform.tiktok:
        return '🎵';
      case SocialPlatform.github:
        return '💻';
      case SocialPlatform.website:
        return '🌐';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'platform': platform.name,
      'url': url,
      'verified': verified,
      'displayOrder': displayOrder,
    };
  }

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    return SocialLink(
      userId: json['userId'] as String,
      platform: SocialPlatform.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => SocialPlatform.website,
      ),
      url: json['url'] as String,
      verified: json['verified'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }
}