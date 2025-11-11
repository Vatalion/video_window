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
}

enum FeedAlgorithm {
  trending,
  personalized,
  newest,
  following,
}
