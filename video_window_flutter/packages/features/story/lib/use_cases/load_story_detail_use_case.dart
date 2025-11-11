import '../../domain/entities/story.dart';

/// Use case to load story detail
/// AC1: Load complete story with all sections
class LoadStoryDetailUseCase {
  // In a real implementation, this would use a repository
  // For now, this is a placeholder that would be injected

  Future<ArtifactStory> execute(String storyId) async {
    // Placeholder implementation
    // Real implementation would call repository to fetch from Serverpod
    throw UnimplementedError('LoadStoryDetailUseCase.execute');
  }
}
