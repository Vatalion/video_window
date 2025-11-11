import 'package:equatable/equatable.dart';
import 'video.dart';

/// Feed configuration for personalization
class FeedConfiguration extends Equatable {
  final String id;
  final String userId;
  final List<String> preferredTags;
  final List<String> blockedMakers;
  final VideoQuality preferredQuality;
  final bool autoPlay;
  final bool showCaptions;
  final double playbackSpeed;
  final FeedAlgorithm algorithm;
  final DateTime lastUpdated;

  const FeedConfiguration({
    required this.id,
    required this.userId,
    required this.preferredTags,
    required this.blockedMakers,
    required this.preferredQuality,
    required this.autoPlay,
    required this.showCaptions,
    required this.playbackSpeed,
    required this.algorithm,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        preferredTags,
        blockedMakers,
        preferredQuality,
        autoPlay,
        showCaptions,
        playbackSpeed,
        algorithm,
        lastUpdated,
      ];

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'preferredTags': preferredTags,
      'blockedMakers': blockedMakers,
      'preferredQuality': preferredQuality.name,
      'autoPlay': autoPlay,
      'showCaptions': showCaptions,
      'playbackSpeed': playbackSpeed,
      'algorithm': algorithm.name,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON
  factory FeedConfiguration.fromJson(Map<String, dynamic> json) {
    return FeedConfiguration(
      id: json['id'] as String,
      userId: json['userId'] as String,
      preferredTags: List<String>.from(json['preferredTags'] as List),
      blockedMakers: List<String>.from(json['blockedMakers'] as List),
      preferredQuality: VideoQuality.values.firstWhere(
        (q) => q.name == json['preferredQuality'] as String,
        orElse: () => VideoQuality.hd,
      ),
      autoPlay: json['autoPlay'] as bool,
      showCaptions: json['showCaptions'] as bool,
      playbackSpeed: (json['playbackSpeed'] as num).toDouble(),
      algorithm: FeedAlgorithm.values.firstWhere(
        (a) => a.name == json['algorithm'] as String,
        orElse: () => FeedAlgorithm.personalized,
      ),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

enum FeedAlgorithm {
  trending,
  personalized,
  newest,
  following,
}
