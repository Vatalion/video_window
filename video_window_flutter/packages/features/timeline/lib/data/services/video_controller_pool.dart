import 'package:video_player/video_player.dart';
import '../../domain/entities/video.dart';

/// Video controller pool for memory optimization
/// PERF-002, PERF-005: Controller pooling to prevent memory leaks
class VideoControllerPool {
  final Map<String, VideoPlayerController> _pool = {};
  final List<String> _accessOrder = [];
  static const int _maxPoolSize = 5;

  /// Get controller from pool or create new one
  Future<VideoPlayerController> getController(Video video) async {
    // Check if controller exists in pool
    if (_pool.containsKey(video.id)) {
      _updateAccessOrder(video.id);
      return _pool[video.id]!;
    }

    // Create new controller
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(video.videoUrl),
    );
    await controller.initialize();

    // Add to pool
    _pool[video.id] = controller;
    _updateAccessOrder(video.id);

    // Evict oldest if pool exceeds limit
    if (_pool.length > _maxPoolSize) {
      final oldest = _accessOrder.removeAt(0);
      _pool[oldest]?.dispose();
      _pool.remove(oldest);
    }

    return controller;
  }

  /// Release controller (keep in pool for reuse)
  void releaseController(String videoId) {
    // Controller stays in pool for potential reuse
    // Only dispose if explicitly requested
  }

  /// Dispose all controllers
  void dispose() {
    for (final controller in _pool.values) {
      controller.dispose();
    }
    _pool.clear();
    _accessOrder.clear();
  }

  void _updateAccessOrder(String videoId) {
    _accessOrder.remove(videoId);
    _accessOrder.add(videoId);
  }
}
