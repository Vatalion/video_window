# camera Integration Guide - Video Window

**Version:** camera 0.10.5+  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Video Capture (Epic 08)

---

## Overview

`camera` plugin provides in-app video recording for Video Window's story creation flow.

---

## Installation

```yaml
# video_window_flutter/packages/features/publishing/pubspec.yaml
dependencies:
  camera: ^0.10.5
```

---

## Permissions Setup

### iOS (Info.plist)

```xml
<!-- video_window_flutter/ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>Record videos to share on Video Window</string>
<key>NSMicrophoneUsageDescription</key>
<string>Record audio with your videos</string>
```

### Android (AndroidManifest.xml)

```xml
<!-- video_window_flutter/android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

---

## Basic Video Recording

```dart
// packages/features/publishing/lib/presentation/pages/record_story_page.dart
class RecordStoryPage extends StatefulWidget {
  @override
  State<RecordStoryPage> createState() => _RecordStoryPageState();
}

class _RecordStoryPageState extends State<RecordStoryPage> {
  CameraController? _controller;
  bool _isRecording = false;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    
    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,  // 720p
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    await _controller!.initialize();
    setState(() {});
  }
  
  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    await _controller!.startVideoRecording();
    setState(() => _isRecording = true);
  }
  
  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    final video = await _controller!.stopVideoRecording();
    setState(() => _isRecording = false);
    
    // Navigate to preview
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPreviewPage(videoPath: video.path),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(_controller!),
          
          // Recording indicator
          if (_isRecording)
            Positioned(
              top: 40,
              left: 16,
              child: Row(
                children: [
                  Icon(Icons.circle, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text('Recording', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          
          // Record button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red : Colors.white,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
```

---

## Advanced Features

### 1. Resolution Presets

```dart
// Video Window uses ResolutionPreset.high (720p)
final controller = CameraController(
  camera,
  ResolutionPreset.high,  // 720p - balance quality/file size
);

// Available presets:
// - ResolutionPreset.low (352x288)
// - ResolutionPreset.medium (480p)
// - ResolutionPreset.high (720p) ✅ Video Window default
// - ResolutionPreset.veryHigh (1080p)
// - ResolutionPreset.ultraHigh (4K)
```

### 2. Camera Switching

```dart
void _switchCamera() async {
  final cameras = await availableCameras();
  final newCamera = cameras.firstWhere(
    (c) => c.lensDirection != _controller!.description.lensDirection,
  );
  
  await _controller!.dispose();
  _controller = CameraController(newCamera, ResolutionPreset.high);
  await _controller!.initialize();
  setState(() {});
}
```

### 3. Zoom Control

```dart
double _currentZoom = 1.0;
double _maxZoom = 1.0;

@override
void initState() {
  super.initState();
  _initializeCamera().then((_) async {
    _maxZoom = await _controller!.getMaxZoomLevel();
  });
}

void _setZoom(double zoom) async {
  await _controller!.setZoomLevel(zoom.clamp(1.0, _maxZoom));
  setState(() => _currentZoom = zoom);
}
```

### 4. Flash Control

```dart
void _toggleFlash() async {
  final mode = _controller!.value.flashMode == FlashMode.off
      ? FlashMode.torch
      : FlashMode.off;
  
  await _controller!.setFlashMode(mode);
  setState(() {});
}
```

---

## Video Window Conventions

- **Resolution:** 720p (ResolutionPreset.high)
- **Max Duration:** 60 seconds (enforced in UI)
- **Orientation:** Portrait only (9:16 aspect ratio)
- **Audio:** Always enabled
- **Default Camera:** Back camera
- **File Format:** MP4 (H.264/AAC)

---

## Testing

```dart
testWidgets('RecordStoryPage shows camera preview', (tester) async {
  await tester.pumpWidget(MaterialApp(home: RecordStoryPage()));
  await tester.pumpAndSettle();
  
  expect(find.byType(CameraPreview), findsOneWidget);
  expect(find.byIcon(Icons.circle), findsOneWidget);  // Record button
});
```

---

## Reference

- **Package:** https://pub.dev/packages/camera
- **Flutter Camera:** https://docs.flutter.dev/cookbook/plugins/picture-using-camera

---

**Last Updated:** 2025-11-03 by Winston
