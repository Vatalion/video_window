# AWS S3 Storage Guide - Video Window

**Version:** AWS SDK Latest  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Video Storage (Epic 06)

---

## Overview

Amazon S3 stores Video Window's video files, HLS segments, and thumbnails with lifecycle policies.

---

## Dependencies

```yaml
# video_window_server/pubspec.yaml
dependencies:
  aws_s3_api: ^2.0.0
```

---

## S3 Service Setup

```dart
// video_window_server/lib/src/services/s3_service.dart
import 'package:aws_s3_api/s3-2006-03-01.dart';

class S3Service {
  final S3 _s3;
  final String _bucketName;
  
  S3Service(String region, this._bucketName)
      : _s3 = S3(
          region: region,
          credentials: AwsClientCredentials(
            accessKey: _getEnvVar('AWS_ACCESS_KEY_ID'),
            secretKey: _getEnvVar('AWS_SECRET_ACCESS_KEY'),
          ),
        );
  
  static String _getEnvVar(String key) {
    final value = Platform.environment[key];
    if (value == null) throw MissingEnvVarException(key);
    return value;
  }
}
```

---

## Upload Patterns

### 1. Simple Upload (Small Files)

```dart
Future<String> uploadFile(
  String localPath,
  String s3Key,
  {String? contentType},
) async {
  final file = File(localPath);
  final bytes = await file.readAsBytes();
  
  await _s3.putObject(
    bucket: _bucketName,
    key: s3Key,
    body: bytes,
    contentType: contentType ?? 'application/octet-stream',
  );
  
  return 'https://$_bucketName.s3.amazonaws.com/$s3Key';
}
```

### 2. Multipart Upload (Large Videos)

```dart
Future<String> uploadLargeFile(
  String localPath,
  String s3Key,
  {void Function(double)? onProgress},
) async {
  final file = File(localPath);
  final fileSize = await file.length();
  const chunkSize = 5 * 1024 * 1024; // 5MB chunks
  
  // Initialize multipart upload
  final initResponse = await _s3.createMultipartUpload(
    bucket: _bucketName,
    key: s3Key,
    contentType: 'video/mp4',
  );
  
  final uploadId = initResponse.uploadId!;
  final parts = <CompletedPart>[];
  
  try {
    // Upload chunks
    var partNumber = 1;
    var offset = 0;
    
    while (offset < fileSize) {
      final end = (offset + chunkSize < fileSize)
          ? offset + chunkSize
          : fileSize;
      
      final chunk = await file.openRead(offset, end).toList();
      final chunkBytes = chunk.expand((x) => x).toList();
      
      final uploadResponse = await _s3.uploadPart(
        bucket: _bucketName,
        key: s3Key,
        uploadId: uploadId,
        partNumber: partNumber,
        body: Uint8List.fromList(chunkBytes),
      );
      
      parts.add(CompletedPart(
        eTag: uploadResponse.eTag,
        partNumber: partNumber,
      ));
      
      offset = end;
      partNumber++;
      
      onProgress?.call(offset / fileSize);
    }
    
    // Complete multipart upload
    await _s3.completeMultipartUpload(
      bucket: _bucketName,
      key: s3Key,
      uploadId: uploadId,
      multipartUpload: CompletedMultipartUpload(parts: parts),
    );
    
    return 'https://$_bucketName.s3.amazonaws.com/$s3Key';
  } catch (e) {
    // Abort on error
    await _s3.abortMultipartUpload(
      bucket: _bucketName,
      key: s3Key,
      uploadId: uploadId,
    );
    rethrow;
  }
}
```

### 3. Presigned URL (Direct Client Upload)

```dart
Future<String> generatePresignedUploadUrl(
  String s3Key,
  Duration expiresIn,
) async {
  return _s3.getSignedUrl(
    bucket: _bucketName,
    key: s3Key,
    expiresIn: expiresIn,
    method: 'PUT',
  );
}

// Client-side upload (Flutter)
Future<void> uploadToPresignedUrl(String url, File file) async {
  final bytes = await file.readAsBytes();
  
  await http.put(
    Uri.parse(url),
    body: bytes,
    headers: {'Content-Type': 'video/mp4'},
  );
}
```

---

## Download Patterns

### 1. Presigned Download URL

```dart
Future<String> generatePresignedDownloadUrl(
  String s3Key,
  Duration expiresIn,
) async {
  return _s3.getSignedUrl(
    bucket: _bucketName,
    key: s3Key,
    expiresIn: expiresIn,
    method: 'GET',
  );
}
```

### 2. Direct Download

```dart
Future<void> downloadFile(String s3Key, String localPath) async {
  final response = await _s3.getObject(
    bucket: _bucketName,
    key: s3Key,
  );
  
  final file = File(localPath);
  await file.writeAsBytes(response.body!);
}
```

---

## Object Management

### List Objects

```dart
Future<List<String>> listObjects(String prefix) async {
  final response = await _s3.listObjectsV2(
    bucket: _bucketName,
    prefix: prefix,
  );
  
  return response.contents?.map((obj) => obj.key!).toList() ?? [];
}
```

### Delete Object

```dart
Future<void> deleteObject(String s3Key) async {
  await _s3.deleteObject(
    bucket: _bucketName,
    key: s3Key,
  );
}
```

### Copy Object

```dart
Future<void> copyObject(String sourceKey, String destKey) async {
  await _s3.copyObject(
    bucket: _bucketName,
    copySource: '$_bucketName/$sourceKey',
    key: destKey,
  );
}
```

---

## Lifecycle Policies

```json
{
  "Rules": [
    {
      "Id": "DeleteOldVideos",
      "Status": "Enabled",
      "Prefix": "stories/",
      "Expiration": {
        "Days": 90
      }
    },
    {
      "Id": "TransitionToGlacier",
      "Status": "Enabled",
      "Prefix": "archives/",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "GLACIER"
        }
      ]
    }
  ]
}
```

---

## Video Window S3 Structure

```
video-window-production/
├── stories/
│   └── {story_id}/
│       ├── original.mp4
│       ├── thumbnail.jpg
│       └── hls/
│           ├── master.m3u8
│           ├── 360p/
│           │   ├── index.m3u8
│           │   └── segment_*.ts
│           ├── 480p/
│           └── 720p/
├── user-uploads/
│   └── {user_id}/
│       └── {upload_id}.mp4
└── temp/
    └── {session_id}/
```

---

## Conventions

- **Bucket Naming:** `video-window-{environment}` (e.g., `video-window-production`)
- **Region:** `us-east-1`
- **Storage Class:** Standard (hot data), Glacier (archives)
- **Lifecycle:** 90 days retention for stories
- **Multipart Threshold:** 5MB chunks
- **Presigned URL Expiry:** 1 hour (downloads), 15 minutes (uploads)

---

## Security

```dart
// Server-side encryption
await _s3.putObject(
  bucket: _bucketName,
  key: s3Key,
  body: bytes,
  serverSideEncryption: ServerSideEncryption.aes256,
);

// Access control
await _s3.putObject(
  bucket: _bucketName,
  key: s3Key,
  body: bytes,
  acl: ObjectCannedACL.private,  // Never public
);
```

---

## Testing

```dart
test('S3Service uploads and downloads file', () async {
  final service = S3Service('us-east-1', 'test-bucket');
  final testFile = File('test.mp4');
  await testFile.writeAsString('test data');
  
  // Upload
  await service.uploadFile(
    testFile.path,
    'test/upload.mp4',
  );
  
  // Download
  await service.downloadFile(
    'test/upload.mp4',
    'test_download.mp4',
  );
  
  expect(File('test_download.mp4').existsSync(), isTrue);
});
```

---

## Reference

- **AWS S3 Docs:** https://docs.aws.amazon.com/s3/
- **S3 API:** https://docs.aws.amazon.com/AmazonS3/latest/API/

---

**Last Updated:** 2025-11-03 by Winston
