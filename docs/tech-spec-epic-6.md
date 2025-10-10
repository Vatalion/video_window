# Epic 6: Media Pipeline & Content Protection - Technical Specification

**Epic Goal:** Implement a secure, scalable media pipeline for video ingestion, transcoding, storage, and delivery with comprehensive content protection including DRM, watermarking, and anti-piracy measures.

**Stories:**
- 6.1: Media Pipeline & Content Protection Implementation
- 6.2: Advanced Video Processing & Optimization
- 6.3: Content Security & Anti-Piracy System

## Architecture Overview

### Component Mapping
- **Flutter App:** Media Upload Module, Secure Video Player, DRM Integration
- **Serverpod:** Media Processing Service, Content Protection Service, DRM License Service
- **AWS Infrastructure:** S3 Storage, CloudFront CDN, MediaConvert, Elemental DRM
- **External Services:** Widevine, FairPlay, PlayReady, Anti-piracy monitoring

### Technology Stack
- **Video Processing:** AWS MediaConvert, FFmpeg, HLS adaptive streaming
- **Content Protection:** AES-256-GCM encryption, Widevine DRM, FairPlay Streaming, PlayReady
- **Storage:** AWS S3 with intelligent tiering, CloudFront CDN with signed URLs
- **Security:** Hardware Security Modules (HSM), forensic watermarking, content fingerprinting
- **Monitoring:** AWS CloudWatch, anti-piracy detection, audit logging

## Data Models

### Media Asset Entity
```dart
class MediaAsset {
  final String id;
  final String title;
  final String description;
  final String uploaderId;
  final MediaStatus status;
  final VideoMetadata metadata;
  final List<MediaVariant> variants;
  final ContentProtection protection;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
}

enum MediaStatus {
  uploading,
  processing,
  transcoding,
  protecting,
  ready,
  failed,
  expired
}

class VideoMetadata {
  final Duration duration;
  final int width;
  final int height;
  final double bitrate;
  final String codec;
  final String format;
  final double frameRate;
  final List<String> thumbnails;
  final String fingerprint;
}

class MediaVariant {
  final String id;
  final String quality; // 480p, 720p, 1080p, 4K
  final int bitrate;
  final String format; // HLS, DASH
  final String encryptionKeyId;
  final String manifestUrl;
  final int sizeBytes;
}
```

### Content Protection Entity
```dart
class ContentProtection {
  final String id;
  final String assetId;
  final ProtectionType type;
  final String encryptionKeyId;
  final DRMConfiguration drmConfig;
  final WatermarkConfig watermarkConfig;
  final AccessPolicy accessPolicy;
  final DateTime createdAt;
}

enum ProtectionType {
  aesEncryption,
  widevine,
  fairplay,
  playready,
  multiDrm
}

class DRMConfiguration {
  final String widevineKeyId;
  final String fairplayKeyId;
  final String playreadyKeyId;
  final LicenseServerConfig licenseServer;
  final DeviceBinding deviceBinding;
  final UsagePolicy usagePolicy;
}

class WatermarkConfig {
  final String watermarkId;
  final WatermarkType type;
  final WatermarkPosition position;
  final double opacity;
  final bool isForensic;
  final Map<String, dynamic> userSpecificData;
}

enum WatermarkType {
  visible,
  invisible,
  forensic,
  dynamic
}
```

### Content Access Log Entity
```dart
class ContentAccessLog {
  final String id;
  final String assetId;
  final String userId;
  final String sessionId;
  final String ipAddress;
  final String userAgent;
  final GeoLocation location;
  final AccessAction action;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
}

enum AccessAction {
  streamStart,
  streamProgress,
  streamComplete,
  downloadAttempt,
  sharingAttempt,
  suspiciousActivity
}

class GeoLocation {
  final String country;
  final String region;
  final String city;
  final double latitude;
  final double longitude;
}
```

## API Endpoints

### Media Upload Endpoints
```
POST /media/upload/initiate
PUT /media/upload/chunk
POST /media/upload/complete
POST /media/upload/abort
GET /media/upload/status/{uploadId}
```

### Media Processing Endpoints
```
POST /media/process/{assetId}
GET /media/process/{assetId}/status
POST /media/process/{assetId}/cancel
GET /media/{assetId}/metadata
GET /media/{assetId}/variants
```

### Content Protection Endpoints
```
POST /media/{assetId}/protect
GET /media/{assetId}/protection/status
POST /drm/license
GET /media/{assetId}/stream-url
POST /media/{assetId}/watermark
```

### Content Monitoring Endpoints
```
GET /media/{assetId}/access-logs
POST /media/{assetId}/access-report
GET /security/piracy-detection
POST /security/dmca-takedown
```

### Endpoint Specifications

#### Initiate Media Upload
```dart
// Request
{
  "filename": "product_demo.mp4",
  "fileSize": 52428800,
  "mimeType": "video/mp4",
  "metadata": {
    "title": "Product Demo",
    "description": "Demo video for product auction",
    "tags": ["demo", "product"]
  }
}

// Response
{
  "uploadId": "upload_123456789",
  "uploadUrl": "https://s3.amazonaws.com/bucket/upload-path",
  "chunkSize": 5242880,
  "totalChunks": 10,
  "expiresAt": "2025-01-09T12:00:00Z"
}
```

#### Generate Secure Stream URL
```dart
// Request
{
  "assetId": "asset_123456789",
  "quality": "1080p",
  "userId": "user_123456789",
  "sessionId": "session_123456789"
}

// Response
{
  "streamUrl": "https://cdn.example.com/hls/asset_123456789.m3u8",
  "licenseUrl": "https://license.example.com/license",
  "expiresAt": "2025-01-09T11:30:00Z",
  "watermarkId": "watermark_123456789",
  "drmType": "widevine"
}
```

#### DRM License Request
```dart
// Request
{
  "assetId": "asset_123456789",
  "userId": "user_123456789",
  "deviceId": "device_123456789",
  "drmType": "widevine",
  "clientData": {
    "chromecast": false,
    "hdcp": true,
    "resolution": "1080p"
  }
}

// Response
{
  "license": "base64_encoded_license_data",
  "expiration": "2025-01-09T12:00:00Z",
  "usagePolicy": {
    "maxResolution": "1080p",
    "playbackDuration": 3600,
    "concurrentStreams": 1
  }
}
```

## Implementation Details

### Media Upload Pipeline

#### Secure Upload Flow
1. **Upload Initiation:** Client requests upload URL with metadata validation
2. **Chunked Upload:** Multipart upload with resumable transfer capability
3. **Virus Scanning:** ClamAV integration for malware detection
4. **Metadata Extraction:** FFmpeg analysis for technical specifications
5. **Content Validation:** Policy compliance and copyright checking

#### Upload Service Implementation
```dart
class MediaUploadService {
  final S3Service _s3Service;
  final VirusScanningService _virusService;
  final MetadataExtractionService _metadataService;
  final ValidationService _validationService;

  Future<UploadInitiationResponse> initiateUpload(
    UploadRequest request,
    User user
  ) async {
    // Validate upload permissions
    await _validationService.validateUploadPermission(user);

    // Validate file constraints
    await _validationService.validateFileConstraints(request);

    // Generate secure upload URL
    final uploadUrl = await _s3Service.generatePresignedUploadUrl(
      key: 'uploads/${user.id}/${request.filename}',
      contentType: request.mimeType,
      expiresIn: Duration(hours: 2),
      contentLength: request.fileSize,
    );

    // Create upload record
    final upload = await _uploadRepository.create(UploadRecord(
      id: _generateUploadId(),
      userId: user.id,
      filename: request.filename,
      fileSize: request.fileSize,
      mimeType: request.mimeType,
      status: UploadStatus.initiated,
      expiresAt: DateTime.now().add(Duration(hours: 2)),
    ));

    return UploadInitiationResponse(
      uploadId: upload.id,
      uploadUrl: uploadUrl,
      chunkSize: 5 * 1024 * 1024, // 5MB chunks
      totalChunks: (request.fileSize / (5 * 1024 * 1024)).ceil(),
      expiresAt: upload.expiresAt,
    );
  }

  Future<void> completeUpload(String uploadId, User user) async {
    final upload = await _uploadRepository.findById(uploadId);
    if (upload == null || upload.userId != user.id) {
      throw UploadException('Upload not found');
    }

    // Verify all chunks uploaded
    final allChunksUploaded = await _s3Service.verifyMultipartUpload(uploadId);
    if (!allChunksUploaded) {
      throw UploadException('Upload incomplete');
    }

    // Complete multipart upload
    final objectKey = await _s3Service.completeMultipartUpload(uploadId);

    // Move to processing queue
    await _queueProcessingJob(upload, objectKey);

    // Update upload status
    upload.status = UploadStatus.completed;
    upload.completedAt = DateTime.now();
    await _uploadRepository.update(upload);
  }
}
```

### Video Transcoding Pipeline

#### Multi-Bitrate Transcoding
```dart
class VideoTranscodingService {
  final AWSMediaConvert _mediaConvert;
  final S3Service _s3Service;
  final ThumbnailGenerationService _thumbnailService;

  Future<void> transcodeVideo(String assetId, String sourceKey) async {
    final asset = await _assetRepository.findById(assetId);
    if (asset == null) throw AssetNotFoundException();

    // Create transcoding job
    final job = await _mediaConvert.createJob(JobSettings(
      role: 'arn:aws:iam::account:role/MediaConvertRole',
      settings: _buildTranscodingSettings(asset, sourceKey),
      userMetadata: {
        'assetId': assetId,
        'userId': asset.uploaderId,
      },
    ));

    // Update asset status
    asset.status = MediaStatus.transcoding;
    asset.transcodingJobId = job.id;
    await _assetRepository.update(asset);

    // Monitor job progress
    _monitorTranscodingJob(job.id, assetId);
  }

  JobSettings _buildTranscodingSettings(MediaAsset asset, String sourceKey) {
    return JobSettings(
      inputs: [
        Input(
          fileInput: "s3://bucket/$sourceKey",
          inputScanType: InputScanType.auto,
        ),
      ],
      outputGroups: [
        // HLS Multi-bitrate output
        OutputGroup(
          name: 'HLS Output Group',
          outputs: [
            _buildHLSOutput('480p', 1000000),
            _buildHLSOutput('720p', 2500000),
            _buildHLSOutput('1080p', 5000000),
            _buildHLSOutput('4K', 15000000),
          ],
          outputGroupSettings: OutputGroupSettings(
            type: OutputGroupType.hlsGroupSettings,
            hlsGroupSettings: HLSGroupSettings(
              destination: "s3://bucket/processed/${asset.id}/hls/",
              segmentLength: 6,
              minSegmentLength: 0,
              targetDurationCompatibility: 'LEGACY',
            ),
          ),
        ),
        // Thumbnail output
        OutputGroup(
          name: 'Thumbnail Output Group',
          outputs: [_buildThumbnailOutput()],
          outputGroupSettings: OutputGroupSettings(
            type: OutputGroupType.fileGroupSettings,
            fileGroupSettings: FileGroupSettings(
              destination: "s3://bucket/processed/${asset.id}/thumbnails/",
            ),
          ),
        ),
      ],
    );
  }

  Output _buildHLSOutput(String quality, int bitrate) {
    return Output(
      preset: 'System-Available', // Use custom settings
      videoDescription: VideoDescription(
        codecSettings: VideoCodecSettings(
          codec: 'H_264',
          h264Settings: H264Settings(
            rateControlMode: 'QVBR',
            qvbrSettings: QvbrSettings(
              qvbrQualityLevel: _getQualityLevel(quality),
            ),
            maxBitrate: bitrate,
            bitrate: bitrate,
          ),
        ),
        width: _getWidth(quality),
        height: _getHeight(quality),
      ),
      audioDescriptions: [
        AudioDescription(
          codecSettings: AudioCodecSettings(
            codec: 'AAC',
            aacSettings: AacSettings(
              bitrate: 128000,
              sampleRate: 48000,
              codingMode: 'CODING_MODE_2_0',
            ),
          ),
        ),
      ],
      containerSettings: ContainerSettings(
        container: 'TS',
        tsSettings: TsSettings(
          audioPids: '1',
          videoPid: '2',
        ),
      ),
      nameModifier: "_$quality",
      encryption: EncryptionSettings(
        encryptionType: 'AES_CTR',
        spekeKeyProvider: SpekeKeyProvider(
          url: 'https://key-provider.example.com/keys',
          roleArn: 'arn:aws:iam::account:role/SPEKEKeyProvider',
          systemIds: [
            'edef8ba9-79d6-4ace-a3c8-27dcd51d21ed', // Widevine
            '94ce86fb-07ff-4f43-adb8-93d2fa968ca2', // PlayReady
            '1077efecc0b24d02ace33c1e52e2fb4b', // FairPlay
          ],
        ),
      ),
    );
  }
}
```

### Content Protection Implementation

#### DRM License Service
```dart
class DRMLicenseService {
  final KeyManagementService _keyManagement;
  final UserService _userService;
  final SecurityLogger _logger;

  Future<DRMLicenseResponse> generateLicense(
    DRMLicenseRequest request,
    User user
  ) async {
    // Validate user access
    if (!await _userService.canAccessAsset(user.id, request.assetId)) {
      throw AccessDeniedException('User does not have access to this content');
    }

    // Get DRM keys
    final drmKeys = await _keyManagement.getDRMKeys(
      assetId: request.assetId,
      drmType: request.drmType,
    );

    // Apply usage policies
    final usagePolicy = await _applyUsagePolicy(user, request);

    // Generate device-specific license
    final license = await _generateDeviceSpecificLicense(
      drmKeys: drmKeys,
      deviceId: request.deviceId,
      usagePolicy: usagePolicy,
      drmType: request.drmType,
    );

    // Log license issuance
    await _logger.logSecurityEvent(
      type: SecurityEventType.drmLicenseIssued,
      userId: user.id,
      metadata: {
        'assetId': request.assetId,
        'drmType': request.drmType,
        'deviceId': request.deviceId,
        'licenseId': license.id,
      },
    );

    return DRMLicenseResponse(
      license: license.licenseData,
      expiration: usagePolicy.expiration,
      usagePolicy: usagePolicy,
    );
  }

  Future<DRMLicense> _generateDeviceSpecificLicense({
    required DRMKeys drmKeys,
    required String deviceId,
    required UsagePolicy usagePolicy,
    required DRMType drmType,
  }) async {
    switch (drmType) {
      case DRMType.widevine:
        return await _generateWidevineLicense(drmKeys, deviceId, usagePolicy);
      case DRMType.fairplay:
        return await _generateFairPlayLicense(drmKeys, deviceId, usagePolicy);
      case DRMType.playready:
        return await _generatePlayReadyLicense(drmKeys, deviceId, usagePolicy);
      default:
        throw DRMSupportException('Unsupported DRM type: $drmType');
    }
  }

  Future<DRMLicense> _generateWidevineLicense(
    DRMKeys drmKeys,
    String deviceId,
    UsagePolicy usagePolicy
  ) async {
    // Widevine license generation
    final widevineLicense = WidevineLicenseBuilder()
      ..setContentKey(drmKeys.contentKey)
      ..setKeyId(drmKeys.keyId)
      ..setDeviceId(deviceId)
      ..setUsagePolicy(usagePolicy)
      ..setSecurityLevel(2) // Hardware-backed
      ..setResolutionConstraint(usagePolicy.maxResolution)
      ..setPlaybackDuration(usagePolicy.playbackDuration)
      ..setConcurrentStreams(usagePolicy.concurrentStreams);

    final licenseData = await widevineLicense.build();

    return DRMLicense(
      id: _generateLicenseId(),
      licenseData: base64Encode(licenseData),
      drmType: DRMType.widevine,
      expiresAt: usagePolicy.expiration,
    );
  }
}
```

#### Forensic Watermarking Service
```dart
class ForensicWatermarkingService {
  final VideoProcessingService _videoProcessing;
  final WatermarkKeyManagement _keyManagement;

  Future<WatermarkResult> embedWatermark(
    String assetId,
    String userId,
    String sessionId
  ) async {
    // Generate user-specific watermark key
    final watermarkKey = await _keyManagement.generateWatermarkKey(
      assetId: assetId,
      userId: userId,
      sessionId: sessionId,
    );

    // Extract watermark payload
    final watermarkPayload = _generateWatermarkPayload(
      userId: userId,
      sessionId: sessionId,
      timestamp: DateTime.now(),
    );

    // Embed watermark in video
    final watermarkedVideoPath = await _embedInvisibleWatermark(
      originalVideoPath: await _getOriginalVideoPath(assetId),
      watermarkKey: watermarkKey,
      payload: watermarkPayload,
    );

    // Store watermark metadata
    final watermarkMetadata = await _watermarkRepository.create(
      WatermarkMetadata(
        id: _generateWatermarkId(),
        assetId: assetId,
        userId: userId,
        sessionId: sessionId,
        keyId: watermarkKey.id,
        payload: watermarkPayload,
        embeddedAt: DateTime.now(),
      ),
    );

    return WatermarkResult(
      watermarkId: watermarkMetadata.id,
      watermarkedVideoUrl: watermarkedVideoPath,
      extractionKeyId: watermarkKey.extractionKeyId,
    );
  }

  String _generateWatermarkPayload({
    required String userId,
    required String sessionId,
    required DateTime timestamp,
  }) {
    final payload = {
      'userId': userId,
      'sessionId': sessionId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'checksum': _calculateChecksum(userId, sessionId, timestamp),
    };

    return _encodePayload(payload);
  }

  Future<String> _embedInvisibleWatermark({
    required String originalVideoPath,
    required WatermarkKey watermarkKey,
    required String payload,
  }) async {
    // Use DCT (Discrete Cosine Transform) watermarking
    return await _videoProcessing.applyWatermark(
      inputPath: originalVideoPath,
      outputPath: _generateWatermarkedPath(originalVideoPath),
      watermarkAlgorithm: WatermarkAlgorithm.dct,
      watermarkKey: watermarkKey.key,
      payload: payload,
      strength: 0.1, // Subtle but detectable
      redundancy: 5, // Embed in multiple frames
    );
  }

  Future<String?> extractWatermark(
    String videoPath,
    String extractionKeyId
  ) async {
    try {
      final watermarkKey = await _keyManagement.getExtractionKey(extractionKeyId);
      if (watermarkKey == null) return null;

      final extractedPayload = await _videoProcessing.extractWatermark(
        inputPath: videoPath,
        watermarkAlgorithm: WatermarkAlgorithm.dct,
        watermarkKey: watermarkKey.key,
      );

      final payload = _decodePayload(extractedPayload);
      if (_validatePayload(payload)) {
        return payload['userId'] as String;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
```

### Anti-Piracy Detection System

#### Content Fingerprinting
```dart
class ContentFingerprintingService {
  final FingerprintDatabase _fingerprintDatabase;
  final ExternalMonitoringService _monitoringService;

  Future<String> generateFingerprint(String videoPath) async {
    // Generate perceptual hash using robust video fingerprinting
    final fingerprints = await _extractVideoFingerprints(videoPath);

    // Create content signature
    final signature = _createContentSignature(fingerprints);

    // Store in database
    await _fingerprintDatabase.storeFingerprint(
      videoPath: videoPath,
      signature: signature,
      fingerprints: fingerprints,
    );

    return signature;
  }

  Future<List<FingerprintMatch>> detectMatches(String videoPath) async {
    final fingerprints = await _extractVideoFingerprints(videoPath);
    final signature = _createContentSignature(fingerprints);

    // Search for matches in database
    final matches = await _fingerprintDatabase.findMatches(signature);

    // Validate matches with frame-by-frame comparison
    final validatedMatches = <FingerprintMatch>[];
    for (final match in matches) {
      final similarity = await _calculateVideoSimilarity(
        videoPath,
        match.originalVideoPath,
      );

      if (similarity > 0.85) { // 85% similarity threshold
        validatedMatches.add(match.copyWith(similarity: similarity));
      }
    }

    return validatedMatches;
  }

  Future<void> monitorForPiracy(String assetId) async {
    // Monitor known piracy sites
    final piracySites = [
      'youtube.com',
      'vimeo.com',
      'dailymotion.com',
      'pornhub.com',
      'xvideos.com',
      'torrent sites',
    ];

    for (final site in piracySites) {
      await _monitoringService.searchSite(
        site: site,
        assetId: assetId,
        searchTerms: await _generateSearchTerms(assetId),
      );
    }
  }

  Future<List<String>> _generateSearchTerms(String assetId) async {
    final asset = await _assetRepository.findById(assetId);
    if (asset == null) return [];

    return [
      asset.title,
      asset.description,
      ...asset.metadata.thumbnails.map((t) => t),
      asset.uploaderId,
    ];
  }
}
```

#### Piracy Detection & Response
```dart
class PiracyDetectionService {
  final ContentFingerprintingService _fingerprinting;
  final TakedownService _takedownService;
  final SecurityLogger _logger;

  Future<void> scanForPiratedContent() async {
    // Get all active content
    final activeAssets = await _assetRepository.findActiveAssets();

    for (final asset in activeAssets) {
      await _scanAssetForPiracy(asset);
    }
  }

  Future<void> _scanAssetForPiracy(MediaAsset asset) async {
    try {
      // Monitor external platforms
      await _fingerprinting.monitorForPiracy(asset.id);

      // Check for unusual access patterns
      await _analyzeAccessPatterns(asset.id);

      // Detect screen recording attempts
      await _detectScreenRecordingAttempts(asset.id);

    } catch (e) {
      await _logger.logSecurityError(
        type: SecurityEventType.piracyScanFailed,
        assetId: asset.id,
        error: e.toString(),
      );
    }
  }

  Future<void> _analyzeAccessPatterns(String assetId) async {
    final recentAccess = await _accessLogRepository.getRecentAccess(
      assetId: assetId,
      timeWindow: Duration(hours: 24),
    );

    // Detect suspicious patterns
    final suspiciousPatterns = _detectSuspiciousPatterns(recentAccess);

    for (final pattern in suspiciousPatterns) {
      await _handleSuspiciousPattern(pattern);
    }
  }

  List<SuspiciousPattern> _detectSuspiciousPatterns(List<ContentAccessLog> accessLogs) {
    final patterns = <SuspiciousPattern>[];

    // Pattern 1: Multiple downloads from same IP
    final downloadsByIP = <String, int>{};
    for (final log in accessLogs) {
      if (log.action == AccessAction.downloadAttempt) {
        downloadsByIP[log.ipAddress] = (downloadsByIP[log.ipAddress] ?? 0) + 1;
      }
    }

    downloadsByIP.forEach((ip, count) {
      if (count > 5) { // More than 5 downloads from same IP
        patterns.add(SuspiciousPattern(
          type: SuspiciousPatternType.multipleDownloads,
          ipAddress: ip,
          count: count,
          severity: SuspicionLevel.high,
        ));
      }
    });

    // Pattern 2: Rapid successive access from different IPs
    final accessByUser = <String, List<ContentAccessLog>>{};
    for (final log in accessLogs) {
      accessByUser.putIfAbsent(log.userId, () => []).add(log);
    }

    accessByUser.forEach((userId, userAccess) {
      if (_isRapidAccessPattern(userAccess)) {
        patterns.add(SuspiciousPattern(
          type: SuspiciousPatternType.rapidAccess,
          userId: userId,
          count: userAccess.length,
          severity: SuspicionLevel.medium,
        ));
      }
    });

    return patterns;
  }

  Future<void> _handleSuspiciousPattern(SuspiciousPattern pattern) async {
    // Log security event
    await _logger.logSecurityEvent(
      type: SecurityEventType.suspiciousPatternDetected,
      metadata: {
        'patternType': pattern.type.toString(),
        'severity': pattern.severity.toString(),
        'count': pattern.count,
        'ipAddress': pattern.ipAddress,
        'userId': pattern.userId,
      },
    );

    // Take appropriate action based on severity
    switch (pattern.severity) {
      case SuspicionLevel.high:
        await _implementHighSecurityMeasures(pattern);
        break;
      case SuspicionLevel.medium:
        await _implementMediumSecurityMeasures(pattern);
        break;
      case SuspicionLevel.low:
        await _monitorPattern(pattern);
        break;
    }
  }

  Future<void> _implementHighSecurityMeasures(SuspiciousPattern pattern) async {
    // Block IP address if applicable
    if (pattern.ipAddress != null) {
      await _blockIpAddress(pattern.ipAddress!, Duration(days: 1));
    }

    // Require additional authentication for user
    if (pattern.userId != null) {
      await _requireAdditionalAuth(pattern.userId!);
    }

    // Alert security team
    await _alertSecurityTeam(pattern);
  }
}
```

## Security Implementation

### Encryption at Rest & In Transit
```dart
class ContentEncryptionService {
  final KeyManagementService _keyManagement;
  final EncryptionProvider _encryptionProvider;

  Future<EncryptedContent> encryptContent({
    required String contentPath,
    required String assetId,
  }) async {
    // Generate content encryption key (CEK)
    final contentKey = await _keyManagement.generateContentKey(assetId);

    // Encrypt content with CEK
    final encryptedContent = await _encryptionProvider.encryptFile(
      inputPath: contentPath,
      key: contentKey.key,
      algorithm: 'AES-256-GCM',
    );

    // Encrypt CEK with master key
    final encryptedContentKey = await _keyManagement.encryptContentKey(
      contentKey: contentKey,
    );

    return EncryptedContent(
      encryptedPath: encryptedContent.encryptedPath,
      contentKeyId: contentKey.id,
      encryptedContentKey: encryptedContentKey,
      iv: encryptedContent.iv,
      authTag: encryptedContent.authTag,
    );
  }

  Future<String> decryptContent({
    required String encryptedPath,
    required String contentKeyId,
    required String encryptedContentKey,
    required String iv,
    required String authTag,
  }) async {
    // Decrypt content key
    final contentKey = await _keyManagement.decryptContentKey(
      encryptedContentKey: encryptedContentKey,
      keyId: contentKeyId,
    );

    // Decrypt content
    final decryptedPath = await _encryptionProvider.decryptFile(
      inputPath: encryptedPath,
      key: contentKey.key,
      iv: iv,
      authTag: authTag,
      algorithm: 'AES-256-GCM',
    );

    return decryptedPath;
  }
}
```

### Secure CDN Delivery
```dart
class SecureCDNService {
  final CloudFrontService _cloudFront;
  final KeyManagementService _keyManagement;
  final DRMLicenseService _drmService;

  Future<SecureStreamURL> generateSecureStreamURL({
    required String assetId,
    required String userId,
    required String sessionId,
    required String quality,
  }) async {
    // Validate user access
    if (!await _validateUserAccess(userId, assetId)) {
      throw AccessDeniedException('User does not have access to this content');
    }

    // Generate DRM license URL
    final licenseUrl = await _drmService.generateLicenseURL(
      assetId: assetId,
      userId: userId,
      sessionId: sessionId,
    );

    // Generate signed CloudFront URL
    final signedURL = await _cloudFront.generateSignedURL(
      url: 'https://cdn.example.com/hls/$assetId/$quality/index.m3u8',
      expiration: DateTime.now().add(Duration(minutes: 30)),
      ipAddress: await _getUserIP(userId),
      activeTrustedSigners: ['cloudfront-key-pair-id'],
      privateKeyPath: 'path/to/private-key.pem',
    );

    // Add watermark parameters
    final watermarkParams = await _generateWatermarkParams(
      userId: userId,
      sessionId: sessionId,
    );

    return SecureStreamURL(
      streamUrl: signedURL,
      licenseUrl: licenseUrl,
      expiresAt: DateTime.now().add(Duration(minutes: 30)),
      watermarkParams: watermarkParams,
      drmType: await _getPreferredDRMType(userId),
    );
  }

  Future<bool> _validateUserAccess(String userId, String assetId) async {
    // Check purchase history
    final hasPurchased = await _purchaseRepository.hasUserPurchasedAsset(
      userId: userId,
      assetId: assetId,
    );

    // Check access permissions
    final hasPermission = await _permissionRepository.hasAccessPermission(
      userId: userId,
      assetId: assetId,
    );

    return hasPurchased || hasPermission;
  }

  Map<String, String> _generateWatermarkParams({
    required String userId,
    required String sessionId,
  }) {
    return {
      'watermark_id': _generateWatermarkId(userId, sessionId),
      'user_id': _obfuscateUserId(userId),
      'session_id': _obfuscateSessionId(sessionId),
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };
  }
}
```

## Testing Strategy

### Unit Tests
- **Media Upload Service:** Test upload initiation, chunk validation, and completion
- **Transcoding Service:** Test job creation, settings configuration, and progress monitoring
- **DRM Service:** Test license generation, key management, and usage policy enforcement
- **Watermarking Service:** Test watermark embedding, extraction, and payload validation
- **Encryption Service:** Test content encryption/decryption and key management

### Integration Tests
- **End-to-End Upload Flow:** Test complete pipeline from upload to streaming
- **DRM Integration:** Test multi-platform DRM license acquisition and playback
- **CDN Delivery:** Test signed URL generation and content access control
- **Anti-Piracy Detection:** Test content fingerprinting and piracy detection

### Security Tests
- **Content Protection:** Test DRM bypass attempts and watermark removal
- **Access Control:** Test unauthorized access attempts and privilege escalation
- **Data Protection:** Test encryption/decryption and key security
- **Anti-Piracy:** Test piracy detection effectiveness and false positive rates

### Performance Tests
- **Upload Performance:** Test concurrent uploads and large file handling
- **Transcoding Performance:** Test parallel transcoding and queue management
- **Streaming Performance:** Test concurrent streams and CDN performance
- **Watermarking Performance:** Test real-time watermarking and extraction

## Error Handling

### Error Types
```dart
abstract class MediaException implements Exception {
  final String message;
  final MediaErrorCode code;
}

class UploadException extends MediaException { }
class TranscodingException extends MediaException { }
class DRMException extends MediaException { }
class WatermarkingException extends MediaException { }
class PiracyDetectionException extends MediaException { }
```

### Error Recovery
- **Upload Failures:** Automatic retry with exponential backoff, resumable uploads
- **Transcoding Failures:** Automatic job restart, quality degradation fallback
- **DRM Failures:** Fallback to alternative DRM, license refresh mechanism
- **Watermarking Failures:** Non-blocking errors, logging for forensic analysis

## Performance Considerations

### Upload Optimizations
- **Chunked Uploads:** 5MB chunks for large files with resumable capability
- **Parallel Processing:** Multiple upload threads for concurrent uploads
- **Compression:** Client-side video compression before upload
- **Progress Tracking:** Real-time upload progress indicators

### Transcoding Optimizations
- **Parallel Jobs:** Multiple transcoding jobs running concurrently
- **Adaptive Bitrate:** Optimal bitrate selection based on content analysis
- **GPU Acceleration:** Hardware-accelerated transcoding where available
- **Smart Retry:** Intelligent retry strategies for failed jobs

### Streaming Optimizations
- **Edge Caching:** CDN edge caching for popular content
- **Pre-fetching:** Intelligent segment pre-fetching
- **Quality Adaptation:** Dynamic quality adjustment based on network conditions
- **Load Balancing:** Distributed load across multiple CDN edge locations

## Monitoring and Analytics

### Key Metrics
- **Upload Success Rate:** Percentage of successful uploads
- **Transcoding Time:** Average time from upload to ready state
- **Content Protection Success:** Rate of successful DRM license issuance
- **Piracy Detection:** Number of piracy incidents detected and resolved
- **Streaming Performance:** Buffer rate, startup time, and quality switches

### Logging Strategy
- **Structured JSON Logs:** Consistent logging format across all services
- **Security Events:** All security-related events with detailed context
- **Performance Metrics:** Transcoding and streaming performance data
- **Error Tracking:** Comprehensive error logging with stack traces

## Deployment Considerations

### Environment Variables
```dart
// AWS Configuration
AWS_REGION=us-east-1
S3_BUCKET_NAME=video-content-bucket
CLOUDFRONT_DISTRIBUTION_ID=E1234567890ABC
MEDIACONVERT_ROLE_ARN=arn:aws:iam::account:role/MediaConvertRole

// DRM Configuration
WIDEVINE_KEY_SERVER_URL=https://widevine-license.example.com
FAIRPLAY_KEY_SERVER_URL=https://fairplay-license.example.com
PLAYREADY_KEY_SERVER_URL=https://playready-license.example.com
DRM_PRIVATE_KEY_PATH=/path/to/drm-private-key.pem

// Security Configuration
HSM_ENDPOINT=https://hsm.example.com
ENCRYPTION_KEY_ID=content-encryption-key-id
WATERMARK_KEY_ID=watermark-key-id

// Monitoring Configuration
PIRACY_DETECTION_WEBHOOK=https://security.example.com/webhooks/piracy
SECURITY_ALERT_EMAIL=security@example.com
```

### Infrastructure Requirements
```yaml
# AWS MediaConvert Template
Resources:
  MediaConvertRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: mediaconvert.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonS3FullAccess
        - arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess

  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: video-content-bucket
      VersioningConfiguration:
        Status: Enabled
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true

  CloudFrontDistribution:
    Type: AWS::CloudFront::Distribution
    Properties:
      DistributionConfig:
        Origins:
          - Id: S3Origin
            DomainName: !GetAtt S3Bucket.DomainName
            S3OriginConfig:
              OriginAccessIdentity: !Sub 'origin-access-identity/cloudfront/${CloudFrontOAI}'
        DefaultCacheBehavior:
          TargetOriginId: S3Origin
          ViewerProtocolPolicy: redirect-to-https
          TrustedSigners:
            - Self
        Enabled: true
        HttpVersion: http2
```

## Success Criteria

### Functional Requirements
- ✅ Users can upload videos with secure, resumable transfers
- ✅ Videos are automatically transcoded to multiple bitrates
- ✅ Content is protected with multi-platform DRM and watermarking
- ✅ Secure streaming with signed URLs and access controls
- ✅ Anti-piracy detection and automated takedown workflows

### Non-Functional Requirements
- ✅ Upload completion within 5 minutes for 100MB files
- ✅ Transcoding completion within 10 minutes for 10-minute videos
- ✅ Stream startup time under 3 seconds
- ✅ 99.9% content protection success rate
- ✅ Piracy detection within 24 hours of infringement

### Success Metrics
- Upload success rate > 99%
- Transcoding success rate > 98%
- Content protection effectiveness > 99.5%
- Piracy detection accuracy > 95%
- User streaming experience score > 4.5/5

## Next Steps

1. **Implement Media Upload Pipeline** - Secure upload, validation, and processing queue
2. **Develop Transcoding Service** - AWS MediaConvert integration and job management
3. **Implement Content Protection** - DRM integration and watermarking system
4. **Set Up CDN Delivery** - CloudFront configuration and signed URL generation
5. **Build Anti-Piracy System** - Content fingerprinting and monitoring
6. **Comprehensive Testing** - Security testing, performance validation, and user acceptance testing

**Dependencies:** Epic 1 (Viewer Authentication) for user access control, Epic 2 (Maker Auth) for content ownership verification
**Blocks:** Epic 7 (Admin Analytics) for content performance analytics, Epic 8 (Mobile Experience) for native video player integration

---
*This technical specification provides the foundation for implementing a secure, scalable media pipeline with comprehensive content protection and anti-piracy measures.*