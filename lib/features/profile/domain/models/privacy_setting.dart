enum ProfileVisibility { public, private, friendsOnly }

enum SearchVisibility { visible, hidden }

class PrivacySetting {
  final String userId;
  final ProfileVisibility profileVisibility;
  final bool allowDataSharing;
  final SearchVisibility searchVisibility;
  final DateTime updatedAt;

  PrivacySetting({
    required this.userId,
    this.profileVisibility = ProfileVisibility.public,
    this.allowDataSharing = true,
    this.searchVisibility = SearchVisibility.visible,
    required this.updatedAt,
  });

  PrivacySetting copyWith({
    ProfileVisibility? profileVisibility,
    bool? allowDataSharing,
    SearchVisibility? searchVisibility,
    DateTime? updatedAt,
  }) {
    return PrivacySetting(
      userId: userId,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      allowDataSharing: allowDataSharing ?? this.allowDataSharing,
      searchVisibility: searchVisibility ?? this.searchVisibility,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'profileVisibility': profileVisibility.name,
      'allowDataSharing': allowDataSharing,
      'searchVisibility': searchVisibility.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PrivacySetting.fromJson(Map<String, dynamic> json) {
    return PrivacySetting(
      userId: json['userId'] as String,
      profileVisibility: ProfileVisibility.values.firstWhere(
        (e) => e.name == json['profileVisibility'],
        orElse: () => ProfileVisibility.public,
      ),
      allowDataSharing: json['allowDataSharing'] as bool? ?? true,
      searchVisibility: SearchVisibility.values.firstWhere(
        (e) => e.name == json['searchVisibility'],
        orElse: () => SearchVisibility.visible,
      ),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}