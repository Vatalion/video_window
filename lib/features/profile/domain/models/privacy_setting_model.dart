import 'package:equatable/equatable.dart';

class PrivacySettingModel extends Equatable {
  final String id;
  final String userId;
  final ProfileVisibility profileVisibility;
  final DataSharingSettings dataSharing;
  final SearchVisibility searchVisibility;
  final MessageSettings messageSettings;
  final ActivitySettings activitySettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PrivacySettingModel({
    required this.id,
    required this.userId,
    required this.profileVisibility,
    required this.dataSharing,
    required this.searchVisibility,
    required this.messageSettings,
    required this.activitySettings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrivacySettingModel.fromJson(Map<String, dynamic> json) {
    return PrivacySettingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      profileVisibility: ProfileVisibility.values.firstWhere(
        (e) => e.name == json['profile_visibility'],
        orElse: () => ProfileVisibility.public,
      ),
      dataSharing: DataSharingSettings.fromJson(
        json['data_sharing'] as Map<String, dynamic>,
      ),
      searchVisibility: SearchVisibility.values.firstWhere(
        (e) => e.name == json['search_visibility'],
        orElse: () => SearchVisibility.everyone,
      ),
      messageSettings: MessageSettings.fromJson(
        json['message_settings'] as Map<String, dynamic>,
      ),
      activitySettings: ActivitySettings.fromJson(
        json['activity_settings'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'profile_visibility': profileVisibility.name,
      'data_sharing': dataSharing.toJson(),
      'search_visibility': searchVisibility.name,
      'message_settings': messageSettings.toJson(),
      'activity_settings': activitySettings.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [
        id,
        userId,
        profileVisibility,
        dataSharing,
        searchVisibility,
        messageSettings,
        activitySettings,
        createdAt,
        updatedAt,
      ];
}

class DataSharingSettings extends Equatable {
  final bool shareProfileWithPartners;
  final bool shareActivityWithFriends;
  final bool shareLocationData;
  final bool allowDataAnalytics;
  final bool allowPersonalizedAds;

  const DataSharingSettings({
    this.shareProfileWithPartners = false,
    this.shareActivityWithFriends = true,
    this.shareLocationData = false,
    this.allowDataAnalytics = true,
    this.allowPersonalizedAds = false,
  });

  factory DataSharingSettings.fromJson(Map<String, dynamic> json) {
    return DataSharingSettings(
      shareProfileWithPartners: json['share_profile_with_partners'] as bool,
      shareActivityWithFriends: json['share_activity_with_friends'] as bool,
      shareLocationData: json['share_location_data'] as bool,
      allowDataAnalytics: json['allow_data_analytics'] as bool,
      allowPersonalizedAds: json['allow_personalized_ads'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'share_profile_with_partners': shareProfileWithPartners,
      'share_activity_with_friends': shareActivityWithFriends,
      'share_location_data': shareLocationData,
      'allow_data_analytics': allowDataAnalytics,
      'allow_personalized_ads': allowPersonalizedAds,
    };
  }

  @override
  List<Object> get props => [
        shareProfileWithPartners,
        shareActivityWithFriends,
        shareLocationData,
        allowDataAnalytics,
        allowPersonalizedAds,
      ];
}

class MessageSettings extends Equatable {
  final bool allowMessagesFromEveryone;
  final bool allowMessagesFromFriends;
  final bool allowMessagesFromFollowers;
  final bool allowMessageRequests;

  const MessageSettings({
    this.allowMessagesFromEveryone = false,
    this.allowMessagesFromFriends = true,
    this.allowMessagesFromFollowers = true,
    this.allowMessageRequests = true,
  });

  factory MessageSettings.fromJson(Map<String, dynamic> json) {
    return MessageSettings(
      allowMessagesFromEveryone: json['allow_messages_from_everyone'] as bool,
      allowMessagesFromFriends: json['allow_messages_from_friends'] as bool,
      allowMessagesFromFollowers: json['allow_messages_from_followers'] as bool,
      allowMessageRequests: json['allow_message_requests'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allow_messages_from_everyone': allowMessagesFromEveryone,
      'allow_messages_from_friends': allowMessagesFromFriends,
      'allow_messages_from_followers': allowMessagesFromFollowers,
      'allow_message_requests': allowMessageRequests,
    };
  }

  @override
  List<Object> get props => [
        allowMessagesFromEveryone,
        allowMessagesFromFriends,
        allowMessagesFromFollowers,
        allowMessageRequests,
      ];
}

class ActivitySettings extends Equatable {
  final bool showOnlineStatus;
  final bool showActivityStatus;
  final bool showLastSeen;
  final bool allowReadReceipts;
  final bool allowTypingIndicators;

  const ActivitySettings({
    this.showOnlineStatus = true,
    this.showActivityStatus = true,
    this.showLastSeen = true,
    this.allowReadReceipts = true,
    this.allowTypingIndicators = true,
  });

  factory ActivitySettings.fromJson(Map<String, dynamic> json) {
    return ActivitySettings(
      showOnlineStatus: json['show_online_status'] as bool,
      showActivityStatus: json['show_activity_status'] as bool,
      showLastSeen: json['show_last_seen'] as bool,
      allowReadReceipts: json['allow_read_receipts'] as bool,
      allowTypingIndicators: json['allow_typing_indicators'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'show_online_status': showOnlineStatus,
      'show_activity_status': showActivityStatus,
      'show_last_seen': showLastSeen,
      'allow_read_receipts': allowReadReceipts,
      'allow_typing_indicators': allowTypingIndicators,
    };
  }

  @override
  List<Object> get props => [
        showOnlineStatus,
        showActivityStatus,
        showLastSeen,
        allowReadReceipts,
        allowTypingIndicators,
      ];
}

enum SearchVisibility {
  everyone,
  friendsOnly,
  none,
}