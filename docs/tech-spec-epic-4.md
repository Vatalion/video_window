# Epic 4: Feed Browsing Experience - Technical Specification

**Epic Goal:** Deliver a TikTok-style, high-performance video feed that enables smooth browsing, infinite scroll, and engaging content discovery while maintaining 60fps performance and minimal jank.

**Stories:**
- 4.1: TikTok-Style Video Feed Implementation
- 4.2: Infinite Scroll & Pagination
- 4.3: Video Preloading & Caching Strategy
- 4.4: Feed Performance Optimization (60fps, <2% jank)
- 4.5: Content Recommendation Engine Integration
- 4.6: Feed Personalization & User Preferences

## Architecture Overview

### Component Mapping
- **Flutter App:** Feed Module (video player widgets, infinite scroll, preloading)
- **Serverpod:** Content Service (video metadata, user preferences, recommendations)
- **Database:** Videos table, user_interactions table, feed_cache table
- **External:** CDN (video streaming), Image optimization service, Analytics

### Technology Stack
- **Flutter 3.19.6:** `video_player` 2.8.1, `cached_network_image` 3.3.1, `infinite_scroll_pagination` 4.0.0, `wakelock_plus` 1.2.5, `flutter_displaymode` 0.6.0, `visibility_detector` 0.4.2
- **Serverpod 2.9.2:** Feed and interaction endpoints in `video_window_server/lib/src/endpoints/feed/`
- **Streaming & CDN:** AWS S3 (us-east-1) bucket `video-window-feed-hls` fronted by CloudFront distribution `d3vw-feed.cloudfront.net` with signed cookies, media segments transcoded via AWS MediaConvert job template `vw-feed-hls-v1`
- **Caching & Storage:** Redis 7.2.4 cluster for feed cursors/prefetch state, PostgreSQL 15 for `videos`, `user_interactions`, `feed_cache` tables, CloudFront edge cache TTL 120s default
- **Analytics & Observability:** Segment SDK 4.5.1, Datadog RUM 1.13.0, Firebase Analytics 11.8.0, Sentry Flutter 8.7.0 for crash/perf monitoring
- **Recommendation Engine:** Serverpod module `recommendation` using LightFM 1.17 on Python microservice (versioned API v2025.9) accessed via gRPC proxy
- **Secrets Management:** 1Password Connect 1.7.3 vault `video-window-feed` for runtime credentials and API keys

### Source Tree & File Directives
```text
video_window_flutter/
  packages/
    features/
      timeline/
        lib/
          presentation/
            pages/
              feed_page.dart                         # Modify: integrate vertical pager + performance overlays (Story 4.1)
              feed_settings_sheet.dart               # Create: personalization controls (Story 4.6)
            widgets/
              video_feed_item.dart                   # Modify: hook preloader + analytics taps (Story 4.1)
              infinite_scroll_footer.dart            # Create: displays loading states (Story 4.2)
              preload_debug_overlay.dart             # Create: toggleable perf metrics HUD (Story 4.4)
          use_cases/
            fetch_feed_page_use_case.dart            # Modify: add cursor + personalization params (Story 4.2)
            preload_videos_use_case.dart             # Create: orchestrate video cache queue (Story 4.3)
            record_interaction_use_case.dart         # Modify: append recommendation signals (Story 4.5)
            update_feed_preferences_use_case.dart    # Create: persist personalization toggles (Story 4.6)
        test/
          presentation/
            pages/
              feed_page_test.dart                    # Modify: cover pagination + jank mitigation
              feed_settings_sheet_test.dart          # Create: ensures preference persistence
          widgets/
            video_feed_item_test.dart                # Modify: verifies preload + pause logic
            infinite_scroll_footer_test.dart         # Create: footer states
          use_cases/
            preload_videos_use_case_test.dart        # Create: cache limit + eviction behaviour

video_window_flutter/
  packages/
    core/
      lib/
        data/
          repositories/
            feed/
              feed_repository.dart                   # Modify: add gRPC recommendation + Redis hydration (Stories 4.2, 4.5)
              feed_cache_repository.dart             # Create: manage local cache + persistence (Story 4.3)
          services/
            analytics/feed_analytics_service.dart    # Modify: emit Segment + Datadog events (Story 4.1)
            performance/feed_performance_service.dart# Create: capture FPS/jank metrics via MethodChannel (Story 4.4)
      test/
        data/
          repositories/
            feed/
              feed_repository_test.dart              # Modify: ensure cursor + personalization coverage

video_window_server/
  lib/
    src/
      endpoints/
        feed/
          feed_endpoint.dart                         # Modify: paginate w/ cursor + personalization filters (Story 4.2)
          interaction_endpoint.dart                  # Modify: stream interactions to recommendation service (Story 4.5)
      services/
        feed_service.dart                            # Modify: add caching + prefetch heuristics
        recommendation_bridge_service.dart           # Create: gRPC proxy to LightFM microservice
      cache/
        feed_cache_manager.dart                      # Create: Redis-backed suggestion cache (Story 4.3)
      metrics/
        feed_performance_sampler.dart                # Create: aggregates server latency for dashboards

infrastructure/
  terraform/
    feed_cdn.tf                                      # Create: CloudFront + S3 origin + signed cookie policy
    feed_redis.tf                                    # Create: Elasticache Redis cluster for feed cursors
  serverless/
    feed_prefetch_worker.ts                          # Create: schedules warm cache jobs via EventBridge
```

## Data Models

### Video Entity
```dart
class Video {
  final String id;
  final String makerId;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final Duration duration;
  final int viewCount;
  final int likeCount;
  final List<String> tags;
  final VideoQuality quality;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final VideoMetadata metadata;
}

class VideoMetadata {
  final int width;
  final int height;
  final String format;
  final double aspectRatio;
  final List<VideoQuality> availableQualities;
  final bool hasCaptions;
  final Duration? thumbnailTime;
}

enum VideoQuality {
  sd(360), hd(720), fhd(1080);

  const VideoQuality(this.height);
  final int height;
}
```

### Feed Configuration Entity
```dart
class FeedConfiguration {
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
}

enum FeedAlgorithm {
  trending,
  personalized,
  newest,
  following
}
```

### Video Interaction Entity
```dart
class VideoInteraction {
  final String id;
  final String userId;
  final String videoId;
  final InteractionType type;
  final Duration? watchTime;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
}

enum InteractionType {
  view,
  like,
  share,
  comment,
  follow,
  complete,
  skip
}
```

## API Endpoints

### Feed Endpoints
```
GET /feed/videos
GET /feed/videos/next-page
POST /feed/interactions
GET /feed/recommendations
PUT /feed/preferences
GET /feed/trending
```

### Endpoint Specifications

#### Get Feed Videos
```dart
// Request
{
  "userId": "user_id",
  "algorithm": "personalized",
  "limit": 20,
  "cursor": "optional_cursor",
  "videoIds": ["exclude_ids"],
  "tags": ["preferred_tags"]
}

// Response
{
  "videos": [Video],
  "nextCursor": "cursor_string",
  "hasMore": true,
  "feedId": "feed_session_id"
}
```

#### Record Video Interaction
```dart
// Request
{
  "userId": "user_id",
  "videoId": "video_id",
  "interaction": "view",
  "watchTime": 15.5,
  "metadata": {
    "completed": false,
    "skipReason": "swipe"
  }
}

// Response
{
  "success": true,
  "interactionId": "interaction_id"
}
```

## Implementation Details

### Implementation Guide
1. **Repository & Data Layer Prep**
  - Update `feed_repository.dart` to request pages via Serverpod with `cursor`, `feedSessionId`, and personalization parameters (preferred tags, blocked makers). Persist responses into `feed_cache_repository.dart` leveraging Hive box `feed_cache` capped at 100 MB. (Stories 4.1, 4.2)
  - Implement `feed_cache_repository.dart` eviction policy (LRU) and hydrate from Redis snapshot when cold-starting the app. (Story 4.3)
2. **Serverpod Endpoint Enhancements**
  - Extend `feed_endpoint.dart` to support cursor-based pagination, max page size 50, and fetch recommendations via `recommendation_bridge_service.dart`. Cache page payloads in Redis `feed:page:{userId}:{cursor}` with TTL 120 seconds. (Stories 4.2, 4.5)
  - Update `interaction_endpoint.dart` to stream watch metrics to Kafka topic `feed.interactions.v1` and trigger LightFM retraining job nightly. (Stories 4.1, 4.5)
3. **Preloading & Performance Services**
  - Create `preload_videos_use_case.dart` orchestrating warm-up of next/previous two videos using `VideoPreloader`. Integrate with `feed_performance_service.dart` capturing FPS/jank via `MethodChannel('com.videowindow/perf')`. (Stories 4.3, 4.4)
  - Implement `feed_prefetch_worker.ts` EventBridge job to pre-warm CloudFront cache for trending videos hourly. (Story 4.3)
4. **Flutter Presentation Layer**
  - Modify `feed_page.dart` to host `PageView` with BLoC-driven state, infinite scroll footer, and debug overlay toggled via long-press. (Stories 4.1, 4.4)
  - Add `feed_settings_sheet.dart` to surface personalization toggles, linking to `update_feed_preferences_use_case.dart` and persisting to Serverpod preferences. (Story 4.6)
5. **Recommendation & Personalization**
  - Implement `recommendation_bridge_service.dart` to call LightFM microservice over gRPC using service account `feed-rec-svc@video-window`. Handle fallback to trending feed when service unavailable. (Story 4.5)
  - Update analytics pipeline to capture `feed_video_viewed`, `feed_swipe`, `feed_like`, and feed session metrics via Segment + Datadog correlation IDs. (Stories 4.1, 4.5)
6. **Testing & Performance Validation**
  - Add unit tests for repositories, caching, and recommendation bridging with golden snapshots for personalization responses.
  - Create integration tests measuring pagination correctness, video preload queue length, and server latency budgets. Use automated performance test harness to assert 60fps/<2% jank thresholds as part of CI.

### Flutter Feed Module Structure

#### Video Feed Architecture
```dart
// Main feed widget with optimized performance
class VideoFeed extends StatefulWidget {
  const VideoFeed({super.key});

  @override
  State<VideoFeed> createState() => _VideoFeedState();
}

class _VideoFeedState extends State<VideoFeed> {
  late PageController _pageController;
  late VideoFeedBloc _feedBloc;
  int _currentIndex = 0;
  Timer? _interactionTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _feedBloc = context.read<VideoFeedBloc>();
    _setupScrollListener();
    _loadInitialVideos();
  }

  void _setupScrollListener() {
    _pageController.addListener(() {
      final newPage = (_pageController.page ?? 0).round();
      if (newPage != _currentIndex) {
        _handleVideoChange(_currentIndex, newPage);
        _currentIndex = newPage;
      }
    });
  }

  void _handleVideoChange(int previousIndex, int newIndex) {
    // Pause previous video
    _feedBloc.add(PauseVideo(videoIndex: previousIndex));

    // Play new video with preloading
    _feedBloc.add(PlayVideo(
      videoIndex: newIndex,
      autoPlay: true,
      preloadAdjacent: true,
    ));

    // Record interaction for analytics
    _recordVideoInteraction(previousIndex, 'skip');
    _recordVideoInteraction(newIndex, 'view');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _feedBloc,
      child: Scaffold(
        body: _buildFeedContent(),
      ),
    );
  }

  Widget _buildFeedContent() {
    return BlocBuilder<VideoFeedBloc, VideoFeedState>(
      builder: (context, state) {
        return state.when(
          initial: () => const LoadingIndicator(),
          loading: () => const LoadingIndicator(),
          loaded: _buildVideoPageView,
          error: (message) => FeedErrorWidget(
            message: message,
            onRetry: () => _feedBloc.add(LoadInitialFeed()),
          ),
        );
      },
    );
  }

  Widget _buildVideoPageView(VideoFeedLoaded state) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: state.videos.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.videos.length) {
          // Load more indicator
          return const LoadingIndicator();
        }

        final video = state.videos[index];
        return VideoFeedItem(
          key: ValueKey(video.id),
          video: video,
          isActive: index == _currentIndex,
          onVideoComplete: () => _handleVideoComplete(index),
          onInteraction: (type) => _recordVideoInteraction(index, type),
        );
      },
    );
  }
}
```

## Analytics & Observability

### Metrics
- `feed.performance.fps` (Datadog gauge) — collected every 15 seconds from `feed_performance_service.dart`; alert when <55 for 5 minutes.
- `feed.performance.jank` (Datadog gauge) — target <2%; critical alert at >3%.
- `feed.preload.queue_depth` (Datadog gauge) — expected 0–4; investigate >6 sustained.
- `feed.cache.hit_rate` (Datadog gauge) — computed hourly from `feed_cache_manager.dart`, target >80%.
- `feed.recommendation.fallback` (Datadog count) — monitor for spikes indicating LightFM outages.
- Firebase traces `feed_scroll_start`/`feed_scroll_end` capturing scroll latency buckets for Release builds.

### Analytics Events (Segment)
- `feed_video_viewed` — params: `videoId`, `position`, `algorithm`, `sessionId`, `preloaded`.
- `feed_swipe` — params: `direction`, `duration`, `completed`.
- `feed_page_loaded` — params: `cursor`, `loadTimeMs`, `cacheHit` (Story 4.2).
- `feed_preload_complete` — params: `queueDepth`, `latencyMs`, `networkType` (Story 4.3).
- `feed_recommendation_served` — params: `algorithm`, `score`, `experimentVariant` (Story 4.5).
- `feed_preferences_updated` — params: `changedFields`, `autoPlayEnabled`, `reducedMotion` (Story 4.6).
- `feed_pagination_retry` — params: `cursor`, `attempt` (Story 4.2).

### Dashboards & Alerts
- Datadog dashboard `Feed Experience` aggregates FPS, jank, cache hit-rate, fallback counts.
- Sentry release health dashboard monitors crash-free sessions for feed feature.
- Segment → Snowflake pipeline exports feed events hourly for analytics modeling.
- Slack channel `#alerts-feed` receives Datadog alerts for FPS, jank, and recommendation fallback thresholds.

#### Optimized Video Player Component
```dart
class VideoFeedItem extends StatefulWidget {
  final Video video;
  final bool isActive;
  final VoidCallback? onVideoComplete;
  final Function(String)? onInteraction;

  const VideoFeedItem({
    super.key,
    required this.video,
    required this.isActive,
    this.onVideoComplete,
    this.onInteraction,
  });

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isDisposed = false;
  Timer? _interactionTimer;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _initializePlayer();
    }
  }

  @override
  void didUpdateWidget(VideoFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _initializePlayer();
      } else {
        _pauseAndDispose();
      }
    }
  }

  Future<void> _initializePlayer() async {
    if (_isDisposed) return;

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
          webOptions: const VideoPlayerWebOptions(
            controls: VideoPlayerWebOptionsControls.enabled(),
          ),
        ),
      );

      await _controller!.initialize();

      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
        });

        _controller!.addListener(_videoListener);

        if (widget.isActive) {
          _controller!.play();
          _startInteractionTracking();
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize video player: $e');
    }
  }

  void _videoListener() {
    if (_controller == null || _isDisposed) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    if (position != _currentPosition) {
      _currentPosition = position;

      // Check if video completed
      if (duration != null && position >= duration) {
        widget.onVideoComplete?.call();
      }
    }
  }

  void _startInteractionTracking() {
    _interactionTimer?.cancel();
    _interactionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isDisposed) {
        _recordWatchTime();
      }
    });
  }

  void _recordWatchTime() {
    final position = _controller?.value.position ?? Duration.zero;
    widget.onInteraction?.call('watch_time_${position.inSeconds}');
  }

  void _pauseAndDispose() async {
    _interactionTimer?.cancel();

    if (_controller != null) {
      await _controller!.pause();
      _controller!.removeListener(_videoListener);

      if (_isDisposed) {
        await _controller!.dispose();
        _controller = null;
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pauseAndDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return VideoPlaceholder(
        thumbnailUrl: widget.video.thumbnailUrl,
        title: widget.video.title,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),

        // Gradient overlay for text visibility
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black26,
                Colors.transparent,
                Colors.black54,
              ],
            ),
          ),
        ),

        // Video controls and information
        VideoFeedOverlay(
          video: widget.video,
          controller: _controller!,
          isActive: widget.isActive,
          onInteraction: widget.onInteraction,
        ),
      ],
    );
  }
}
```

### Feed State Management (BLoC)

```dart
// Feed Events
abstract class VideoFeedEvent {}

class LoadInitialFeed extends VideoFeedEvent {
  final FeedAlgorithm algorithm;
  final List<String>? preferredTags;

  LoadInitialFeed({
    this.algorithm = FeedAlgorithm.personalized,
    this.preferredTags,
  });
}

class LoadNextPage extends VideoFeedEvent {
  final String cursor;
  final List<String> excludeVideoIds;

  LoadNextPage({
    required this.cursor,
    this.excludeVideoIds = const [],
  });
}

class PlayVideo extends VideoFeedEvent {
  final int videoIndex;
  final bool autoPlay;
  final bool preloadAdjacent;

  PlayVideo({
    required this.videoIndex,
    this.autoPlay = true,
    this.preloadAdjacent = true,
  });
}

class PauseVideo extends VideoFeedEvent {
  final int videoIndex;

  PauseVideo({required this.videoIndex});
}

class RecordInteraction extends VideoFeedEvent {
  final String videoId;
  final String interactionType;
  final Duration? watchTime;
  final Map<String, dynamic>? metadata;

  RecordInteraction({
    required this.videoId,
    required this.interactionType,
    this.watchTime,
    this.metadata,
  });
}

// Feed States
@freezed
class VideoFeedState with _$VideoFeedState {
  const factory VideoFeedState.initial() = _Initial;
  const factory VideoFeedState.loading() = _Loading;
  const factory VideoFeedState.loaded({
    required List<Video> videos,
    required String nextCursor,
    required bool hasMore,
    required String feedId,
    @Default(false) bool isLoadingMore,
  }) = _Loaded;
  const factory VideoFeedState.error(String message) = _Error;
}

// Feed BLoC Implementation
class VideoFeedBloc extends Bloc<VideoFeedEvent, VideoFeedState> {
  final GetVideosUseCase _getVideosUseCase;
  final RecordInteractionUseCase _recordInteractionUseCase;
  final VideoPreloader _preloader;

  String? _nextCursor;
  String? _feedId;

  VideoFeedBloc({
    required GetVideosUseCase getVideosUseCase,
    required RecordInteractionUseCase recordInteractionUseCase,
    required VideoPreloader preloader,
  }) : _getVideosUseCase = getVideosUseCase,
       _recordInteractionUseCase = recordInteractionUseCase,
       _preloader = preloader,
       super(const VideoFeedState.initial()) {

    on<LoadInitialFeed>(_onLoadInitialFeed);
    on<LoadNextPage>(_onLoadNextPage);
    on<PlayVideo>(_onPlayVideo);
    on<PauseVideo>(_onPauseVideo);
    on<RecordInteraction>(_onRecordInteraction);
  }

  Future<void> _onLoadInitialFeed(
    LoadInitialFeed event,
    Emitter<VideoFeedState> emit,
  ) async {
    emit(const VideoFeedState.loading());

    try {
      final result = await _getVideosUseCase.call(
        GetVideosParams(
          algorithm: event.algorithm,
          limit: 20,
          preferredTags: event.preferredTags,
        ),
      );

      result.fold(
        (failure) => emit(VideoFeedState.error(failure.message)),
        (response) {
          _nextCursor = response.nextCursor;
          _feedId = response.feedId;

          emit(VideoFeedState.loaded(
            videos: response.videos,
            nextCursor: response.nextCursor,
            hasMore: response.hasMore,
            feedId: response.feedId,
          ));

          // Preload first few videos
          _preloader.preloadVideos(response.videos.take(3).toList());
        },
      );
    } catch (e) {
      emit(VideoFeedState.error('Failed to load feed: $e'));
    }
  }

  Future<void> _onLoadNextPage(
    LoadNextPage event,
    Emitter<VideoFeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is! VideoFeedStateLoaded ||
        currentState.isLoadingMore ||
        _nextCursor == null) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final result = await _getVideosUseCase.call(
        GetVideosParams(
          cursor: _nextCursor,
          limit: 20,
          excludeVideoIds: event.excludeVideoIds,
        ),
      );

      result.fold(
        (failure) => emit(currentState.copyWith(isLoadingMore: false)),
        (response) {
          _nextCursor = response.nextCursor;

          final updatedVideos = [...currentState.videos, ...response.videos];

          emit(VideoFeedState.loaded(
            videos: updatedVideos,
            nextCursor: response.nextCursor,
            hasMore: response.hasMore,
            feedId: _feedId!,
            isLoadingMore: false,
          ));

          // Preload newly loaded videos
          _preloader.preloadVideos(response.videos.take(3).toList());
        },
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onPlayVideo(
    PlayVideo event,
    Emitter<VideoFeedState> emit,
  ) async {
    // Video playback is handled by individual video widgets
    // This event can be used for analytics and preloading
    if (event.preloadAdjacent) {
      _preloadAdjacentVideos(event.videoIndex);
    }
  }

  Future<void> _onPauseVideo(
    PauseVideo event,
    Emitter<VideoFeedState> emit,
  ) async {
    // Video pausing is handled by individual video widgets
    // This event can be used for analytics
  }

  Future<void> _onRecordInteraction(
    RecordInteraction event,
    Emitter<VideoFeedState> emit,
  ) async {
    try {
      await _recordInteractionUseCase.call(
        RecordInteractionParams(
          videoId: event.videoId,
          interactionType: event.interactionType,
          watchTime: event.watchTime,
          metadata: event.metadata,
        ),
      );
    } catch (e) {
      debugPrint('Failed to record interaction: $e');
    }
  }

  void _preloadAdjacentVideos(int currentIndex) {
    final currentState = state;
    if (currentState is! VideoFeedStateLoaded) return;

    // Preload next video
    if (currentIndex + 1 < currentState.videos.length) {
      _preloader.preloadVideo(currentState.videos[currentIndex + 1]);
    }

    // Preload video after next
    if (currentIndex + 2 < currentState.videos.length) {
      _preloader.preloadVideo(currentState.videos[currentIndex + 2]);
    }
  }
}
```

### Video Preloading & Caching System

```dart
class VideoPreloader {
  static const _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const _maxPreloadCount = 3;

  final Map<String, VideoPlayerController> _controllers = {};
  final Queue<String> _preloadQueue = Queue();
  final Map<String, int> _accessOrder = {};
  int _currentCacheSize = 0;
  Timer? _cleanupTimer;

  VideoPreloader() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) => _cleanupCache());
  }

  Future<void> preloadVideo(Video video) async {
    if (_controllers.containsKey(video.id)) {
      _updateAccessOrder(video.id);
      return;
    }

    if (_preloadQueue.length >= _maxPreloadCount) {
      return; // Queue is full
    }

    _preloadQueue.add(video.id);
    _processPreloadQueue();
  }

  Future<void> preloadVideos(List<Video> videos) async {
    for (final video in videos) {
      if (_controllers.length < _maxPreloadCount) {
        await preloadVideo(video);
      } else {
        break;
      }
    }
  }

  VideoPlayerController? getController(String videoId) {
    _updateAccessOrder(videoId);
    return _controllers[videoId];
  }

  void _updateAccessOrder(String videoId) {
    _accessOrder[videoId] = DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> _processPreloadQueue() async {
    while (_preloadQueue.isNotEmpty && _controllers.length < _maxPreloadCount) {
      final videoId = _preloadQueue.removeFirst();
      await _preloadSingleVideo(videoId);
    }
  }

  Future<void> _preloadSingleVideo(String videoId) async {
    try {
      // Get video URL from repository or cache
      final videoUrl = await _getVideoUrl(videoId);
      if (videoUrl == null) return;

      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      // Pre-initialize without playing
      await controller.initialize();

      _controllers[videoId] = controller;
      _updateAccessOrder(videoId);

      // Estimate cache size (rough approximation)
      _currentCacheSize += (100 * 1024); // 100KB per video controller estimate

      // If cache exceeds limit, remove oldest
      if (_currentCacheSize > _maxCacheSize) {
        _removeOldestController();
      }
    } catch (e) {
      debugPrint('Failed to preload video $videoId: $e');
    }
  }

  void _removeOldestController() {
    if (_accessOrder.isEmpty) return;

    final sortedEntries = _accessOrder.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final oldestVideoId = sortedEntries.first.key;
    final controller = _controllers.remove(oldestVideoId);

    controller?.dispose();
    _accessOrder.remove(oldestVideoId);

    // Update cache size estimate
    _currentCacheSize = (_currentCacheSize - (100 * 1024)).clamp(0, _maxCacheSize);
  }

  void _cleanupCache() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final maxAge = 10 * 60 * 1000; // 10 minutes

    final toRemove = <String>[];

    for (final entry in _accessOrder.entries) {
      if (now - entry.value > maxAge) {
        toRemove.add(entry.key);
      }
    }

    for (final videoId in toRemove) {
      final controller = _controllers.remove(videoId);
      controller?.dispose();
      _accessOrder.remove(videoId);
    }
  }

  Future<String?> _getVideoUrl(String videoId) async {
    // Implementation would fetch video URL from repository
    // This is a placeholder for the actual implementation
    return null;
  }

  void dispose() {
    _cleanupTimer?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _accessOrder.clear();
    _preloadQueue.clear();
  }
}
```

### Performance Optimization Implementation

#### Frame Rate Monitoring
```dart
class PerformanceMonitor {
  static const _targetFrameRate = 60.0;
  static const _jankThreshold = 2.0; // 2% jank threshold

  final List<double> _frameTimes = [];
  Timer? _monitorTimer;
  int _lastFrameTime = 0;
  int _jankFrames = 0;
  int _totalFrames = 0;

  void startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _collectFrameMetrics();
    });
  }

  void _collectFrameMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_lastFrameTime > 0) {
        final frameTime = now - _lastFrameTime;
        _frameTimes.add(frameTime.toDouble());

        _totalFrames++;

        // Check for jank (frame time > 16.67ms for 60fps)
        if (frameTime > 16.67 * 1.5) {
          _jankFrames++;
        }

        // Keep only last 60 frame times (1 second of data)
        if (_frameTimes.length > 60) {
          _frameTimes.removeAt(0);
        }
      }
      _lastFrameTime = now;
    });
  }

  double get currentFps {
    if (_frameTimes.isEmpty) return 0.0;
    final avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    return avgFrameTime > 0 ? 1000.0 / avgFrameTime : 0.0;
  }

  double get jankPercentage {
    if (_totalFrames == 0) return 0.0;
    return (_jankFrames / _totalFrames) * 100;
  }

  bool get isPerformingWell {
    return currentFps >= _targetFrameRate && jankPercentage < _jankThreshold;
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    _frameTimes.clear();
    _totalFrames = 0;
    _jankFrames = 0;
  }
}
```

#### Optimized Infinite Scroll
```dart
class OptimizedInfiniteScroll extends StatefulWidget {
  final List<Video> videos;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext, Video, int) itemBuilder;

  const OptimizedInfiniteScroll({
    super.key,
    required this.videos,
    required this.hasMore,
    required this.onLoadMore,
    required this.itemBuilder,
    this.isLoadingMore = false,
  });

  @override
  State<OptimizedInfiniteScroll> createState() => _OptimizedInfiniteScrollState();
}

class _OptimizedInfiniteScrollState extends State<OptimizedInfiniteScroll> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.isLoadingMore && widget.hasMore) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final delta = 500.0; // Load more when 500px from bottom

      if (maxScroll - currentScroll <= delta) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: widget.videos.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.videos.length) {
          return widget.isLoadingMore
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox.shrink();
        }

        final video = widget.videos[index];
        _itemKeys[index] ??= GlobalKey();

        return RepaintBoundary(
          key: _itemKeys[index],
          child: widget.itemBuilder(context, video, index),
        );
      },
    );
  }
}
```

## Serverpod Feed Service Implementation

### Feed Service
```dart
class FeedService {
  final VideoRepository _videoRepository;
  final UserRepository _userRepository;
  final AnalyticsService _analyticsService;
  final RedisCache _cache;

  FeedService({
    required VideoRepository videoRepository,
    required UserRepository userRepository,
    required AnalyticsService analyticsService,
    required RedisCache cache,
  }) : _videoRepository = videoRepository,
       _userRepository = userRepository,
       _analyticsService = analyticsService,
       _cache = cache;

  Future<FeedResponse> getVideos(GetVideosParams params) async {
    // Try cache first
    final cacheKey = _generateCacheKey(params);
    final cachedResponse = await _cache.get(cacheKey);

    if (cachedResponse != null) {
      return FeedResponse.fromJson(jsonDecode(cachedResponse));
    }

    // Generate feed based on algorithm
    List<Video> videos;
    switch (params.algorithm) {
      case FeedAlgorithm.personalized:
        videos = await _getPersonalizedFeed(params);
        break;
      case FeedAlgorithm.trending:
        videos = await _getTrendingFeed(params);
        break;
      case FeedAlgorithm.newest:
        videos = await _getNewestFeed(params);
        break;
      case FeedAlgorithm.following:
        videos = await _getFollowingFeed(params);
        break;
    }

    final response = FeedResponse(
      videos: videos,
      nextCursor: _generateCursor(videos.last?.id),
      hasMore: videos.length == params.limit,
      feedId: _generateFeedId(),
    );

    // Cache for 5 minutes
    await _cache.set(
      cacheKey,
      jsonEncode(response.toJson()),
      ttl: Duration(minutes: 5),
    );

    return response;
  }

  Future<List<Video>> _getPersonalizedFeed(GetVideosParams params) async {
    // Get user preferences and interaction history
    final user = await _userRepository.findById(params.userId);
    final interactions = await _analyticsService.getUserInteractions(
      params.userId,
      limit: 100,
    );

    // Calculate user preferences based on interactions
    final preferredTags = _calculatePreferredTags(interactions);
    final preferredMakers = _calculatePreferredMakers(interactions);

    // Get videos matching preferences
    return await _videoRepository.findPersonalizedVideos(
      userId: params.userId,
      preferredTags: preferredTags,
      preferredMakers: preferredMakers,
      excludeVideoIds: params.excludeVideoIds,
      limit: params.limit,
      cursor: params.cursor,
    );
  }

  Future<List<Video>> _getTrendingFeed(GetVideosParams params) async {
    return await _videoRepository.findTrendingVideos(
      excludeVideoIds: params.excludeVideoIds,
      limit: params.limit,
      cursor: params.cursor,
      timeWindow: Duration(hours: 24),
    );
  }

  Future<List<Video>> _getNewestFeed(GetVideosParams params) async {
    return await _videoRepository.findNewestVideos(
      excludeVideoIds: params.excludeVideoIds,
      limit: params.limit,
      cursor: params.cursor,
    );
  }

  Future<List<Video>> _getFollowingFeed(GetVideosParams params) async {
    final followingMakers = await _userRepository.getFollowingMakers(params.userId);

    return await _videoRepository.findVideosByMakers(
      makerIds: followingMakers,
      excludeVideoIds: params.excludeVideoIds,
      limit: params.limit,
      cursor: params.cursor,
    );
  }

  Future<void> recordInteraction(RecordInteractionParams params) async {
    final interaction = VideoInteraction(
      id: generateId(),
      userId: params.userId,
      videoId: params.videoId,
      type: _parseInteractionType(params.interactionType),
      watchTime: params.watchTime,
      timestamp: DateTime.now(),
      metadata: params.metadata,
    );

    await _analyticsService.recordInteraction(interaction);

    // Update user preferences asynchronously
    unawaited(_updateUserPreferences(params.userId, interaction));
  }

  List<String> _calculatePreferredTags(List<UserInteraction> interactions) {
    final tagCounts = <String, int>{};

    for (final interaction in interactions) {
      if (interaction.video?.tags != null) {
        for (final tag in interaction.video!.tags) {
          final weight = _getInteractionWeight(interaction.type);
          tagCounts[tag] = (tagCounts[tag] ?? 0) + weight;
        }
      }
    }

    return tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(10)
      .map((e) => e.key)
      .toList();
  }

  int _getInteractionWeight(InteractionType type) {
    switch (type) {
      case InteractionType.complete:
        return 5;
      case InteractionType.like:
        return 3;
      case InteractionType.comment:
        return 4;
      case InteractionType.share:
        return 4;
      case InteractionType.follow:
        return 3;
      case InteractionType.view:
        return 1;
      case InteractionType.skip:
        return -1;
    }
  }
}
```

## Database Schema

### Videos Table
```sql
CREATE TABLE videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  maker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  video_url VARCHAR(500) NOT NULL,
  thumbnail_url VARCHAR(500) NOT NULL,
  duration_seconds INTEGER NOT NULL,
  view_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  tags JSONB DEFAULT '[]',
  quality VARCHAR(20) DEFAULT 'hd',
  metadata JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for feed performance
CREATE INDEX idx_videos_created_at ON videos(created_at DESC) WHERE is_active = true;
CREATE INDEX idx_videos_maker_id ON videos(maker_id) WHERE is_active = true;
CREATE INDEX idx_videos_tags ON videos USING GIN(tags) WHERE is_active = true;
CREATE INDEX idx_videos_popularity ON videos(view_count DESC, like_count DESC) WHERE is_active = true;
CREATE INDEX idx_videos_trending ON videos(created_at DESC, view_count DESC) WHERE is_active = true AND created_at >= NOW() - INTERVAL '24 hours';
```

### User Interactions Table
```sql
CREATE TABLE user_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
  interaction_type VARCHAR(50) NOT NULL,
  watch_time_seconds INTEGER,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for analytics and recommendations
CREATE INDEX idx_interactions_user_id ON user_interactions(user_id, created_at DESC);
CREATE INDEX idx_interactions_video_id ON user_interactions(video_id, created_at DESC);
CREATE INDEX idx_interactions_type ON user_interactions(interaction_type, created_at DESC);
CREATE INDEX idx_interactions_composite ON user_interactions(user_id, video_id, interaction_type, created_at DESC);
```

### Feed Cache Table
```sql
CREATE TABLE feed_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  algorithm VARCHAR(50) NOT NULL,
  video_ids UUID[] NOT NULL,
  cursor VARCHAR(255),
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_feed_cache_user ON feed_cache(user_id, algorithm, expires_at);
CREATE INDEX idx_feed_cache_expires ON feed_cache(expires_at);
```

## Performance Requirements and Monitoring

### Performance Targets
- **Frame Rate**: Maintain 60fps during scrolling and video playback
- **Jank**: Keep jank below 2% of all frames
- **Video Load Time**: Initial video playback within 2 seconds
- **Scroll Response**: UI response to scroll gestures within 16ms
- **Memory Usage**: Peak memory usage below 200MB
- **Battery Impact**: Less than 10% battery drain per hour of use

### Performance Monitoring Implementation
```dart
class FeedPerformanceMonitor {
  static final FeedPerformanceMonitor _instance = FeedPerformanceMonitor._internal();
  factory FeedPerformanceMonitor() => _instance;
  FeedPerformanceMonitor._internal();

  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final Map<String, Stopwatch> _timers = {};
  final List<PerformanceMetric> _metrics = [];

  void startMonitoring() {
    _performanceMonitor.startMonitoring();
  }

  void startTimer(String operation) {
    _timers[operation] = Stopwatch()..start();
  }

  void endTimer(String operation) {
    final timer = _timers[operation];
    if (timer != null) {
      timer.stop();
      _recordMetric(operation, timer.elapsedMilliseconds);
      timer.reset();
    }
  }

  void _recordMetric(String operation, int duration) {
    final metric = PerformanceMetric(
      operation: operation,
      duration: duration,
      timestamp: DateTime.now(),
      fps: _performanceMonitor.currentFps,
      jankPercentage: _performanceMonitor.jankPercentage,
    );

    _metrics.add(metric);

    // Keep only last 1000 metrics
    if (_metrics.length > 1000) {
      _metrics.removeAt(0);
    }

    // Check performance thresholds
    _checkPerformanceThresholds(metric);
  }

  void _checkPerformanceThresholds(PerformanceMetric metric) {
    if (metric.fps < 60) {
      debugPrint('⚠️ Low FPS detected: ${metric.fps.toStringAsFixed(1)}');
    }

    if (metric.jankPercentage > 2) {
      debugPrint('⚠️ High jank detected: ${metric.jankPercentage.toStringAsFixed(1)}%');
    }

    if (metric.duration > 100) {
      debugPrint('⚠️ Slow operation: ${metric.operation} took ${metric.duration}ms');
    }
  }

  Map<String, double> getAverageMetrics() {
    final operationTimes = <String, List<int>>{};

    for (final metric in _metrics) {
      operationTimes[metric.operation] ??= [];
      operationTimes[metric.operation]!.add(metric.duration);
    }

    return operationTimes.map((operation, times) {
      final average = times.isEmpty
          ? 0.0
          : times.reduce((a, b) => a + b) / times.length;
      return MapEntry(operation, average);
    });
  }

  void logPerformanceReport() {
    final avgMetrics = getAverageMetrics();
    final currentFps = _performanceMonitor.currentFps;
    final jankPercentage = _performanceMonitor.jankPercentage;

    debugPrint('=== Performance Report ===');
    debugPrint('Current FPS: ${currentFps.toStringAsFixed(1)}');
    debugPrint('Jank Percentage: ${jankPercentage.toStringAsFixed(2)}%');
    debugPrint('Average Operation Times:');

    for (final entry in avgMetrics.entries) {
      debugPrint('  ${entry.key}: ${entry.value.toStringAsFixed(1)}ms');
    }

    debugPrint('========================');
  }
}

class PerformanceMetric {
  final String operation;
  final int duration;
  final DateTime timestamp;
  final double fps;
  final double jankPercentage;

  PerformanceMetric({
    required this.operation,
    required this.duration,
    required this.timestamp,
    required this.fps,
    required this.jankPercentage,
  });
}
```

## Testing Strategy

### Unit Tests
```dart
void main() {
  group('VideoFeedBloc', () {
    late VideoFeedBloc feedBloc;
    late MockGetVideosUseCase mockGetVideosUseCase;
    late MockRecordInteractionUseCase mockRecordInteractionUseCase;
    late MockVideoPreloader mockPreloader;

    setUp(() {
      mockGetVideosUseCase = MockGetVideosUseCase();
      mockRecordInteractionUseCase = MockRecordInteractionUseCase();
      mockPreloader = MockVideoPreloader();

      feedBloc = VideoFeedBloc(
        getVideosUseCase: mockGetVideosUseCase,
        recordInteractionUseCase: mockRecordInteractionUseCase,
        preloader: mockPreloader,
      );
    });

    test('emits loaded state when initial feed loads successfully', () async {
      // Arrange
      final videos = [Video.test(), Video.test()];
      final response = FeedResponse(
        videos: videos,
        nextCursor: 'cursor',
        hasMore: true,
        feedId: 'feed_id',
      );

      when(mockGetVideosUseCase.call(any))
          .thenAnswer((_) async => Right(response));

      // Act
      feedBloc.add(LoadInitialFeed());

      // Assert
      expectLater(
        feedBloc.stream,
        emitsInOrder([
          VideoFeedState.loading(),
          VideoFeedState.loaded(
            videos: videos,
            nextCursor: 'cursor',
            hasMore: true,
            feedId: 'feed_id',
          ),
        ]),
      );
    });

    test('emits error state when feed loading fails', () async {
      // Arrange
      when(mockGetVideosUseCase.call(any))
          .thenAnswer((_) async => Left(FeedFailure.networkError()));

      // Act
      feedBloc.add(LoadInitialFeed());

      // Assert
      expectLater(
        feedBloc.stream,
        emitsInOrder([
          VideoFeedState.loading(),
          VideoFeedState.error('Network error'),
        ]),
      );
    });
  });

  group('VideoPreloader', () {
    late VideoPreloader preloader;

    setUp(() {
      preloader = VideoPreloader();
    });

    tearDown(() {
      preloader.dispose();
    });

    test('should preload video successfully', () async {
      // Arrange
      final video = Video.test();

      // Act
      await preloader.preloadVideo(video);

      // Assert
      expect(preloader.getController(video.id), isNotNull);
    });

    test('should limit preloaded videos to max count', () async {
      // Arrange
      final videos = List.generate(5, (_) => Video.test());

      // Act
      for (final video in videos) {
        await preloader.preloadVideo(video);
      }

      // Assert
      // Should only preload up to max count (3)
      expect(preloader.getController(videos[0].id), isNotNull);
      expect(preloader.getController(videos[1].id), isNotNull);
      expect(preloader.getController(videos[2].id), isNotNull);
    });
  });
}
```

### Integration Tests
```dart
void main() {
  group('Feed Integration Tests', () {
    testWidgets('should scroll through feed smoothly', (tester) async {
      // Arrange
      final mockVideos = List.generate(10, (i) => Video.test(id: 'video_$i'));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => MockVideoFeedBloc()..add(LoadInitialFeed()),
            child: VideoFeed(),
          ),
        ),
      );

      // Act & Assert - Scroll down
      await tester.fling(
        find.byType(PageView),
        const Offset(0, -500),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.byType(VideoFeedItem), findsWidgets);
    });

    testWidgets('should maintain 60fps during scrolling', (tester) async {
      // Arrange
      final performanceMonitor = FeedPerformanceMonitor();
      performanceMonitor.startMonitoring();

      await tester.pumpWidget(
        MaterialApp(
          home: VideoFeed(),
        ),
      );

      // Act - Perform rapid scrolling
      for (int i = 0; i < 10; i++) {
        await tester.fling(
          find.byType(PageView),
          const Offset(0, -200),
          500,
        );
        await tester.pump(Duration(milliseconds: 16)); // 60fps frame time
      }

      // Assert
      final avgFps = performanceMonitor.getAverageMetrics()['scrolling'] ?? 0;
      expect(avgFps, greaterThan(55)); // Allow some tolerance

      performanceMonitor.stopMonitoring();
    });

    testWidgets('should load more videos when reaching end', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: VideoFeed(),
        ),
      );

      // Act - Scroll to bottom
      await tester.drag(
        find.byType(PageView),
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();

      // Assert
      verify(mockLoadMoreUseCase.call(any)).called(greaterThan(0));
    });
  });

  group('Performance Tests', () {
    testWidgets('should meet memory usage targets', (tester) async {
      // Arrange
      final initialMemory = ProcessInfo.currentRss;

      await tester.pumpWidget(
        MaterialApp(
          home: VideoFeed(),
        ),
      );

      // Act - Scroll through many videos
      for (int i = 0; i < 50; i++) {
        await tester.fling(
          find.byType(PageView),
          const Offset(0, -300),
          800,
        );
        await tester.pump(Duration(milliseconds: 16));
      }

      await tester.pumpAndSettle();

      // Assert
      final finalMemory = ProcessInfo.currentRss;
      final memoryIncrease = finalMemory - initialMemory;
      final memoryIncreaseMB = memoryIncrease / (1024 * 1024);

      expect(memoryIncreaseMB, lessThan(50)); // Less than 50MB increase
    });
  });
}
```

## Deployment Considerations

### Environment Configuration
```dart
class FeedConfig {
  static const int maxPreloadCount = 3;
  static const int maxCacheSizeMB = 100;
  static const Duration cacheExpiry = Duration(minutes: 5);
  static const Duration videoLoadTimeout = Duration(seconds: 10);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Performance targets
  static const double targetFps = 60.0;
  static const double maxJankPercentage = 2.0;
  static const int maxMemoryUsageMB = 200;

  // Feed configuration
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
  static const double preloadTriggerThreshold = 0.8; // 80% scroll
}
```

### Environment Variables
```bash
FEED_CDN_BASE_URL=https://d3vw-feed.cloudfront.net
FEED_S3_BUCKET=video-window-feed-hls
FEED_REDIS_ENDPOINT=redis-feed-cluster.x1yzab.0001.use1.cache.amazonaws.com:6379
RECOMMENDATION_GRPC_ENDPOINT=grpcs://feed-rec.video-window.internal:7443
LIGHTFM_MODEL_VERSION=2025.09.1
SEGMENT_FEED_WRITE_KEY=op://video-window-feed/Analytics/SEGMENT_FEED_WRITE_KEY
DATADOG_RUM_CLIENT_TOKEN=op://observability/Datadog/RUM_CLIENT_TOKEN
SENTRY_DSN=op://video-window-feed/Sentry/DSN
SERVERPOD_FEED_SERVICE_SECRET=op://serverpod/Feed/SHARED_SECRET
FEED_PREFETCH_CRON_EXPRESSION=rate(1 hour)
```

### Feature Flags
```dart
class FeedFeatureFlags {
  static const String enableInfiniteScroll = 'feed_infinite_scroll';
  static const String enableVideoPreloading = 'feed_video_preloading';
  static const String enablePerformanceMonitoring = 'feed_performance_monitoring';
  static const String enablePersonalizedFeed = 'feed_personalization';
  static const String enableTrendingFeed = 'feed_trending';

  static bool isEnabled(String flagName) {
    // Implementation would integrate with feature flag service
    return true; // Default to enabled for development
  }
}
```

## Success Criteria

### Functional Requirements
- ✅ Users can scroll vertically through TikTok-style video feed
- ✅ Videos auto-play when visible and pause when not visible
- ✅ Infinite scroll loads more videos seamlessly
- ✅ Video preloading provides smooth playback experience
- ✅ User interactions are tracked for analytics
- ✅ Feed personalization adapts to user preferences

### Non-Functional Requirements
- ✅ Feed maintains 60fps during scrolling operations
- ✅ Jank is kept below 2% of all frames
- ✅ Video playback starts within 2 seconds
- ✅ Memory usage stays below 200MB peak
- ✅ Battery impact is minimized during extended use
- ✅ Performance issues are detected and reported

### Performance Metrics
- Average scroll response time < 16ms
- Video load success rate > 99%
- Cache hit rate > 80%
- User session duration > 5 minutes
- Feed refresh rate < 3 seconds

## Next Steps

1. **Implement Core Feed Components** - Video player widget, PageView feed, BLoC state management
2. **Build Video Preloading System** - Cache management, memory optimization, preload queue
3. **Develop Performance Monitoring** - FPS tracking, jank detection, memory monitoring
4. **Create Feed Service Backend** - Serverpod endpoints, database optimization, caching
5. **Implement Analytics Integration** - User interaction tracking, recommendation algorithm
6. **Comprehensive Testing** - Unit tests, integration tests, performance benchmarks
7. **Performance Optimization** - Memory profiling, battery optimization, network efficiency

**Dependencies:** Epic 1 (Authentication) for user identification, Epic 2 (Content Creation) for video availability, Epic F2 (Core Platform Services) for design tokens and navigation framework

**Blocks:** Epic 5 (Shopping Discovery) can begin in parallel after feed foundation is established

## Change Log
| Date       | Version | Description                               | Author            |
| ---------- | ------- | ----------------------------------------- | ----------------- |
| 2025-10-10 | v0.1    | Initial draft created                     | Development Team  |
| 2025-10-29 | v1.0    | Definitive stack, source tree, stories    | GitHub Copilot AI |