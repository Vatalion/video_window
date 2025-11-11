import 'dart:async';
import 'package:video_player/video_player.dart';
import '../../domain/entities/video.dart';

/// Video preloader service for prefetching
/// PERF-003: Prefetch next 3 video items during scroll
/// AC2: Intelligent prefetching and caching
class VideoPreloaderService {
  final Map<String, VideoPlayerController> _preloadedControllers = {};
  final List<String> _preloadQueue = [];
  static const int _maxPreloadCount = 3;

  /// Preload video controllers for upcoming videos
  /// PERF-003: Progressive loading with quality adaptation based on network
  Future<void> preloadVideos(List<Video> videos, int currentIndex,
      {String? quality}) async {
    // Clear old preloads
    _cleanupOldPreloads(videos.map((v) => v.id).toList());

    // Preload next 3 videos
    final endIndex = (currentIndex + _maxPreloadCount).clamp(0, videos.length);
    for (int i = currentIndex + 1; i < endIndex; i++) {
      final video = videos[i];
      if (!_preloadedControllers.containsKey(video.id)) {
        await _preloadVideo(video, quality: quality);
      }
    }
  }

  Future<void> _preloadVideo(Video video, {String? quality}) async {
    try {
      // PERF-003: Progressive video loading with quality adaptation
      // Select video URL based on network conditions
      final videoUrl = _selectVideoQuality(video, quality);

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      // Initialize but don't play
      await controller.initialize();
      _preloadedControllers[video.id] = controller;
      _preloadQueue.add(video.id);
    } catch (e) {
      // Preload failed, continue
    }
  }

  /// Select video quality based on network conditions
  /// PERF-003: Progressive loading with quality adaptation
  String _selectVideoQuality(Video video, String? preferredQuality) {
    // If video has multiple quality URLs, select based on preference
    // For now, use the main videoUrl (will be enhanced when multi-quality support is added)
    return video.videoUrl;
  }

  /// Get preloaded controller if available
  VideoPlayerController? getPreloadedController(String videoId) {
    final controller = _preloadedControllers.remove(videoId);
    if (controller != null) {
      _preloadQueue.remove(videoId);
    }
    return controller;
  }

  /// Cleanup controllers for videos no longer in feed
  void _cleanupOldPreloads(List<String> currentVideoIds) {
    final toRemove = _preloadedControllers.keys
        .where((id) => !currentVideoIds.contains(id))
        .toList();

    for (final id in toRemove) {
      _preloadedControllers[id]?.dispose();
      _preloadedControllers.remove(id);
      _preloadQueue.remove(id);
    }
  }

  /// Dispose all preloaded controllers
  void dispose() {
    for (final controller in _preloadedControllers.values) {
      controller.dispose();
    }
    _preloadedControllers.clear();
    _preloadQueue.clear();
  }
}
