import '../../domain/entities/video_player_state.dart';

/// Use case to play video with signed URL
/// AC2, AC4: Secure video playback with content protection
class PlayVideoUseCase {
  Future<String> execute({
    required String mediaId,
    required VideoQuality quality,
    required String userId,
  }) async {
    // Placeholder implementation
    // Real implementation would call media token service to get signed URL
    throw UnimplementedError('PlayVideoUseCase.execute');
  }
}
