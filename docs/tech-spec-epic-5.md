# Epic 5: Story Detail Playback & Consumption - Technical Specification

**Epic Goal:** Provide comprehensive story viewing experience with video playback, section navigation, accessibility compliance, content protection, and social sharing capabilities.

**Stories:**
- 5.1: Story Detail Page Implementation
- 5.2: Accessible Playback & Transcripts
- 5.3: Share & Save Functionality

## Architecture Overview

### Component Mapping
- **Flutter App:** Story Module (story detail UI, video player, section navigation, share functionality)
- **Serverpod:** Story Service (story metadata, content delivery), Media Pipeline (video streaming, protection)
- **Database:** Stories table, story sections (JSONB), media references, user interactions
- **External:** CDN for HLS delivery, social media APIs for sharing, analytics service

### Technology Stack
- **Flutter:** video_player 2.8.0, chewie 1.7.0, share_plus 7.2.0, url_launcher 6.2.0
- **Video Streaming:** HLS with adaptive bitrate, signed URLs, watermark overlay enforcement
- **Content Protection:** JWT-based token authentication, client-side capture deterrence
- **Accessibility:** WCAG 2.1 AA compliance, screen reader support, keyboard navigation
- **State Management:** BLoC pattern for story state, video player state, and UI interactions

## Data Models

### Story Entity
```dart
class ArtifactStory {
  final String id;
  final String makerId;
  final String title;
  final String description;
  final String categoryId;
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
}

class StorySection {
  final String type; // overview, process, materials, notes, location
  final String title;
  final dynamic content; // Flexible content structure based on type
  final Map<String, dynamic> metadata;
}

enum StoryStatus { draft, submitted, approved, published, archived }
```

### Media Reference Entity
```dart
class MediaReference {
  final String id;
  final String type; // video, image, caption_track, transcript
  final String url;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
}
```

### Video Player State
```dart
class VideoPlayerState {
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isBuffering;
  final bool isFullscreen;
  final bool captionsEnabled;
  final VideoQuality quality;
  final String? errorMessage;
}
```

### User Interaction Models
```dart
class StoryView {
  final String id;
  final String storyId;
  final String userId;
  final String source; // feed, share, deep_link
  final DateTime viewedAt;
  final Map<String, dynamic> analytics;
}

class StoryShare {
  final String id;
  final String storyId;
  final String userId;
  final String channel;
  final String deepLink;
  final DateTime expiresAt;
  final DateTime createdAt;
}
```

## API Endpoints

### Story Endpoints
```
GET /stories/{id}
GET /stories/{id}/sections
POST /stories/{id}/share
GET /stories/{id}/analytics
```

### Media Endpoints
```
POST /media/signed-url
GET /media/{id}/captions
GET /media/{id}/transcript
POST /media/{id}/watermark-config
```

### Endpoint Specifications

#### Get Story Details
```dart
// Request
GET /stories/{story_id}?include=sections,maker,media

// Response
{
  "story": {
    "id": "story_123",
    "title": "Handmade Ceramic Vase",
    "description": "Learn how I create this beautiful ceramic vase...",
    "maker": {
      "id": "maker_456",
      "name": "Sarah's Pottery",
      "avatar": "https://cdn.example.com/avatars/maker_456.jpg",
      "isVerified": true,
      "followerCount": 1250
    },
    "sections": {
      "overview": {
        "title": "Overview",
        "content": {
          "category": "Pottery",
          "duration": "45 minutes",
          "difficulty": "Intermediate",
          "description": "Create a beautiful ceramic vase using traditional techniques..."
        }
      },
      "process": {
        "title": "Process Timeline",
        "content": [
          {
            "step": 1,
            "title": "Preparing the Clay",
            "description": "Wedging and centering the clay",
            "timestamp": "00:00",
            "duration": "5:00"
          }
        ]
      }
    },
    "heroVideo": {
      "id": "video_789",
      "type": "video",
      "url": "https://cdn.example.com/videos/story_123/hero.m3u8",
      "thumbnail": "https://cdn.example.com/videos/story_123/thumbnail.jpg",
      "duration": "45:20",
      "qualities": ["720p", "1080p", "4K"]
    }
  }
}
```

#### Generate Signed URL for Video
```dart
// Request
POST /media/signed-url
{
  "mediaId": "video_789",
  "userId": "user_123",
  "quality": "1080p",
  "watermarkConfig": {
    "userId": "user_123",
    "position": "bottom-right",
    "opacity": 0.7
  }
}

// Response
{
  "signedUrl": "https://cdn.example.com/videos/story_123/hero_1080p.m3u8?signature=abc123&expires=1697136000",
  "expiresAt": "2023-10-12T12:00:00Z",
  "watermarkConfig": {
    "userId": "user_123",
    "text": "user_123",
    "position": "bottom-right",
    "opacity": 0.7
  }
}
```

#### Create Share Link
```dart
// Request
POST /stories/{story_id}/share
{
  "channel": "whatsapp",
  "customMessage": "Check out this amazing pottery tutorial!"
}

// Response
{
  "shareId": "share_456",
  "deepLink": "https://videowindow.app/story/story_123?ref=share_456",
  "expiresAt": "2023-10-19T12:00:00Z",
  "socialPreview": {
    "title": "Handmade Ceramic Vase - Pottery Tutorial",
    "description": "Learn how I create this beautiful ceramic vase using traditional techniques...",
    "image": "https://cdn.example.com/videos/story_123/social-preview.jpg"
  }
}
```

## Implementation Details

### Flutter Story Module Structure

#### Feature Package Organization
```
packages/features/story/
├── lib/
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── story.dart
│   │   │   ├── story_section.dart
│   │   │   └── media_reference.dart
│   │   ├── repositories/
│   │   │   └── story_repository.dart
│   │   └── usecases/
│   │       ├── get_story_details.dart
│   │       ├── play_video.dart
│   │       └── share_story.dart
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── story_remote_data_source.dart
│   │   │   └── media_remote_data_source.dart
│   │   ├── models/
│   │   │   ├── story_model.dart
│   │   │   └── media_model.dart
│   │   └── repositories/
│   │       └── story_repository_impl.dart
│   └── presentation/
│       ├── bloc/
│       │   ├── story_bloc.dart
│       │   ├── video_player_bloc.dart
│       │   └── section_navigation_bloc.dart
│       ├── pages/
│       │   └── story_detail_page.dart
│       └── widgets/
│           ├── story_header.dart
│           ├── video_player_widget.dart
│           ├── section_navigation.dart
│           ├── story_overview.dart
│           ├── process_timeline.dart
│           ├── materials_section.dart
│           └── share_widget.dart
```

#### State Management (BLoC)
```dart
// Story BLoC Events
abstract class StoryEvent {}
class StoryLoadRequested extends StoryEvent {
  final String storyId;
  final String source;
}
class VideoPlayRequested extends StoryEvent {
  final String mediaId;
  final VideoQuality quality;
}
class SectionNavigated extends StoryEvent {
  final String sectionId;
}
class StoryShareRequested extends StoryEvent {
  final String channel;
  final String? customMessage;
}

// Story BLoC States
abstract class StoryState {}
class StoryInitial extends StoryState {}
class StoryLoading extends StoryState {}
class StoryLoaded extends StoryState {
  final ArtifactStory story;
  final VideoPlayerState? videoState;
  final String activeSection;
}
class StoryError extends StoryState {
  final String message;
  final StoryErrorType type;
}

// Video Player BLoC
class VideoPlayerBloc extends Bloc<VideoPlayerEvent, VideoPlayerState> {
  VideoPlayerBloc(this.videoRepository) : super(VideoPlayerState.initial()) {
    on<VideoPlayRequested>(_onPlayRequested);
    on<VideoPauseRequested>(_onPauseRequested);
    on<VideoSeekRequested>(_onSeekRequested);
    on<VideoQualityChanged>(_onQualityChanged);
    on<CaptionsToggled>(_onCaptionsToggled);
  }

  Future<void> _onPlayRequested(
    VideoPlayRequested event,
    Emitter<VideoPlayerState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final signedUrl = await _videoRepository.getSignedUrl(
        mediaId: event.mediaId,
        quality: event.quality,
        watermarkConfig: WatermarkConfig(
          userId: _currentUserId,
          position: 'bottom-right',
          opacity: 0.7,
        ),
      );

      emit(state.copyWith(
        signedUrl: signedUrl,
        isLoading: false,
        isPlaying: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: VideoError.loadFailed(e.toString()),
        isLoading: false,
      ));
    }
  }
}
```

#### Video Player Implementation
```dart
class AccessibleVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final Map<String, String> captionTracks;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final Function(Duration)? onSeek;
  final Function(VideoQuality)? onQualityChanged;

  @override
  _AccessibleVideoPlayerState createState() => _AccessibleVideoPlayerState();
}

class _AccessibleVideoPlayerState extends State<AccessibleVideoPlayer> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _captionsEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _setupAccessibility();
  }

  void _initializePlayer() async {
    _controller = VideoPlayerController.network(widget.videoUrl);
    await _controller.initialize();
    setState(() {});
    _controller.addListener(_onPlayerStateChanged);
  }

  void _setupAccessibility() {
    // Enable screen reader support
    SemanticsService.announce(
      'Video player loaded. Duration: ${_formatDuration(_controller.value.duration)}',
      TextDirection.ltr,
    );
  }

  Widget _buildPlayerWithControls() {
    return Stack(
      children: [
        // Main video player with semantic labels
        Semantics(
          label: 'Story video player',
          hint: 'Tap to play or pause. Use space bar for keyboard control',
          child: GestureDetector(
            onTap: _togglePlayPause,
            child: VideoPlayer(_controller),
          ),
        ),

        // Custom controls overlay
        if (_showControls) _buildControlsOverlay(),

        // Watermark overlay
        _buildWatermarkOverlay(),
      ],
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            _buildProgressBar(),

            // Control buttons
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Play/Pause button
                  Semantics(
                    label: _controller.value.isPlaying ? 'Pause video' : 'Play video',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                  ),

                  // Time display
                  Text(
                    '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                    style: TextStyle(color: Colors.white),
                  ),

                  Spacer(),

                  // Captions toggle
                  Semantics(
                    label: _captionsEnabled ? 'Disable captions' : 'Enable captions',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        _captionsEnabled ? Icons.closed_caption : Icons.closed_caption_disabled,
                        color: Colors.white,
                      ),
                      onPressed: _toggleCaptions,
                    ),
                  ),

                  // Quality selector
                  _buildQualitySelector(),

                  // Fullscreen button
                  Semantics(
                    label: 'Enter fullscreen',
                    button: true,
                    child: IconButton(
                      icon: Icon(Icons.fullscreen, color: Colors.white),
                      onPressed: _toggleFullscreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatermarkOverlay() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: IgnorePointer(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '@${_currentUserId}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
      _resetHideControlsTimer();
    });
  }

  void _toggleCaptions() {
    setState(() {
      _captionsEnabled = !_captionsEnabled;
      SemanticsService.announce(
        _captionsEnabled ? 'Captions enabled' : 'Captions disabled',
        TextDirection.ltr,
      );
    });
  }
}
```

#### Section Navigation Implementation
```dart
class SectionNavigation extends StatefulWidget {
  final List<StorySection> sections;
  final String activeSection;
  final Function(String) onSectionChanged;

  @override
  _SectionNavigationState createState() => _SectionNavigationState();
}

class _SectionNavigationState extends State<SectionNavigation> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<SectionNavigationState> _overviewKey = GlobalKey();
  final GlobalKey<SectionNavigationState> _processKey = GlobalKey();
  final GlobalKey<SectionNavigationState> _materialsKey = GlobalKey();
  final GlobalKey<SectionNavigationState> _notesKey = GlobalKey();
  final GlobalKey<SectionNavigationState> _locationKey = GlobalKey();

  Map<String, GlobalKey> get _sectionKeys => {
    'overview': _overviewKey,
    'process': _processKey,
    'materials': _materialsKey,
    'notes': _notesKey,
    'location': _locationKey,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.sections.length,
        itemBuilder: (context, index) {
          final section = widget.sections[index];
          final isActive = section.type == widget.activeSection;

          return _SectionTab(
            section: section,
            isActive: isActive,
            onTap: () => _navigateToSection(section.type),
          );
        },
      ),
    );
  }

  void _navigateToSection(String sectionType) {
    final key = _sectionKeys[sectionType];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      widget.onSectionChanged(sectionType);

      // Announce navigation for screen readers
      SemanticsService.announce(
        'Navigated to ${sectionType} section',
        TextDirection.ltr,
      );
    }
  }
}

class _SectionTab extends StatelessWidget {
  final StorySection section;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          section.title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
```

### Serverpod Story Service

#### Story Service Implementation
```dart
class StoryService {
  // Get story with all sections and media
  Future<StoryResponse> getStoryDetails(
    String storyId,
    String? userId,
  ) async {
    // Verify story access permissions
    final story = await _storyRepository.findById(storyId);
    if (story == null || story.status != StoryStatus.published) {
      throw StoryNotFoundException('Story not found or not published');
    }

    // Get story sections
    final sections = await _storySectionRepository.findByStoryId(storyId);

    // Get maker information
    final maker = await _userRepository.findById(story.makerId);

    // Get media references
    final media = await _mediaRepository.findByStoryId(storyId);

    // Track story view for analytics
    if (userId != null) {
      await _analyticsService.trackStoryView(
        StoryView(
          storyId: storyId,
          userId: userId,
          source: 'direct', // Determined from request context
          viewedAt: DateTime.now(),
        ),
      );
    }

    return StoryResponse(
      story: story,
      sections: sections,
      maker: maker,
      media: media,
    );
  }

  // Generate signed URL for secure video access
  Future<String> generateSignedUrl(
    String mediaId,
    String userId,
    VideoQuality quality,
    WatermarkConfig watermarkConfig,
  ) async {
    // Verify media exists and user has access
    final media = await _mediaRepository.findById(mediaId);
    if (media == null) {
      throw MediaNotFoundException('Media not found');
    }

    // Generate watermark configuration
    final watermarkData = {
      'userId': userId,
      'text': userId,
      'position': watermarkConfig.position,
      'opacity': watermarkConfig.opacity,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Generate JWT token for signed URL
    final token = _generateSignedUrlToken({
      'mediaId': mediaId,
      'userId': userId,
      'quality': quality.name,
      'watermark': watermarkData,
      'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
    });

    // Construct signed URL
    final baseUrl = media.url;
    final signedUrl = '$baseUrl?token=$token';

    return signedUrl;
  }

  // Create share link with analytics tracking
  Future<ShareResponse> createShareLink(
    String storyId,
    String userId,
    String channel,
    String? customMessage,
  ) async {
    // Generate share ID and deep link
    final shareId = _generateShareId();
    final deepLink = 'https://videowindow.app/story/$storyId?ref=$shareId';

    // Set expiration (7 days from now)
    final expiresAt = DateTime.now().add(Duration(days: 7));

    // Store share record
    final share = StoryShare(
      id: shareId,
      storyId: storyId,
      userId: userId,
      channel: channel,
      deepLink: deepLink,
      expiresAt: expiresAt,
      createdAt: DateTime.now(),
    );

    await _shareRepository.create(share);

    // Generate social preview metadata
    final story = await _storyRepository.findById(storyId);
    final socialPreview = _generateSocialPreview(story);

    // Track share event for analytics
    await _analyticsService.trackStoryShare(
      storyId: storyId,
      userId: userId,
      channel: channel,
      shareId: shareId,
    );

    return ShareResponse(
      shareId: shareId,
      deepLink: deepLink,
      expiresAt: expiresAt,
      socialPreview: socialPreview,
    );
  }

  String _generateSignedUrlToken(Map<String, dynamic> payload) {
    final jwt = JWT(payload);
    final key = SecretKey(_config.jwtSecretKey);
    return jwt.sign(key, algorithm: HS256);
  }

  SocialPreview _generateSocialPreview(ArtifactStory story) {
    return SocialPreview(
      title: story.title,
      description: story.description.length > 150
          ? '${story.description.substring(0, 150)}...'
          : story.description,
      image: story.heroVideo?.thumbnail ?? '',
      url: 'https://videowindow.app/story/${story.id}',
    );
  }
}
```

## Video Streaming & Content Protection

### HLS Streaming Implementation
```dart
class VideoStreamingService {
  // HLS manifest generation with adaptive bitrate
  String generateHLSManifest(
    String videoId,
    Map<VideoQuality, String> renditions,
    String watermarkToken,
  ) {
    final manifest = StringBuffer();
    manifest.writeln('#EXTM3U');
    manifest.writeln('#EXT-X-VERSION:6');
    manifest.writeln('#EXT-X-INDEPENDENT-SEGMENTS');

    // Add renditions
    renditions.forEach((quality, url) {
      manifest.writeln('#EXT-X-STREAM-INF:BANDWIDTH=${quality.bitrate},RESOLUTION=${quality.resolution},CODECS="avc1.640028,mp4a.40.2"');
      manifest.writeln('$url?watermark=$watermarkToken');
    });

    return manifest.toString();
  }

  // Adaptive bitrate selection based on network conditions
  VideoQuality selectOptimalQuality(
    NetworkInfo networkInfo,
    List<VideoQuality> availableQualities,
  ) {
    // Estimate available bandwidth
    final estimatedBandwidth = networkInfo.downlink * 1000000; // Convert Mbps to bps

    // Find highest quality that fits within bandwidth
    VideoQuality optimalQuality = availableQualities.first; // Default to lowest
    int maxBitrate = 0;

    for (final quality in availableQualities) {
      if (quality.bitrate <= estimatedBandwidth && quality.bitrate > maxBitrate) {
        optimalQuality = quality;
        maxBitrate = quality.bitrate;
      }
    }

    return optimalQuality;
  }
}
```

### Content Protection Implementation
```dart
class ContentProtectionService {
  // Client-side capture deterrence
  void enableCaptureDeterrence() {
    // Disable right-click context menu
    document.onContextMenu.listen((event) => event.preventDefault());

    // Disable keyboard shortcuts
    document.onKeyDown.listen((event) {
      if (event.ctrlKey && (event.key == 's' || event.key == 'p')) {
        event.preventDefault();
      }
      if (event.key == 'PrintScreen') {
        event.preventDefault();
      }
    });

    // Detect screen recording attempts
    _detectScreenRecording();
  }

  void _detectScreenRecording() {
    // Monitor for screen recording APIs
    if (window.navigator.mediaDevices != null) {
      window.navigator.mediaDevices.getDisplayMedia().then((_) {
        // Screen recording detected - take protective action
        _onScreenRecordingDetected();
      }).catchError((_) {
        // No screen recording detected
      });
    }
  }

  void _onScreenRecordingDetected() {
    // Log security event
    _securityLogger.logEvent(
      SecurityEventType.screenRecordingAttempt,
      userId: _currentUserId,
      timestamp: DateTime.now(),
    );

    // Optionally blur content or show warning
    _showSecurityWarning();
  }

  // Watermark overlay enforcement
  Widget buildWatermarkOverlay(String userId, String contentId) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Subtle watermark pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Image.network(
                  'https://cdn.example.com/watermarks/pattern.png',
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),

            // User-specific watermark
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'User: $userId',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Accessibility Implementation

### WCAG 2.1 AA Compliance
```dart
class AccessibilityManager {
  // Screen reader announcements
  static void announceVideoStateChange(VideoPlayerState state) {
    String message;

    switch (state.status) {
      case VideoStatus.playing:
        message = 'Video playing';
        break;
      case VideoStatus.paused:
        message = 'Video paused';
        break;
      case VideoStatus.buffering:
        message = 'Video buffering';
        break;
      case VideoStatus.ended:
        message = 'Video ended';
        break;
      case VideoStatus.error:
        message = 'Video error: ${state.errorMessage}';
        break;
    }

    SemanticsService.announce(message, TextDirection.ltr);
  }

  // Keyboard navigation setup
  static void setupKeyboardShortcuts(GlobalKey<NavigatorState> navigatorKey) {
    RawKeyboard.instance.addListener((RawKeyEvent event) {
      if (event is RawKeyDownEvent) {
        switch (event.logicalKey.keyLabel) {
          case 'Space':
            // Toggle play/pause
            _toggleVideoPlayback();
            break;
          case 'Arrow Left':
            // Seek backward 10 seconds
            _seekVideo(-10);
            break;
          case 'Arrow Right':
            // Seek forward 10 seconds
            _seekVideo(10);
            break;
          case 'Arrow Up':
            // Increase volume
            _adjustVolume(0.1);
            break;
          case 'Arrow Down':
            // Decrease volume
            _adjustVolume(-0.1);
            break;
          case 'Key C':
            // Toggle captions
            _toggleCaptions();
            break;
          case 'Key F':
            // Toggle fullscreen
            _toggleFullscreen();
            break;
        }
      }
    });
  }

  // High contrast mode support
  static ThemeData buildHighContrastTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.white,
        onSecondary: Colors.black,
        surface: Colors.white,
        onSurface: Colors.black,
        background: Colors.white,
        onBackground: Colors.black,
      ),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
    );
  }

  // Focus management for modals and overlays
  static FocusNode trapFocus(BuildContext context, Widget child) {
    final focusNode = FocusNode();

    return Focus(
      focusNode: focusNode,
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
          // Handle tab navigation within trapped area
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
```

### Caption and Transcript Support
```dart
class CaptionService {
  // Load caption tracks in multiple languages
  Future<List<CaptionTrack>> loadCaptionTracks(String videoId) async {
    final captionData = await _captionRepository.findByVideoId(videoId);

    return captionData.map((data) => CaptionTrack(
      language: data.language,
      label: data.label,
      url: data.url,
      format: data.format, // WebVTT, SRT, etc.
    )).toList();
  }

  // Parse WebVTT captions
  List<CaptionCue> parseWebVTT(String vttContent) {
    final cues = <CaptionCue>[];
    final lines = vttContent.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('WEBVTT')) {
        // Skip header
        continue;
      }

      if (line.contains('-->')) {
        // This is a timing line
        final parts = line.split('-->');
        if (parts.length == 2) {
          final start = _parseTime(parts[0].trim());
          final end = _parseTime(parts[1].trim());

          // Get caption text (next non-empty line)
          String text = '';
          for (int j = i + 1; j < lines.length; j++) {
            final textLine = lines[j].trim();
            if (textLine.isNotEmpty) {
              text = textLine;
              break;
            }
          }

          cues.add(CaptionCue(
            start: start,
            end: end,
            text: text,
          ));
        }
      }
    }

    return cues;
  }

  Duration _parseTime(String timeString) {
    // Parse format like "00:01:23.456"
    final parts = timeString.split(':');
    if (parts.length == 3) {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = double.parse(parts[2]);
      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds.toInt(),
        milliseconds: ((seconds - seconds.toInt()) * 1000).toInt(),
      );
    }
    return Duration.zero;
  }
}

class CaptionCue {
  final Duration start;
  final Duration end;
  final String text;

  CaptionCue({
    required this.start,
    required this.end,
    required this.text,
  });
}
```

## Testing Strategy

### Unit Tests
```dart
// Story BLoC tests
class StoryBlocTest {
  @testWidgets('should load story successfully', (WidgetTester tester) async {
    // Arrange
    final mockRepository = MockStoryRepository();
    final story = ArtifactStory.test();
    mockRepository.getStoryDetails(any) async => Right(story);

    final bloc = StoryBloc(mockRepository);

    // Act
    bloc.add(StoryLoadRequested(storyId: '123', source: 'feed'));

    // Assert
    await expectLater(
      bloc.stream,
      emitsInOrder([
        StoryLoading(),
        StoryLoaded(story: story),
      ]),
    );
  });

  @testWidgets('should handle video playback errors', (WidgetTester tester) async {
    // Arrange
    final mockVideoRepository = MockVideoRepository();
    mockVideoRepository.getSignedUrl(any)
        .thenThrow(VideoLoadException('Network error'));

    final bloc = VideoPlayerBloc(mockVideoRepository);

    // Act
    bloc.add(VideoPlayRequested(mediaId: 'video123', quality: VideoQuality.hd));

    // Assert
    await expectLater(
      bloc.stream,
      emitsInOrder([
        VideoPlayerState(isLoading: true),
        VideoPlayerState(
          isLoading: false,
          error: VideoError.loadFailed('Network error'),
        ),
      ]),
    );
  });
}

// Video player tests
class VideoPlayerTest {
  @testWidgets('should toggle play/pause state', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(MaterialApp(
      home: AccessibleVideoPlayer(
        videoUrl: 'https://example.com/test.m3u8',
        captionTracks: {},
      ),
    ));

    // Act
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    // Assert
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  @testWidgets('should be keyboard accessible', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(MaterialApp(
      home: AccessibleVideoPlayer(
        videoUrl: 'https://example.com/test.m3u8',
        captionTracks: {},
      ),
    ));

    // Act
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();

    // Assert
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });
}
```

### Integration Tests
```dart
class StoryIntegrationTest {
  @testWidgets('should complete story viewing flow', (WidgetTester tester) async {
    // Arrange
    mockNetworkResponses();

    // Act
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // Navigate to story
    await tester.tap(find.text('View Story'));
    await tester.pumpAndSettle();

    // Verify story loaded
    expect(find.text('Handmade Ceramic Vase'), findsOneWidget);

    // Play video
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump(Duration(seconds: 1));

    // Navigate sections
    await tester.tap(find.text('Process'));
    await tester.pumpAndSettle();

    // Share story
    await tester.tap(find.byIcon(Icons.share));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Story shared successfully'), findsOneWidget);
  });
}
```

### Accessibility Tests
```dart
class AccessibilityTest {
  @testWidgets('should meet WCAG 2.1 AA standards', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(MaterialApp(
      home: StoryDetailPage(storyId: '123'),
    ));

    // Assert semantic labels
    expect(
      tester.binding.pipelineOwner.semanticsOwner,
      includesSemantics(
        label: 'Story video player',
        hint: 'Tap to play or pause',
      ),
    );

    // Assert focus management
    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(tester.binding.focusNode.primaryFocus, isNotNull);
  });

  @testWidgets('should support screen readers', (WidgetTester tester) async {
    // Arrange
    final semantics = SemanticsHandle();
    await tester.pumpWidget(MaterialApp(
      home: AccessibleVideoPlayer(
        videoUrl: 'https://example.com/test.m3u8',
        captionTracks: {},
      ),
    ));

    // Act
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    // Assert
    expect(
      semantics.debugSemanticsTree,
      contains('Video playing'),
    );

    semantics.dispose();
  });
}
```

## Performance Optimization

### Video Loading Optimization
```dart
class VideoOptimizer {
  // Preload next video in background
  Future<void> preloadNextVideo(String storyId, String currentSection) async {
    final sections = await _storyRepository.getSections(storyId);
    final currentIndex = sections.indexWhere((s) => s.type == currentSection);

    if (currentIndex < sections.length - 1) {
      final nextSection = sections[currentIndex + 1];
      final nextMedia = nextSection.mediaReferences
          .where((m) => m.type == 'video')
          .firstOrNull;

      if (nextMedia != null) {
        // Preload with low priority
        _videoPreloader.preload(
          mediaId: nextMedia.id,
          priority: PreloadPriority.low,
        );
      }
    }
  }

  // Adaptive bitrate based on network conditions
  VideoQuality selectOptimalQuality(NetworkInfo network, DeviceInfo device) {
    // Consider network bandwidth
    final bandwidth = network.downlink * 1000000; // Convert to bps

    // Consider device capabilities
    final screenSize = device.screenSize;
    final pixelRatio = device.pixelRatio;

    // Consider battery level
    final batteryLevel = device.batteryLevel;

    // Calculate optimal quality
    if (batteryLevel < 0.2) {
      // Low battery - prefer lower quality
      return VideoQuality.sd;
    }

    if (bandwidth < 1000000) {
      // Low bandwidth - use SD
      return VideoQuality.sd;
    } else if (bandwidth < 5000000) {
      // Medium bandwidth - use HD
      return VideoQuality.hd;
    } else {
      // High bandwidth - use FHD or 4K based on device
      return pixelRatio > 2.0 ? VideoQuality.uhd : VideoQuality.fhd;
    }
  }

  // Memory management for video buffers
  void manageVideoMemory() {
    // Clear unused video buffers
    _videoBufferManager.clearOldBuffers(
      maxAge: Duration(minutes: 10),
      maxMemory: 100 * 1024 * 1024, // 100MB
    );

    // Release memory pressure
    if (_memoryMonitor.isMemoryPressureHigh) {
      _videoBufferManager.reduceBuffers(targetMemory: 50 * 1024 * 1024);
    }
  }
}
```

### Network Resilience
```dart
class NetworkResilienceService {
  // Retry logic with exponential backoff
  Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = Duration(seconds: 1),
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;

        final delay = initialDelay * math.pow(2, attempt);
        await Future.delayed(delay);
      }
    }
    throw OperationException('Max retries exceeded');
  }

  // Offline support with sync
  Future<void> syncOfflineData() async {
    if (await _connectivityService.hasConnection()) {
      // Sync viewed stories
      final viewedStories = await _offlineStorage.getViewedStories();
      for (final story in viewedStories) {
        try {
          await _analyticsService.syncStoryView(story);
          await _offlineStorage.removeViewedStory(story.id);
        } catch (e) {
          _logger.error('Failed to sync story view: $e');
        }
      }

      // Sync share events
      final shareEvents = await _offlineStorage.getShareEvents();
      for (final event in shareEvents) {
        try {
          await _shareService.syncShareEvent(event);
          await _offlineStorage.removeShareEvent(event.id);
        } catch (e) {
          _logger.error('Failed to sync share event: $e');
        }
      }
    }
  }
}
```

## Error Handling

### Error Types and Recovery
```dart
abstract class StoryError implements Exception {
  final String message;
  final StoryErrorType type;

  const StoryError(this.message, this.type);
}

class VideoLoadError extends StoryError {
  const VideoLoadError(String message) : super(message, StoryErrorType.videoLoad);
}

class NetworkError extends StoryError {
  const NetworkError(String message) : super(message, StoryErrorType.network);
}

class ContentProtectionError extends StoryError {
  const ContentProtectionError(String message) : super(message, StoryErrorType.contentProtection);
}

enum StoryErrorType {
  videoLoad,
  network,
  contentProtection,
  authentication,
  notFound,
}

class ErrorRecoveryService {
  Future<void> handleError(StoryError error, BuildContext context) async {
    switch (error.type) {
      case StoryErrorType.videoLoad:
        await _handleVideoLoadError(error, context);
        break;
      case StoryErrorType.network:
        await _handleNetworkError(error, context);
        break;
      case StoryErrorType.contentProtection:
        await _handleContentProtectionError(error, context);
        break;
      case StoryErrorType.authentication:
        await _handleAuthenticationError(error, context);
        break;
      case StoryErrorType.notFound:
        await _handleNotFoundError(error, context);
        break;
    }
  }

  Future<void> _handleVideoLoadError(VideoLoadError error, BuildContext context) async {
    // Show retry dialog
    final shouldRetry = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Video Load Error'),
        content: Text('Failed to load video. Would you like to retry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Retry'),
          ),
        ],
      ),
    );

    if (shouldRetry == true) {
      // Retry video loading with different quality
      context.read<VideoPlayerBloc>().add(
        VideoPlayRequested(
          mediaId: 'current_video_id',
          quality: VideoQuality.sd, // Fallback to lower quality
        ),
      );
    }
  }

  Future<void> _handleNetworkError(NetworkError error, BuildContext context) async {
    // Show offline mode options
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Network error. Some features may be unavailable.'),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            // Retry network operation
            context.read<StoryBloc>().add(StoryLoadRequested(
              storyId: 'current_story_id',
              source: 'retry',
            ));
          },
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }
}
```

## Deployment Considerations

### Environment Configuration
```yaml
# Production Environment Variables
VIDEO_STREAMING_CONFIG:
  CDN_BASE_URL: "https://cdn.videowindow.com"
  SIGNED_URL_SECRET: "your-jwt-secret-key"
  WATERMARK_SERVICE_URL: "https://watermark.videowindow.com"

CONTENT_PROTECTION:
  ENABLE_WATERMARKING: true
  WATERMARK_OPACITY: 0.7
  CAPTURE_DETERRENCE_ENABLED: true

ACCESSIBILITY_CONFIG:
  CAPTIONS_ENABLED: true
  HIGH_CONTRAST_MODE: true
  SCREEN_READER_SUPPORT: true

PERFORMANCE_CONFIG:
  VIDEO_PRELOAD_ENABLED: true
  ADAPTIVE_BITRATE_ENABLED: true
  MAX_CONCURRENT_STREAMS: 3
  BUFFER_SIZE: "10MB"
```

### Database Schema
```sql
-- Stories table
CREATE TABLE stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  maker_id UUID NOT NULL REFERENCES users(id),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  category_id UUID REFERENCES categories(id),
  hero_video_id UUID REFERENCES media(id),
  status VARCHAR(50) NOT NULL DEFAULT 'draft',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Story sections (flexible content structure)
CREATE TABLE story_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  section_type VARCHAR(50) NOT NULL, -- overview, process, materials, notes, location
  title VARCHAR(255) NOT NULL,
  content JSONB NOT NULL,
  metadata JSONB DEFAULT '{}',
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Media references
CREATE TABLE media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL, -- video, image, caption_track, transcript
  url VARCHAR(500) NOT NULL,
  metadata JSONB DEFAULT '{}',
  file_size BIGINT,
  duration INTEGER, -- For videos in seconds
  created_at TIMESTAMP DEFAULT NOW()
);

-- Story views (analytics)
CREATE TABLE story_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES stories(id),
  user_id UUID REFERENCES users(id),
  source VARCHAR(50) NOT NULL, -- feed, share, deep_link
  viewed_at TIMESTAMP DEFAULT NOW(),
  analytics_data JSONB DEFAULT '{}'
);

-- Story shares
CREATE TABLE story_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES stories(id),
  user_id UUID REFERENCES users(id),
  channel VARCHAR(50) NOT NULL, -- whatsapp, instagram, twitter, etc.
  deep_link VARCHAR(500) NOT NULL,
  custom_message TEXT,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_stories_maker_id ON stories(maker_id);
CREATE INDEX idx_stories_status ON stories(status);
CREATE INDEX idx_stories_created_at ON stories(created_at DESC);
CREATE INDEX idx_story_sections_story_id ON story_sections(story_id);
CREATE INDEX idx_media_story_id ON media(story_id);
CREATE INDEX idx_story_views_story_id ON story_views(story_id);
CREATE INDEX idx_story_shares_story_id ON story_shares(story_id);
CREATE INDEX idx_story_shares_expires_at ON story_shares(expires_at);
```

## Success Criteria

### Functional Requirements
- ✅ Users can view complete story pages with video playback and section navigation
- ✅ Video streaming supports adaptive bitrate and content protection
- ✅ Section navigation provides smooth scrolling and active state indicators
- ✅ Share functionality generates expiring deep links with analytics tracking
- ✅ Accessibility features meet WCAG 2.1 AA standards
- ✅ Content protection prevents unauthorized downloads and screen capture

### Non-Functional Requirements
- ✅ Video startup time under 2 seconds on 4G networks
- ✅ Smooth video playback with minimal buffering
- ✅ Responsive design works across all device sizes and orientations
- ✅ Memory usage optimized for video playback on mobile devices
- ✅ Network resilience with offline support and graceful degradation
- ✅ Comprehensive error handling with user-friendly recovery options

### Success Metrics
- Story view completion rate > 85%
- Video playback success rate > 95%
- Average video load time < 3 seconds
- Share conversion rate > 10%
- Accessibility compliance score 100%
- User satisfaction score > 4.2/5
- Content protection violation rate < 0.1%

## Next Steps

1. **Implement Story Detail Page** - Layout, video player, section navigation
2. **Develop Video Streaming** - HLS integration, adaptive bitrate, content protection
3. **Add Accessibility Features** - Screen reader support, captions, keyboard navigation
4. **Implement Share Functionality** - Deep links, social media integration, analytics
5. **Add Performance Optimizations** - Video preloading, adaptive quality, memory management
6. **Comprehensive Testing** - Unit tests, integration tests, accessibility validation
7. **Error Handling** - Network resilience, content protection errors, graceful degradation

**Dependencies:** Epic F2 (Core Platform Services) for design tokens and navigation, Epic 1 (Viewer Authentication) for user identification and analytics, Epic 6 (Media Pipeline) for video processing and content protection

**Blocks:** Epic 9 (Offer Submission Flow) depends on story CTA implementation, Epic 11 (Notifications) for story engagement notifications