import 'package:equatable/equatable.dart';

class AnalyticsData extends Equatable {
  final String contentId;
  final int views;
  final int likes;
  final int shares;
  final int comments;
  final double engagementRate;
  final List<PlatformMetrics> platformMetrics;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnalyticsData({
    required this.contentId,
    required this.views,
    required this.likes,
    required this.shares,
    required this.comments,
    required this.engagementRate,
    required this.platformMetrics,
    required this.createdAt,
    required this.updatedAt,
  });

  AnalyticsData copyWith({
    String? contentId,
    int? views,
    int? likes,
    int? shares,
    int? comments,
    double? engagementRate,
    List<PlatformMetrics>? platformMetrics,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnalyticsData(
      contentId: contentId ?? this.contentId,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      shares: shares ?? this.shares,
      comments: comments ?? this.comments,
      engagementRate: engagementRate ?? this.engagementRate,
      platformMetrics: platformMetrics ?? this.platformMetrics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        contentId,
        views,
        likes,
        shares,
        comments,
        engagementRate,
        platformMetrics,
        createdAt,
        updatedAt,
      ];
}

class PlatformMetrics extends Equatable {
  final String platform;
  final int views;
  final int likes;
  final int shares;
  final int comments;
  final double engagementRate;

  const PlatformMetrics({
    required this.platform,
    required this.views,
    required this.likes,
    required this.shares,
    required this.comments,
    required this.engagementRate,
  });

  PlatformMetrics copyWith({
    String? platform,
    int? views,
    int? likes,
    int? shares,
    int? comments,
    double? engagementRate,
  }) {
    return PlatformMetrics(
      platform: platform ?? this.platform,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      shares: shares ?? this.shares,
      comments: comments ?? this.comments,
      engagementRate: engagementRate ?? this.engagementRate,
    );
  }

  @override
  List<Object?> get props => [
        platform,
        views,
        likes,
        shares,
        comments,
        engagementRate,
      ];
}