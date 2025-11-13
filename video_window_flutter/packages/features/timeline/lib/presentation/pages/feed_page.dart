import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
ed_event.dart';
import '../bloc/feed_state.dart';
import '../widgets/video_feed_item.dart';
import '../widgets/infinite_scroll_footer.dart';
import '../../data/services/feed_analytics_events.dart';
import 'package:core/services/analytics_service.dart';
import 'package:core/config/app_config.dart';
import '../../data/services/video_preloader_service.dart';
import '../../data/services/network_aware_service.dart';
import '../../data/services/feed_performance_service.dart';
import '../../data/services/memory_monitor_service.dart';

/// TikTok-style vertical video feed page
/// PERF-001: Optimized ListView with 60fps scrolling performance
/// AC1, AC4: Vertical feed with smooth scrolling
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  late VideoPreloaderService _preloaderService;
  late NetworkAwareService _networkService;
  late FeedPerformanceService _performanceService;
  late MemoryMonitorService _memoryMonitor;
  AnalyticsService? _analyticsService;
  int _currentVideoIndex = 0;
  int _paginationRetryAttempt = 0;

  @override
  void initState() {
    super.initState();
    _preloaderService = VideoPreloaderService();
    _networkService = NetworkAwareService();
    _performanceService = FeedPerformanceService();
    _memoryMonitor = MemoryMonitorService();
    // Analytics service - optional, will be initialized if AppConfig available
    _initializeAnalytics();
    _performanceService.startMonitoring();
    _memoryMonitor.startMonitoring();
    _setupScrollListener();

    // AC5: Try to restore from cache if offline
    if (!_networkService.isConnected) {
      _tryOfflineReplay();
    } else {
      context.read<FeedBloc>().add(const FeedLoadInitial());
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // AC2: Load next page when near bottom
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final threshold = maxScroll * 0.8; // Load when 80% scrolled

      if (currentScroll >= threshold) {
        // Debounce to prevent multiple rapid calls
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          context.read<FeedBloc>().add(const FeedLoadNextPage());
        });
      }

      // PERF-003: Prefetch videos when scrolling with quality adaptation
      final state = context.read<FeedBloc>().state;
      if (state is FeedLoaded && _networkService.shouldPrefetch()) {
        final newIndex = (_scrollController.position.pixels /
                MediaQuery.of(context).size.height)
            .round();
        if (newIndex != _currentVideoIndex) {
          _currentVideoIndex = newIndex;
          // PERF-003: Select quality based on network (Wi-Fi = high, mobile = low)
          final quality = _networkService.isWifi ? 'high' : 'low';
          _preloaderService.preloadVideos(state.videos, _currentVideoIndex,
              quality: quality);
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _preloaderService.dispose();
    _networkService.dispose();
    _performanceService.stopMonitoring();
    _memoryMonitor.dispose();
    super.dispose();
  }

  /// AC5: Try to replay cached videos when offline
  Future<void> _tryOfflineReplay() async {
    try {
      // This would use FeedCacheRepository to restore cached videos
      // For now, just load initial feed - offline replay will be handled
      // by FetchFeedPageUseCase when it tries cache fallback
      context.read<FeedBloc>().add(const FeedLoadInitial());
    } catch (e) {
      // If offline replay fails, show error state
    }
  }

  /// Initialize analytics service if AppConfig is available
  Future<void> _initializeAnalytics() async {
    try {
      // Try to load AppConfig - if not available, analytics will be null (graceful degradation)
      // This allows the app to work even if analytics service is not configured
      // ignore: avoid_dynamic_calls
      final appConfig = await AppConfig.load();
      _analyticsService = AnalyticsService(appConfig);
    } catch (e) {
      // Analytics service unavailable - app continues without tracking
      _analyticsService = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<FeedBloc, FeedState>(
        builder: (context, state) {
          if (state is FeedLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (state is FeedError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<FeedBloc>().add(const FeedRefresh());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is FeedLoaded) {
            // PERF-001: Use BlocSelector to prevent unnecessary rebuilds
            return BlocSelector<FeedBloc, FeedState, FeedLoaded>(
              selector: (state) => state is FeedLoaded
                  ? state
                  : throw StateError('Expected FeedLoaded'),
              builder: (context, loadedState) {
                if (loadedState.videos.isEmpty) {
                  return const Center(
                    child: Text(
                      'No videos available',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<FeedBloc>().add(const FeedRefresh());
                    // Wait for state update
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    // PERF-001: Fixed itemExtent for optimal performance
                    itemExtent: MediaQuery.of(context).size.height,
                    // PERF-001: Proper cacheExtent for prefetching
                    cacheExtent: MediaQuery.of(context).size.height * 2,
                    // PERF-001: Use addAutomaticKeepAlives for video players
                    addAutomaticKeepAlives: true,
                    addRepaintBoundaries: true,
                    itemCount: loadedState.videos.length +
                        (loadedState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show footer when at end
                      if (index == loadedState.videos.length) {
                        // AC3: Show appropriate footer state
                        if (loadedState.paginationError != null) {
                          return InfiniteScrollFooter(
                            state: InfiniteScrollFooterState.error,
                            errorMessage: loadedState.paginationError,
                            onRetry: () {
                              _paginationRetryAttempt++;
                              // AC3: Track retry analytics event
                              _analyticsService?.trackEvent(
                                FeedPaginationRetryEvent(
                                  cursor: loadedState.nextCursor,
                                  attempt: _paginationRetryAttempt,
                                ),
                              );
                              context.read<FeedBloc>().add(
                                    const FeedRetryPagination(),
                                  );
                            },
                          );
                        } else if (!loadedState.hasMore) {
                          return const InfiniteScrollFooter(
                            state: InfiniteScrollFooterState.endOfFeed,
                          );
                        } else {
                          return const InfiniteScrollFooter(
                            state: InfiniteScrollFooterState.loading,
                          );
                        }
                      }

                      final video = loadedState.videos[index];
                      final isPlaying =
                          loadedState.videoPlaybackStates[video.id] ?? false;
                      final isVisible =
                          loadedState.currentVisibleVideoId == video.id;

                      return Hero(
                        // UI/UX: Smooth page transitions with Hero animations
                        tag: 'video_${video.id}',
                        child: VideoFeedItem(
                          key: ValueKey(video.id), // PERF-001: Proper keys
                          video: video,
                          isPlaying: isPlaying && isVisible,
                          onVisibilityChanged: (isVisible, percentage) {
                            context.read<FeedBloc>().add(
                                  FeedVideoVisibilityChanged(
                                    videoId: video.id,
                                    isVisible: isVisible,
                                    visibilityPercentage: percentage,
                                  ),
                                );
                          },
                          onInteraction: (type, watchTime, metadata) {
                            context.read<FeedBloc>().add(
                                  FeedVideoInteraction(
                                    videoId: video.id,
                                    type: type,
                                    watchTime: watchTime,
                                    metadata: metadata,
                                  ),
                                );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
