# FFmpeg Transcoding Guide - Video Window

**Version:** FFmpeg 6.0+  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Video Processing (Epic 06)

---

## Overview

FFmpeg handles video transcoding, format conversion, and watermarking in Video Window's server-side pipeline.

---

## Installation (Server)

```dockerfile
# video_window_server/Dockerfile
FROM dart:3.9.2

# Install FFmpeg
RUN apt-get update && apt-get install -y ffmpeg

# Verify installation
RUN ffmpeg -version
```

---

## Core Transcoding Patterns

### 1. MP4 to HLS (Multi-Bitrate)

```dart
// video_window_server/lib/src/services/ffmpeg_service.dart
class FFmpegService {
  Future<void> transcodeToHls(
    String inputPath,
    String outputDir,
  ) async {
    // 720p variant
    await _runFFmpeg([
      '-i', inputPath,
      '-vf', 'scale=1280:720',
      '-c:v', 'libx264',
      '-b:v', '2800k',
      '-c:a', 'aac',
      '-b:a', '128k',
      '-hls_time', '10',
      '-hls_list_size', '0',
      '-hls_segment_filename', '$outputDir/720p/segment_%03d.ts',
      '$outputDir/720p/index.m3u8',
    ]);
    
    // 480p variant
    await _runFFmpeg([
      '-i', inputPath,
      '-vf', 'scale=842:480',
      '-c:v', 'libx264',
      '-b:v', '1400k',
      '-c:a', 'aac',
      '-b:a', '128k',
      '-hls_time', '10',
      '-hls_list_size', '0',
      '-hls_segment_filename', '$outputDir/480p/segment_%03d.ts',
      '$outputDir/480p/index.m3u8',
    ]);
    
    // 360p variant
    await _runFFmpeg([
      '-i', inputPath,
      '-vf', 'scale=640:360',
      '-c:v', 'libx264',
      '-b:v', '800k',
      '-c:a', 'aac',
      '-b:a', '128k',
      '-hls_time', '10',
      '-hls_list_size', '0',
      '-hls_segment_filename', '$outputDir/360p/segment_%03d.ts',
      '$outputDir/360p/index.m3u8',
    ]);
  }
  
  Future<void> _runFFmpeg(List<String> args) async {
    final result = await Process.run('ffmpeg', args);
    
    if (result.exitCode != 0) {
      throw FFmpegException(
        'FFmpeg failed: ${result.stderr}',
        exitCode: result.exitCode,
      );
    }
  }
}
```

---

## Watermarking

### Dynamic Text Watermark

```dart
Future<void> addWatermark(
  String inputPath,
  String outputPath,
  String watermarkText,
) async {
  await _runFFmpeg([
    '-i', inputPath,
    '-vf', '''
      drawtext=text='$watermarkText':
      fontsize=24:
      fontcolor=white@0.5:
      x=w-tw-10:
      y=h-th-10:
      fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
    ''',
    '-c:v', 'libx264',
    '-preset', 'medium',
    '-crf', '23',
    '-c:a', 'copy',
    outputPath,
  ]);
}
```

### Image Watermark Overlay

```dart
Future<void> addImageWatermark(
  String inputPath,
  String outputPath,
  String watermarkImagePath,
) async {
  await _runFFmpeg([
    '-i', inputPath,
    '-i', watermarkImagePath,
    '-filter_complex', '''
      [1:v]scale=120:-1[watermark];
      [0:v][watermark]overlay=W-w-10:H-h-10
    ''',
    '-c:v', 'libx264',
    '-c:a', 'copy',
    outputPath,
  ]);
}
```

---

## Video Metadata Extraction

```dart
Future<VideoMetadata> extractMetadata(String videoPath) async {
  final result = await Process.run('ffprobe', [
    '-v', 'quiet',
    '-print_format', 'json',
    '-show_format',
    '-show_streams',
    videoPath,
  ]);
  
  if (result.exitCode != 0) {
    throw FFprobeException('Failed to extract metadata');
  }
  
  final json = jsonDecode(result.stdout);
  final videoStream = (json['streams'] as List)
      .firstWhere((s) => s['codec_type'] == 'video');
  
  return VideoMetadata(
    duration: double.parse(json['format']['duration']),
    width: videoStream['width'],
    height: videoStream['height'],
    codec: videoStream['codec_name'],
    bitrate: int.parse(json['format']['bit_rate']),
  );
}
```

---

## Thumbnail Generation

```dart
Future<String> generateThumbnail(
  String videoPath,
  String outputPath,
  {double atSecond = 1.0},
) async {
  await _runFFmpeg([
    '-i', videoPath,
    '-ss', atSecond.toString(),
    '-vframes', '1',
    '-vf', 'scale=640:360',
    outputPath,
  ]);
  
  return outputPath;
}
```

---

## Format Conversion

```dart
Future<void> convertToMp4(String inputPath, String outputPath) async {
  await _runFFmpeg([
    '-i', inputPath,
    '-c:v', 'libx264',
    '-preset', 'medium',
    '-crf', '23',
    '-c:a', 'aac',
    '-b:a', '128k',
    '-movflags', '+faststart',  // Web optimization
    outputPath,
  ]);
}
```

---

## Video Clipping

```dart
Future<void> clipVideo(
  String inputPath,
  String outputPath,
  Duration start,
  Duration duration,
) async {
  await _runFFmpeg([
    '-i', inputPath,
    '-ss', start.inSeconds.toString(),
    '-t', duration.inSeconds.toString(),
    '-c', 'copy',  // No re-encoding
    outputPath,
  ]);
}
```

---

## Performance Optimization

```dart
// Use hardware acceleration (if available)
Future<void> transcodeWithHardwareAccel(
  String inputPath,
  String outputPath,
) async {
  await _runFFmpeg([
    '-hwaccel', 'auto',  // Auto-detect GPU
    '-i', inputPath,
    '-c:v', 'h264_nvenc',  // NVIDIA GPU encoding
    '-preset', 'fast',
    '-b:v', '2800k',
    '-c:a', 'aac',
    outputPath,
  ]);
}

// Multi-threaded processing
Future<void> transcodeMultiThreaded(
  String inputPath,
  String outputPath,
) async {
  await _runFFmpeg([
    '-i', inputPath,
    '-threads', '4',  // Use 4 CPU threads
    '-c:v', 'libx264',
    '-preset', 'fast',
    outputPath,
  ]);
}
```

---

## Video Window Conventions

- **Codec:** H.264 (libx264)
- **Audio:** AAC 128kbps
- **Preset:** medium (balance speed/quality)
- **CRF:** 23 (constant rate factor)
- **HLS Segment:** 10 seconds
- **Watermark:** Bottom-right, 50% opacity
- **Max Resolution:** 720p (1280x720)

---

## Error Handling

```dart
class FFmpegException implements Exception {
  final String message;
  final int exitCode;
  
  FFmpegException(this.message, {required this.exitCode});
  
  @override
  String toString() => 'FFmpegException: $message (exit code: $exitCode)';
}

Future<void> transcodeWithRetry(
  String input,
  String output,
  {int maxRetries = 3},
) async {
  for (var i = 0; i < maxRetries; i++) {
    try {
      await transcodeToHls(input, output);
      return;
    } on FFmpegException catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: 2 * (i + 1)));
    }
  }
}
```

---

## Testing

```dart
test('FFmpeg generates HLS with 3 bitrates', () async {
  await ffmpegService.transcodeToHls(
    'test_input.mp4',
    '/tmp/output',
  );
  
  expect(File('/tmp/output/720p/index.m3u8').existsSync(), isTrue);
  expect(File('/tmp/output/480p/index.m3u8').existsSync(), isTrue);
  expect(File('/tmp/output/360p/index.m3u8').existsSync(), isTrue);
});
```

---

## Reference

- **FFmpeg Docs:** https://ffmpeg.org/documentation.html
- **H.264 Encoding:** https://trac.ffmpeg.org/wiki/Encode/H.264
- **HLS Guide:** https://trac.ffmpeg.org/wiki/EncodingForStreamingSites

---

**Last Updated:** 2025-11-03 by Winston
