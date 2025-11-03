# video_player Integration Guide - Video Window

**Version:** video_player 2.8.1+  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Video Playback (Epic 06)

---

## Overview

`video_player` provides HLS video playback with security features for Video Window's protected content.

---

## Installation

```yaml
# video_window_flutter/packages/features/timeline/pubspec.yaml
dependencies:
  video_player: ^2.8.1
```

---

## Basic HLS Playback

```dart
// packages/features/timeline/lib/presentation/widgets/story_video_player.dart
class StoryVideoPlayer extends StatefulWidget {
  final String hlsUrl;
  final String watermarkText;
  
  const StoryVideoPlayer({
    required this.hlsUrl,
    required this.watermarkText,
  });
  
  @override
  State<StoryVideoPlayer> createState() => _StoryVideoPlayerState();
}

class _StoryVideoPlayerState extends State<StoryVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.hlsUrl),
      httpHeaders: {
        'Authorization': 'Bearer ${await _getAuthToken()}',
      },
    );
    
    await _controller.initialize();
    setState(() => _initialized = true);
    
    // Auto-play
    _controller.play();
    
    // Loop for story playback
    _controller.setLooping(true);
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Center(child: CircularProgressIndicator());
    }
    
    return Stack(
      children: [
        // Video player
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        
        // Watermark overlay
        Positioned(
          bottom: 16,
          right: 16,
          child: Text(
            widget.watermarkText,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ),
        
        // Play/Pause control
        Center(
          child: IconButton(
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 64,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## Security Features

### 1. FLAG_SECURE (Android)

```kotlin
// video_window_flutter/android/app/src/main/kotlin/MainActivity.kt
import android.view.WindowManager

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Prevent screenshots/screen recording
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
```

### 2. Capture Detection (iOS)

```swift
// video_window_flutter/ios/Runner/AppDelegate.swift
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Detect screen recording
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCaptureChanged),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    @objc func screenCaptureChanged() {
        if UIScreen.main.isCaptured {
            // Pause playback or show warning
            print("Screen recording detected")
        }
    }
}
```

### 3. Signed URLs (Server)

```dart
// video_window_server/lib/src/endpoints/media/video_endpoint.dart
@override
Future<String> getVideoPlaybackUrl(Session session, String storyId) async {
  final story = await Story.findById(session, storyId);
  if (story == null) throw StoryNotFoundException();
  
  // Generate signed CloudFront URL (1 hour expiry)
  final signedUrl = await _cloudFrontSigner.getSignedUrl(
    story.hlsManifestUrl,
    expiresIn: Duration(hours: 1),
  );
  
  return signedUrl;
}
```

---

## TikTok-Style Feed Integration

```dart
// packages/features/timeline/lib/presentation/pages/feed_page.dart
class FeedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: stories.length,
      itemBuilder: (context, index) {
        return StoryVideoPlayer(
          hlsUrl: stories[index].hlsUrl,
          watermarkText: '@${stories[index].makerUsername}',
        );
      },
      onPageChanged: (index) {
        // Pause previous, play current
        _handlePageChange(index);
      },
    );
  }
}
```

---

## Adaptive Bitrate (HLS)

```dart
// HLS automatically handles ABR, but you can monitor quality
_controller.addListener(() {
  final videoFormat = _controller.value.videoFormat;
  print('Current quality: ${videoFormat?.width}x${videoFormat?.height}');
});
```

---

## Common Patterns

```dart
// Preload next video
void _preloadNext(String nextUrl) {
  VideoPlayerController.networkUrl(Uri.parse(nextUrl))
    ..initialize();
}

// Error handling
_controller.addListener(() {
  if (_controller.value.hasError) {
    print('Video error: ${_controller.value.errorDescription}');
  }
});

// Buffering indicator
if (_controller.value.isBuffering) {
  return CircularProgressIndicator();
}
```

---

## Testing

```dart
testWidgets('StoryVideoPlayer displays watermark', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: StoryVideoPlayer(
        hlsUrl: 'https://test.m3u8',
        watermarkText: '@testuser',
      ),
    ),
  );
  
  await tester.pumpAndSettle();
  
  expect(find.text('@testuser'), findsOneWidget);
});
```

---

## Video Window Conventions

- **Format:** HLS only (.m3u8 manifests)
- **Watermark:** Maker username bottom-right
- **Security:** FLAG_SECURE + capture detection
- **Signed URLs:** 1-hour expiry
- **Auto-play:** Stories play automatically in feed
- **Looping:** Single story loops until user swipes

---

## Reference

- **Package:** https://pub.dev/packages/video_player
- **HLS Spec:** https://datatracker.ietf.org/doc/html/rfc8216

---

**Last Updated:** 2025-11-03 by Winston
