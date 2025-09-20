import 'package:json_annotation/json_annotation.dart';

part 'content.g.dart';

@JsonSerializable()
enum ContentStatus {
  draft,
  review,
  scheduled,
  published,
  archived,
}

@JsonSerializable()
class Content {
  final String id;
  final String title;
  final String description;
  final String body;
  final ContentStatus status;
  final String authorId;
  final String? categoryId;
  final List<String> tags;
  final List<MediaAsset> mediaAssets;
  final PublishSettings publishSettings;
  final ContentMetadata metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final DateTime? scheduledAt;
  final List<ContentVersion> versions;
  final List<ApprovalRequest> approvalRequests;
  final AnalyticsData analytics;

  Content({
    required this.id,
    required this.title,
    required this.description,
    required this.body,
    required this.status,
    required this.authorId,
    this.categoryId,
    required this.tags,
    required this.mediaAssets,
    required this.publishSettings,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.scheduledAt,
    required this.versions,
    required this.approvalRequests,
    required this.analytics,
  });

  factory Content.fromJson(Map<String, dynamic> json) => _$ContentFromJson(json);
  Map<String, dynamic> toJson() => _$ContentToJson(this);

  Content copyWith({
    String? id,
    String? title,
    String? description,
    String? body,
    ContentStatus? status,
    String? authorId,
    String? categoryId,
    List<String>? tags,
    List<MediaAsset>? mediaAssets,
    PublishSettings? publishSettings,
    ContentMetadata? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    DateTime? scheduledAt,
    List<ContentVersion>? versions,
    List<ApprovalRequest>? approvalRequests,
    AnalyticsData? analytics,
  }) {
    return Content(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      body: body ?? this.body,
      status: status ?? this.status,
      authorId: authorId ?? this.authorId,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      mediaAssets: mediaAssets ?? this.mediaAssets,
      publishSettings: publishSettings ?? this.publishSettings,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      versions: versions ?? this.versions,
      approvalRequests: approvalRequests ?? this.approvalRequests,
      analytics: analytics ?? this.analytics,
    );
  }

  bool get isDraft => status == ContentStatus.draft;
  bool get isInReview => status == ContentStatus.review;
  bool get isScheduled => status == ContentStatus.scheduled;
  bool get isPublished => status == ContentStatus.published;
  bool get isArchived => status == ContentStatus.archived;
}

@JsonSerializable()
class MediaAsset {
  final String id;
  final String url;
  final String type; // 'image', 'video', 'audio', 'document'
  final String? filename;
  final int size;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  MediaAsset({
    required this.id,
    required this.url,
    required this.type,
    this.filename,
    required this.size,
    this.metadata,
    required this.createdAt,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) => _$MediaAssetFromJson(json);
  Map<String, dynamic> toJson() => _$MediaAssetToJson(this);
}

@JsonSerializable()
class PublishSettings {
  final bool isPublic;
  final bool allowComments;
  final bool allowSharing;
  final DateTime? publishAt;
  final DateTime? expireAt;
  final List<String> targetPlatforms;
  final Map<String, dynamic>? platformSettings;
  final Map<String, dynamic>? seoSettings;

  PublishSettings({
    required this.isPublic,
    required this.allowComments,
    required this.allowSharing,
    this.publishAt,
    this.expireAt,
    required this.targetPlatforms,
    this.platformSettings,
    this.seoSettings,
  });

  factory PublishSettings.fromJson(Map<String, dynamic> json) => _$PublishSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$PublishSettingsToJson(this);
}

@JsonSerializable()
class ContentMetadata {
  final String? featuredImage;
  final String? excerpt;
  final int estimatedReadTime;
  final int wordCount;
  final Map<String, dynamic>? customFields;
  final Map<String, dynamic>? seo;

  ContentMetadata({
    this.featuredImage,
    this.excerpt,
    required this.estimatedReadTime,
    required this.wordCount,
    this.customFields,
    this.seo,
  });

  factory ContentMetadata.fromJson(Map<String, dynamic> json) => _$ContentMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$ContentMetadataToJson(this);
}

@JsonSerializable()
class ContentVersion {
  final String id;
  final int versionNumber;
  final String title;
  final String description;
  final String body;
  final String authorId;
  final DateTime createdAt;
  final String? changeLog;

  ContentVersion({
    required this.id,
    required this.versionNumber,
    required this.title,
    required this.description,
    required this.body,
    required this.authorId,
    required this.createdAt,
    this.changeLog,
  });

  factory ContentVersion.fromJson(Map<String, dynamic> json) => _$ContentVersionFromJson(json);
  Map<String, dynamic> toJson() => _$ContentVersionToJson(this);
}

@JsonSerializable()
class ApprovalRequest {
  final String id;
  final String contentId;
  final String requestedBy;
  final String requestedTo;
  final String? message;
  final ApprovalStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? responseMessage;

  ApprovalRequest({
    required this.id,
    required this.contentId,
    required this.requestedBy,
    required this.requestedTo,
    this.message,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.responseMessage,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) => _$ApprovalRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ApprovalRequestToJson(this);
}

@JsonSerializable()
enum ApprovalStatus {
  pending,
  approved,
  rejected,
}

@JsonSerializable()
class AnalyticsData {
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final double engagementRate;
  final Map<String, int> platformViews;
  final Map<String, dynamic>? customMetrics;

  AnalyticsData({
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.engagementRate,
    required this.platformViews,
    this.customMetrics,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) => _$AnalyticsDataFromJson(json);
  Map<String, dynamic> toJson() => _$AnalyticsDataToJson(this);
}

@JsonSerializable()
class PublishingTemplate {
  final String id;
  final String name;
  final String description;
  final PublishSettings settings;
  final ContentMetadata? defaultMetadata;
  final List<String> tags;
  final bool isSystemTemplate;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  PublishingTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.settings,
    this.defaultMetadata,
    required this.tags,
    required this.isSystemTemplate,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PublishingTemplate.fromJson(Map<String, dynamic> json) => _$PublishingTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$PublishingTemplateToJson(this);
}