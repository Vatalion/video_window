# HLS Streaming Guide - Video Window

**Version:** HLS RFC 8216  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Video Delivery (Epic 06)

---

## Overview

HTTP Live Streaming (HLS) delivers adaptive bitrate video to Video Window clients via CloudFront CDN.

---

## Architecture

```
MP4 Upload → FFmpeg Transcoding → HLS Segments → S3 → CloudFront → video_player
            (video_window_server)   (.ts + .m3u8)
```

---

## HLS Manifest Structure

### Master Playlist (Multi-Bitrate)

```m3u8
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360
360p/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1400000,RESOLUTION=842x480
480p/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2800000,RESOLUTION=1280x720
720p/index.m3u8
```

### Media Playlist (Single Bitrate)

```m3u8
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:10
#EXT-X-MEDIA-SEQUENCE:0
#EXTINF:10.0,
segment_0.ts
#EXTINF:10.0,
segment_1.ts
#EXTINF:10.0,
segment_2.ts
#EXT-X-ENDLIST
```

---

## FFmpeg Transcoding (Server)

```dart
// video_window_server/lib/src/services/video_processing_service.dart
class VideoProcessingService {
  Future<HlsOutput> transcodeToHls(String inputPath, String storyId) async {
    final outputDir = '/tmp/hls_output/$storyId';
    await Directory(outputDir).create(recursive: true);
    
    // Transcode to 3 bitrates (360p, 480p, 720p)
    await _transcodeVariant(inputPath, outputDir, '360p', '640x360', '800k');
    await _transcodeVariant(inputPath, outputDir, '480p', '842x480', '1400k');
    await _transcodeVariant(inputPath, outputDir, '720p', '1280x720', '2800k');
    
    // Generate master playlist
    await _generateMasterPlaylist(outputDir);
    
    // Upload to S3
    final s3Prefix = 'stories/$storyId/hls';
    await _uploadToS3(outputDir, s3Prefix);
    
    return HlsOutput(
      masterPlaylistUrl: 'https://cdn.videowindow.app/$s3Prefix/master.m3u8',
    );
  }
  
  Future<void> _transcodeVariant(
    String input,
    String outputDir,
    String name,
    String resolution,
    String bitrate,
  ) async {
    final result = await Process.run('ffmpeg', [
      '-i', input,
      '-vf', 'scale=$resolution',
      '-c:v', 'libx264',
      '-b:v', bitrate,
      '-c:a', 'aac',
      '-b:a', '128k',
      '-hls_time', '10',
      '-hls_list_size', '0',
      '-hls_segment_filename', '$outputDir/$name/segment_%03d.ts',
      '$outputDir/$name/index.m3u8',
    ]);
    
    if (result.exitCode != 0) {
      throw VideoTranscodingException(result.stderr);
    }
  }
  
  Future<void> _generateMasterPlaylist(String outputDir) async {
    final manifest = '''
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360
360p/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1400000,RESOLUTION=842x480
480p/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2800000,RESOLUTION=1280x720
720p/index.m3u8
''';
    
    await File('$outputDir/master.m3u8').writeAsString(manifest);
  }
}
```

---

## CloudFront Signed URLs

```dart
// video_window_server/lib/src/services/cloudfront_signer.dart
import 'package:cloudfront_signer/cloudfront_signer.dart';

class CloudFrontSigner {
  final CloudFrontSignerService _signer;
  
  CloudFrontSigner(String keyPairId, String privateKey)
      : _signer = CloudFrontSignerService(
          keyPairId: keyPairId,
          privateKey: privateKey,
        );
  
  Future<String> getSignedUrl(String url, {required Duration expiresIn}) async {
    final expiry = DateTime.now().add(expiresIn);
    
    return _signer.getSignedUrl(
      url: url,
      expireTime: expiry.millisecondsSinceEpoch ~/ 1000,
    );
  }
}
```

---

## Client Playback

```dart
// video_player handles HLS automatically
final controller = VideoPlayerController.networkUrl(
  Uri.parse('https://cdn.videowindow.app/stories/123/hls/master.m3u8'),
  httpHeaders: {
    'Authorization': 'Bearer $token',
  },
);

await controller.initialize();
controller.play();

// ABR happens automatically based on network conditions
```

---

## Watermarking

```dart
// Add watermark during FFmpeg transcoding
Future<void> _transcodeWithWatermark(
  String input,
  String output,
  String watermarkText,
) async {
  await Process.run('ffmpeg', [
    '-i', input,
    '-vf', '''
      drawtext=text='$watermarkText':
      fontsize=24:
      fontcolor=white@0.5:
      x=w-tw-10:
      y=h-th-10
    ''',
    '-c:v', 'libx264',
    '-c:a', 'copy',
    output,
  ]);
}
```

---

## Video Window Conventions

- **Segment Duration:** 10 seconds
- **Bitrates:** 360p (800k), 480p (1.4M), 720p (2.8M)
- **Codec:** H.264 (video), AAC (audio)
- **Signed URLs:** 1-hour expiry
- **CDN:** CloudFront with origin access identity
- **Storage:** S3 with lifecycle policy (90 days)

---

## Testing

```dart
test('HLS manifest has 3 bitrate variants', () async {
  final manifest = await File('master.m3u8').readAsString();
  
  expect(manifest, contains('360p/index.m3u8'));
  expect(manifest, contains('480p/index.m3u8'));
  expect(manifest, contains('720p/index.m3u8'));
});
```

---

## Reference

- **HLS RFC:** https://datatracker.ietf.org/doc/html/rfc8216
- **FFmpeg HLS:** https://ffmpeg.org/ffmpeg-formats.html#hls-2
- **Apple HLS:** https://developer.apple.com/streaming/

---

**Last Updated:** 2025-11-03 by Winston
