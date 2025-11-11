import 'package:equatable/equatable.dart';

/// Story entity representing a complete story with all sections
class ArtifactStory extends Equatable {
  final String id;
  final String makerId;
  final String title;
  final String description;
  final String? categoryId;
  final StorySection overview;
  final StorySection? process;
  final StorySection? materials;
  final StorySection? notes;
  final StorySection? location;
  final MediaReference heroVideo;
  final List<MediaReference> gallery;
  final StoryStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ArtifactStory({
    required this.id,
    required this.makerId,
    required this.title,
    required this.description,
    this.categoryId,
    required this.overview,
    this.process,
    this.materials,
    this.notes,
    this.location,
    required this.heroVideo,
    this.gallery = const [],
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        makerId,
        title,
        description,
        categoryId,
        overview,
        process,
        materials,
        notes,
        location,
        heroVideo,
        gallery,
        status,
        createdAt,
        updatedAt,
      ];
}

/// Story section entity with flexible content structure
class StorySection extends Equatable {
  final String type; // overview, process, materials, notes, location
  final String title;
  final dynamic content; // Flexible content structure based on type
  final Map<String, dynamic> metadata;

  const StorySection({
    required this.type,
    required this.title,
    required this.content,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [type, title, content, metadata];
}

/// Media reference entity
class MediaReference extends Equatable {
  final String id;
  final String type; // video, image, caption_track, transcript
  final String url;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const MediaReference({
    required this.id,
    required this.type,
    required this.url,
    this.metadata = const {},
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, type, url, metadata, createdAt];
}

/// Story status enum
enum StoryStatus {
  draft,
  submitted,
  approved,
  published,
  archived,
}
