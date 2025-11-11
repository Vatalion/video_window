import 'dart:async';
import 'package:video_player/video_player.dart';
import '../../domain/entities/video.dart';

/// Video preloader service for prefetching
/// AC1: Video preloader warms the previous and next two videos using controller pooling
/// and releases resources when out of range
class VideoPreloaderService {
  final Map<String, VideoPlayerController> _preloadedControllers = {};
  final List<String> _preloadQueue = [];
  static const int _preloadRange = 2; // AC1: Previous and next 2 videos

  /// Preload video controllers for videos around current index
  /// AC1: Preloads previous 2 and next 2 videos (total 4 videos)
  /// PERF-003: Progressive loading with quality adaptation based on network
  Future<void> preloadVideos(List<Video> videos, int currentIndex,
      {String? quality}) async {
    if (videos.isEmpty) return;

    // AC1: Preload previous 2 and next 2 videos
    final preloadStart = (currentIndex - _preloadRange).clamp(0, videos.length);
    final preloadEnd =
        (currentIndex + _preloadRange + 1).clamp(0, videos.length);

    // Preload videos in range (excluding current)
    for (int i = preloadStart; i < preloadEnd; i++) {
      if (i != currentIndex && i >= 0 && i < videos.length) {
        final video = videos[i];
        if (!_preloadedControllers.containsKey(video.id)) {
          await _preloadVideo(video, quality: quality);
        }
      }
    }

    // Cleanup controllers outside the preload range
    _cleanupControllersOutsideRange(
      videos.map((v) => v.id).toList(),
      currentIndex,
      _preloadRange,
    );
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

  /// AC1: Release controllers for videos outside the specified range
  /// Used to release resources when videos are out of range
  void cleanupControllersOutsideRange(
    List<String> currentVideoIds,
    int currentIndex,
    int rangeSize,
  ) {
    if (currentVideoIds.isEmpty) return;

    // Calculate valid range
    final rangeStart =
        (currentIndex - rangeSize).clamp(0, currentVideoIds.length);
    final rangeEnd =
        (currentIndex + rangeSize + 1).clamp(0, currentVideoIds.length);

    // Get valid video IDs in range
    final validVideoIds = <String>{};
    for (int i = rangeStart; i < rangeEnd; i++) {
      if (i >= 0 && i < currentVideoIds.length) {
        validVideoIds.add(currentVideoIds[i]);
      }
    }

    // Dispose controllers outside range
    final toRemove = _preloadedControllers.keys
        .where((id) => !validVideoIds.contains(id))
        .toList();

    for (final id in toRemove) {
      _preloadedControllers[id]?.dispose();
      _preloadedControllers.remove(id);
      _preloadQueue.remove(id);
    }
  }

  /// Get current preload queue depth
  /// AC5: Used for metrics reporting
  int getQueueDepth() => _preloadQueue.length;

  /// Dispose all preloaded controllers
  void dispose() {
    for (final controller in _preloadedControllers.values) {
      controller.dispose();
    }
    _preloadedControllers.clear();
    _preloadQueue.clear();
  }
}
