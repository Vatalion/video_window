# Performance Optimization Guide — Craft Video Marketplace

**Status:** v1.0 — Comprehensive performance optimization guidelines for Flutter video marketplace application.

## Purpose

This guide provides detailed performance optimization strategies, best practices, and monitoring approaches for ensuring the Craft Video Marketplace Flutter application delivers optimal performance across all devices and network conditions.

## Performance Targets and Benchmarks

### Application Performance Metrics
- **Cold Start Time**: < 3 seconds on mid-range devices
- **Warm Start Time**: < 1 second
- **Screen Load Time**: < 500ms for standard screens, < 1s for complex screens
- **Frame Rate**: Maintain 60fps during normal operations, never drop below 30fps
- **Memory Usage**: < 150MB peak usage on mid-range devices
- **Battery Impact**: < 5% battery drain per hour of normal usage
- **Network Latency**: API responses < 2 seconds for 95% of requests

### Video-Specific Performance
- **Video Load Time**: < 2 seconds for initial playback
- **Seek Time**: < 500ms for video seeking operations
- **Thumbnail Load**: < 300ms for video thumbnails
- **Stream Buffering**: < 3 seconds initial buffer, < 1 second for rebuffering

## Widget Performance Optimization

### Const Constructors and Immutable Widgets

```dart
// GOOD: Const constructors for static content
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Image(
      image: AssetImage('assets/logo.png'),
      width: 120,
      height: 40,
    );
  }
}

// GOOD: Using const wherever possible
Padding(
  padding: const EdgeInsets.all(16.0),
  child: const Text('Welcome'),
)

// BAD: Missing const keywords
Padding(
  padding: EdgeInsets.all(16.0), // Should be const
  child: Text('Welcome'), // Should be const
)
```

### Efficient List Implementation

```dart
// GOOD: Efficient list with item extent and builder
class VideoList extends StatelessWidget {
  final List<Video> videos;

  const VideoList({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: videos.length,
      itemExtent: 120.0, // Fixed height for optimal performance
      cacheExtent: 500.0, // Cache items beyond visible area
      itemBuilder: (context, index) {
        final video = videos[index];
        return VideoListItem(
          key: ValueKey(video.id), // Proper key for identity
          video: video,
        );
      },
    );
  }
}

// BAD: Inefficient list implementation
Column(
  children: videos.map((video) => VideoListItem(video: video)).toList(),
)

// GOOD: Custom scroll view for complex layouts
class CustomVideoFeed extends StatelessWidget {
  final List<Video> videos;

  const CustomVideoFeed({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Video Feed'),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => VideoListItem(video: videos[index]),
            childCount: videos.length,
          ),
        ),
      ],
    );
  }
}
```

### Widget Rebuilding Optimization

```dart
// GOOD: Using const and proper state management
class OptimizedVideoPlayer extends StatelessWidget {
  final String videoUrl;
  final bool isPlaying;

  const OptimizedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return VideoPlayer(
      controller: _controller,
      // Only rebuild when URL changes, not when playing state changes
      key: ValueKey(videoUrl),
    );
  }
}

// GOOD: Using selector to prevent unnecessary rebuilds
class VideoPlayerContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<VideoBloc, VideoState, String>(
      selector: (state) => state.currentVideoUrl,
      builder: (context, videoUrl) {
        return VideoPlayer(url: videoUrl);
      },
    );
  }
}

// BAD: Widget that rebuilds unnecessarily
class BadVideoPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        // Rebuilds on every state change, even when URL hasn't changed
        return VideoPlayer(url: state.currentVideoUrl);
      },
    );
  }
}
```

## Image and Media Optimization

### Image Loading and Caching

```dart
// GOOD: Optimized image loading with proper caching
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      memCacheWidth: width?.toInt(), // Cache at target size
      memCacheHeight: height?.toInt(),
      maxHeightDiskCache: 1000, // Limit disk cache size
      maxWidthDiskCache: 1000,
    );
  }
}

// GOOD: Custom image provider for video thumbnails
class VideoThumbnail extends StatelessWidget {
  final String videoUrl;
  final double width;
  final double height;

  const VideoThumbnail({
    super.key,
    required this.videoUrl,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _generateThumbnail(videoUrl),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            width: width,
            height: height,
            fit: BoxFit.cover,
          );
        }
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.play_arrow),
        );
      },
    );
  }

  Future<Uint8List> _generateThumbnail(String videoUrl) async {
    // Generate thumbnail from video
    final thumbnail = await VideoThumbnail.thumbnailData(
      video: videoUrl,
      imageFormat: ImageFormat.PNG,
      maxWidth: width.toInt(),
      quality: 75,
    );
    return thumbnail ?? Uint8List(0);
  }
}
```

### Video Performance Optimization

```dart
// GOOD: Optimized video player with proper lifecycle management
class OptimizedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final AutoPlayMode autoPlay;

  const OptimizedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = AutoPlayMode.none,
  });

  @override
  State<OptimizedVideoPlayer> createState() => _OptimizedVideoPlayerState();
}

class _OptimizedVideoPlayerState extends State<OptimizedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(OptimizedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _reinitializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    if (_isDisposed) return;

    _controller = VideoPlayerController.network(widget.videoUrl);

    try {
      await _controller!.initialize();
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
        });

        if (widget.autoPlay == AutoPlayMode.always) {
          _controller!.play();
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize video player: $e');
    }
  }

  Future<void> _reinitializePlayer() async {
    await _controller?.dispose();
    _isInitialized = false;
    await _initializePlayer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }
}

enum AutoPlayMode { none, always, wifiOnly }
```

## Memory Management

### Resource Disposal

```dart
// GOOD: Proper resource disposal
class ImageGallery extends StatefulWidget {
  final List<String> imageUrls;

  const ImageGallery({super.key, required this.imageUrls});

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  late PageController _pageController;
  Timer? _preloadTimer;
  final Map<int, precache.PrecachedImage> _cachedImages = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startPreloading();
  }

  void _startPreloading() {
    _preloadTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _preloadAdjacentImages();
      } else {
        timer.cancel();
      }
    });
  }

  void _preloadAdjacentImages() {
    final currentIndex = (_pageController.page ?? 0).round();
    final indicesToPreload = [
      currentIndex - 1,
      currentIndex + 1,
      currentIndex + 2,
    ];

    for (final index in indicesToPreload) {
      if (index >= 0 && index < widget.imageUrls.length) {
        _preloadImage(index);
      }
    }
  }

  void _preloadImage(int index) {
    if (!_cachedImages.containsKey(index)) {
      precache.PrecachedImage(
        NetworkImage(widget.imageUrls[index]),
        context,
      );
      _cachedImages[index] = precache.PrecachedImage(
        NetworkImage(widget.imageUrls[index]),
        context,
      );
    }
  }

  @override
  void dispose() {
    _preloadTimer?.cancel();
    _pageController.dispose();
    _cachedImages.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.imageUrls.length,
      itemBuilder: (context, index) {
        return OptimizedImage(
          imageUrl: widget.imageUrls[index],
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
        );
      },
    );
  }
}
```

### Memory Leak Prevention

```dart
// GOOD: Preventing memory leaks with proper stream management
class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final UserProfileRepository _repository;
  StreamSubscription<UserProfileUpdate>? _profileUpdateSubscription;

  UserProfileBloc(this._repository) : super(const UserProfileState.initial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<UpdateUserProfile>(_onUpdateUserProfile);

    // Listen to profile updates
    _profileUpdateSubscription = _repository.profileUpdates.listen(
      (update) => add(ProfileUpdated(update)),
    );
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(const UserProfileState.loading());

    try {
      final profile = await _repository.getUserProfile(event.userId);
      emit(UserProfileState.loaded(profile));
    } catch (e) {
      emit(UserProfileState.error(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _profileUpdateSubscription?.cancel();
    return super.close();
  }
}

// GOOD: Proper disposal in widgets
class StreamWidget extends StatefulWidget {
  final Stream<String> dataStream;

  const StreamWidget({super.key, required this.dataStream});

  @override
  State<StreamWidget> createState() => _StreamWidgetState();
}

class _StreamWidgetState extends State<StreamWidget> {
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.dataStream.listen(
      (data) {
        if (mounted) {
          setState(() {
            // Update state
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Widget implementation
    return Container();
  }
}
```

## Network Optimization

### Request Optimization

```dart
// GOOD: Optimized Serverpod client usage with proper error handling
class OptimizedApiClient {
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;

  final ServerpodClient _client;

  OptimizedApiClient(this._client);

  Future<T?> get<T>(
    String endpoint, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      return await _client.callMethod(
        endpoint,
        parameters: parameters,
      ) as T?;
    } on ServerpodException catch (e) {
      throw _handleServerpodException(e);
    }
  }

  Future<T?> post<T>(
    String endpoint, {
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _client.callMethod(
        endpoint,
        parameters: data,
      ) as T?;
    } on ServerpodException catch (e) {
      throw _handleServerpodException(e);
    }
  }

  Exception _handleServerpodException(ServerpodException e) {
    // Convert Serverpod exceptions to domain exceptions
    switch (e.statusCode) {
      case 401:
        return UnauthorizedException(e.message);
      case 429:
        return RateLimitException(e.message);
      case 500:
        return ServerException(e.message);
      default:
        return NetworkException(e.message);
    }
  }
}

### Serverpod Request Caching

```dart
// GOOD: Serverpod client with local caching
class CachedServerpodClient {
  final ServerpodClient _client;
  final Map<String, _CacheEntry> _cache = {};

  CachedServerpodClient(this._client);

  Future<T?> getCached<T>(
    String endpoint, {
    Map<String, dynamic>? parameters,
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    final cacheKey = _generateCacheKey(endpoint, parameters);

    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (!entry.isExpired) {
        return entry.data as T?;
      }
    }

    // Fetch from Serverpod
    try {
      final data = await _client.callMethod(
        endpoint,
        parameters: parameters,
      ) as T?;

      // Cache the result
      _cache[cacheKey] = _CacheEntry(
        data: data,
        timestamp: DateTime.now(),
        maxAge: cacheDuration,
      );

      return data;
    } on ServerpodException catch (e) {
      throw _handleServerpodException(e);
    }
  }

  String _generateCacheKey(String endpoint, Map<String, dynamic>? parameters) {
    return '$endpoint:${parameters?.toString() ?? ''}';
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration maxAge;

  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.maxAge,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > maxAge;
}
```

### Request Batching and Pagination

```dart
// GOOD: Efficient Serverpod pagination implementation
class PaginatedVideoRepository {
  final ServerpodClient _client;

  PaginatedVideoRepository(this._client);

  Future<PaginatedResponse<Video>> getVideos({
    int page = 1,
    int pageSize = 20,
    String? category,
    SortOption sortBy = SortOption.newest,
  }) async {
    try {
      final response = await _client.videos.getVideos(
        page: page,
        pageSize: pageSize,
        category: category,
        sortBy: sortBy.value,
      );

      return PaginatedResponse<Video>.fromServerpodModel(response);
    } on ServerpodException catch (e) {
      throw VideoException('Failed to fetch videos: $e');
    }
  }

  Future<List<Video>> getVideosByIds(List<String> videoIds) async {
    try {
      // Batch request for multiple videos
      final response = await _client.videos.getVideosByIds(videoIds);

      return response.map((model) => Video.fromSharedModel(model)).toList();
    } on ServerpodException catch (e) {
      throw VideoException('Failed to fetch videos: $e');
    }
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    final items = (json['items'] as List)
        .map((item) => fromJson(item))
        .cast<T>()
        .toList();

    return PaginatedResponse<T>(
      items: items,
      currentPage: json['current_page'] as int,
      totalPages: json['total_pages'] as int,
      totalItems: json['total_items'] as int,
      hasNextPage: json['has_next_page'] as bool,
      hasPreviousPage: json['has_previous_page'] as bool,
    );
  }
}

// GOOD: Infinite scroll pagination widget
class InfiniteVideoList extends StatefulWidget {
  const InfiniteVideoList({super.key});

  @override
  State<InfiniteVideoList> createState() => _InfiniteVideoListState();
}

class _InfiniteVideoListState extends State<InfiniteVideoList> {
  final ScrollController _scrollController = ScrollController();
  final List<Video> _videos = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadVideos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_isLoading && _hasMore) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final delta = 200.0; // Load more when 200px from bottom

      if (maxScroll - currentScroll <= delta) {
        _loadVideos();
      }
    }
  }

  Future<void> _loadVideos() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = context.read<VideoRepository>();
      final response = await repository.getVideos(page: _currentPage);

      setState(() {
        _videos.addAll(response.items);
        _currentPage++;
        _hasMore = response.hasNextPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _videos.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _videos.length) {
            return _isLoading
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink();
          }

          return VideoListItem(video: _videos[index]);
        },
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _videos.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoading = false;
    });
    await _loadVideos();
  }
}
```

## State Management Performance

### Efficient BLoC Implementation

```dart
// GOOD: Optimized BLoC with proper state management
class VideoBloc extends Bloc<VideoEvent, VideoState> {
  final VideoRepository _repository;

  VideoBloc(this._repository) : super(const VideoState.initial()) {
    on<LoadVideos>(_onLoadVideos, transformer: _debounce(const Duration(milliseconds: 300)));
    on<RefreshVideos>(_onRefreshVideos);
    on<LoadMoreVideos>(_onLoadMoreVideos);
  }

  EventTransformer<T> _debounce<T>(Duration duration) {
    return (events, mapper) => events.debounceTime(duration).flatMap(mapper);
  }

  Future<void> _onLoadVideos(
    LoadVideos event,
    Emitter<VideoState> emit,
  ) async {
    emit(const VideoState.loading());

    try {
      final videos = await _repository.getVideos(
        category: event.category,
        limit: 20,
      );

      emit(VideoState.loaded(
        videos: videos,
        hasMore: true,
        currentPage: 1,
      ));
    } catch (e) {
      emit(VideoState.error(e.toString()));
    }
  }

  Future<void> _onRefreshVideos(
    RefreshVideos event,
    Emitter<VideoState> emit,
  ) async {
    final currentState = state;

    try {
      final videos = await _repository.getVideos(
        category: event.category,
        limit: 20,
      );

      emit(VideoState.loaded(
        videos: videos,
        hasMore: true,
        currentPage: 1,
      ));
    } catch (e) {
      // Restore previous state on error
      emit(currentState);
    }
  }

  Future<void> _onLoadMoreVideos(
    LoadMoreVideos event,
    Emitter<VideoState> emit,
  ) async {
    final currentState = state;
    if (currentState is! VideoStateLoaded || !currentState.hasMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final moreVideos = await _repository.getVideos(
        category: event.category,
        limit: 20,
        offset: currentState.videos.length,
      );

      final allVideos = [...currentState.videos, ...moreVideos];
      final hasMore = moreVideos.length == 20;

      emit(VideoState.loaded(
        videos: allVideos,
        hasMore: hasMore,
        currentPage: currentState.currentPage + 1,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }
}

@freezed
class VideoState with _$VideoState {
  const factory VideoState.initial() = _Initial;
  const factory VideoState.loading() = _Loading;
  const factory VideoState.loaded({
    required List<Video> videos,
    required bool hasMore,
    required int currentPage,
    bool isLoadingMore = false,
  }) = _Loaded;
  const factory VideoState.error(String message) = _Error;
}
```

### Selective Widget Rebuilding

```dart
// GOOD: Using BlocSelector and BlocBuilder appropriately
class VideoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocSelector<VideoBloc, VideoState, String>(
          selector: (state) => state.maybeWhen(
            loaded: (videos, _, __, ___) => 'Videos (${videos.length})',
            orElse: () => 'Videos',
          ),
          builder: (context, title) => Text(title),
        ),
      ),
      body: BlocBuilder<VideoBloc, VideoState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text('Pull to refresh')),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: _buildVideoList,
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $message'),
                  ElevatedButton(
                    onPressed: () => context.read<VideoBloc>().add(const RefreshVideos()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoList(
    List<Video> videos,
    bool hasMore,
    int currentPage,
    bool isLoadingMore,
  ) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            hasMore &&
            !isLoadingMore) {
          context.read<VideoBloc>().add(const LoadMoreVideos());
        }
        return false;
      },
      child: ListView.builder(
        itemCount: videos.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == videos.length) {
            return isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink();
          }
          return VideoListItem(video: videos[index]);
        },
      ),
    );
  }
}
```

## Animation Performance

### Efficient Animations

```dart
// GOOD: Performance-optimized animations
class SmoothVideoTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SmoothVideoTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<SmoothVideoTransition> createState() => _SmoothVideoTransitionState();
}

class _SmoothVideoTransitionState extends State<SmoothVideoTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(SmoothVideoTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(_animation),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// GOOD: Using Hero animations for smooth transitions
class VideoListItem extends StatelessWidget {
  final Video video;

  const VideoListItem({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'video_${video.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToVideoPlayer(context),
          child: Card(
            child: Column(
              children: [
                OptimizedImage(
                  imageUrl: video.thumbnailUrl,
                  width: double.infinity,
                  height: 200,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    video.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToVideoPlayer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
          video: video,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
```

## Performance Monitoring and Debugging

### Performance Overlay

```dart
// GOOD: Custom performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  final List<double> _frameTimes = [];
  Timer? _monitorTimer;
  int _lastFrameTime = 0;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (_lastFrameTime > 0) {
            final frameTime = now - _lastFrameTime;
            _frameTimes.add(frameTime.toDouble());

            // Keep only last 60 frame times
            if (_frameTimes.length > 60) {
              _frameTimes.removeAt(0);
            }
          }
          _lastFrameTime = now;
        });
      }
    });
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        if (_frameTimes.isNotEmpty)
          Positioned(
            top: 50,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FPS: ${_calculateFps().toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'Frame Time: ${_getAverageFrameTime().toStringAsFixed(1)}ms',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  double _calculateFps() {
    if (_frameTimes.isEmpty) return 0.0;
    final avgFrameTime = _getAverageFrameTime();
    return avgFrameTime > 0 ? 1000.0 / avgFrameTime : 0.0;
  }

  double _getAverageFrameTime() {
    if (_frameTimes.isEmpty) return 0.0;
    final sum = _frameTimes.reduce((a, b) => a + b);
    return sum / _frameTimes.length;
  }
}
```

### Memory and Performance Profiling

```dart
// GOOD: Performance profiling utilities
class PerformanceProfiler {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<int>> _metrics = {};

  static void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }

  static void endTimer(String name) {
    final timer = _timers[name];
    if (timer != null) {
      timer.stop();
      _metrics[name] ??= [];
      _metrics[name]!.add(timer.elapsedMilliseconds);
      timer.reset();
    }
  }

  static Map<String, int> getAverageMetrics() {
    return _metrics.map((key, values) {
      final average = values.isEmpty
          ? 0
          : values.reduce((a, b) => a + b) ~/ values.length;
      return MapEntry(key, average);
    });
  }

  static void reset() {
    _timers.clear();
    _metrics.clear();
  }

  static void logMetrics() {
    final averages = getAverageMetrics();
    for (final entry in averages.entries) {
      debugPrint('${entry.key}: ${entry.value}ms average');
    }
  }
}

// GOOD: Memory usage monitoring
class MemoryMonitor {
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      final info = ProcessInfo.currentRss;
      debugPrint('Memory usage at $context: ${(info / 1024 / 1024).toStringAsFixed(2)} MB');
    }
  }

  static void startMemoryMonitoring() {
    if (kDebugMode) {
      Timer.periodic(const Duration(seconds: 10), (timer) {
        logMemoryUsage('periodic check');
      });
    }
  }
}
```

## Performance Testing

### Benchmark Tests

```dart
// GOOD: Performance benchmark tests
void main() {
  group('Performance Tests', () {
    testWidgets('List view performance test', (tester) async {
      final videos = List.generate(1000, (index) => Video.test(index));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoList(videos: videos),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      // Scroll through the list
      await tester.fling(find.byType(ListView), const Offset(0, -5000), 5000);
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Assert scrolling takes less than 1 second
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets('Image loading performance test', (tester) async {
      final imageUrl = 'https://example.com/test-image.jpg';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedImage(imageUrl: imageUrl),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      // Wait for image to load
      await tester.pumpUntilFound(find.byType(Image));

      stopwatch.stop();

      // Assert image loads in less than 3 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });
  });
}

// GOOD: Integration test for performance metrics
void main() {
  group('Performance Integration Tests', () {
    testWidgets('App startup performance', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(const VideoMarketplaceApp());
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Assert app starts in less than 3 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    testWidgets('Navigation performance test', (tester) async {
      await tester.pumpWidget(const VideoMarketplaceApp());
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Navigate to different screens
      await tester.tap(find.text('Videos'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Assert navigation completes in less than 1 second
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
```

This comprehensive performance optimization guide provides the strategies and implementations needed to ensure the Craft Video Marketplace Flutter application delivers optimal performance across all devices and usage scenarios. Regular monitoring and profiling should be incorporated into the development workflow to maintain performance standards as the application grows.