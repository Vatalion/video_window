import 'package:equatable/equatable.dart';

class DistributionChannel extends Equatable {
  final String id;
  final String name;
  final String platform;
  final String? apiKey;
  final String? apiSecret;
  final Map<String, dynamic> settings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DistributionChannel({
    required this.id,
    required this.name,
    required this.platform,
    this.apiKey,
    this.apiSecret,
    required this.settings,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  DistributionChannel copyWith({
    String? id,
    String? name,
    String? platform,
    String? apiKey,
    String? apiSecret,
    Map<String, dynamic>? settings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DistributionChannel(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      apiKey: apiKey ?? this.apiKey,
      apiSecret: apiSecret ?? this.apiSecret,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        platform,
        apiKey,
        apiSecret,
        settings,
        isActive,
        createdAt,
        updatedAt,
      ];
}

class DistributionSettings extends Equatable {
  final String channelId;
  final String contentId;
  final Map<String, dynamic> platformSpecificSettings;
  final DateTime? scheduledTime;
  final String? customCaption;
  final List<String> hashtags;
  final bool optimizeForPlatform;

  const DistributionSettings({
    required this.channelId,
    required this.contentId,
    required this.platformSpecificSettings,
    this.scheduledTime,
    this.customCaption,
    required this.hashtags,
    required this.optimizeForPlatform,
  });

  DistributionSettings copyWith({
    String? channelId,
    String? contentId,
    Map<String, dynamic>? platformSpecificSettings,
    DateTime? scheduledTime,
    String? customCaption,
    List<String>? hashtags,
    bool? optimizeForPlatform,
  }) {
    return DistributionSettings(
      channelId: channelId ?? this.channelId,
      contentId: contentId ?? this.contentId,
      platformSpecificSettings: platformSpecificSettings ?? this.platformSpecificSettings,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      customCaption: customCaption ?? this.customCaption,
      hashtags: hashtags ?? this.hashtags,
      optimizeForPlatform: optimizeForPlatform ?? this.optimizeForPlatform,
    );
  }

  @override
  List<Object?> get props => [
        channelId,
        contentId,
        platformSpecificSettings,
        scheduledTime,
        customCaption,
        hashtags,
        optimizeForPlatform,
      ];
}