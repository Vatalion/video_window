import 'package:equatable/equatable.dart';

/// Video interaction entity for analytics
class VideoInteraction extends Equatable {
  final String id;
  final String userId;
  final String videoId;
  final InteractionType type;
  final Duration? watchTime;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const VideoInteraction({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.type,
    this.watchTime,
    required this.timestamp,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        videoId,
        type,
        watchTime,
        timestamp,
        metadata,
      ];
}

enum InteractionType {
  view,
  like,
  share,
  comment,
  follow,
  complete,
  skip,
}
