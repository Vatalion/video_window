# Epic 6: Media Pipeline & Content Protection - Technical Specification

**Epic Goal:** Implement a secure, scalable media pipeline for video ingestion, transcoding, storage, and delivery with comprehensive content protection including DRM, watermarking, and anti-piracy measures.

**Stories:**
- 6-1: Media Pipeline & Content Protection Implementation
- 6-2: Advanced Video Processing & Optimization
- 6-3: Content Security & Anti-Piracy System

## Architecture Overview

### Component Mapping
- **Flutter App:** Media Upload Module, Secure Video Player, DRM Integration
- **Serverpod:** Media Processing Service, Content Protection Service, DRM License Service
- **AWS Infrastructure:** S3 Storage, CloudFront CDN, MediaConvert, Elemental DRM
- **External Services:** Widevine, FairPlay, PlayReady, Anti-piracy monitoring

### Technology Stack
- **Media Processing:** AWS MediaConvert 2025.09 template `vw-media-hls-v3`, FFmpeg 6.1.1 (EKS job image `ghcr.io/videowindow/ffmpeg:6.1.1-gpu`), AWS Elemental PeerLink `v3.4` for live handoffs, Shaka Packager 2.6.1 for manifest packaging.
- **Storage & Delivery:** AWS S3 bucket `vw-media-origin-prod` (intelligent tiering), CloudFront distribution `d3vw-media.cloudfront.net` with signed cookies, AWS Global Accelerator GA-05F3 to reduce startup latency.
- **Content Protection:** AWS KMS multi-Region key `alias/media-content-aes256`, Google Widevine CAS SDK 17.0.0, Apple FairPlay Streaming SDK 4.1.0, Microsoft PlayReady Server SDK 4.5.3, NAGRA NexGuard forensic watermark SaaS v7.4.
- **Security & Key Management:** AWS CloudHSM cluster `cloudhsm-media-prod` firmware 7.2, HashiCorp Vault 1.15.3 (1Password Connect bridge v1.7.3) for DRM signing keys, Forter anti-piracy fingerprinting agent 3.2.2.
- **Monitoring & Analytics:** Datadog Agent 7.53.0 with synthetic monitor `story-startup`, AWS CloudWatch metrics, Segment backend ingestion 4.5.1, Kibana 8.14 for security dashboards.
- **Workflow Orchestration:** AWS Step Functions `media-transcode-orchestrator@2025-09`, EventBridge bus `media-pipeline-events`, SQS queue `media-transcode-work-queue` with dead-letter queue retention 14 days.

### Source Tree & File Directives
```text
video_window_server/
  lib/
    src/
      endpoints/
        media/
          media_upload_endpoint.dart             # Modify: enforce KMS envelope encryption workflow (Story 6.1)
          media_transcode_endpoint.dart          # Create: orchestrate MediaConvert jobs + status (Story 6.2)
          media_protection_endpoint.dart         # Create: DRM token issuance + forensic watermark requests (Story 6.3)
      services/
        media_pipeline/
          upload_service.dart                   # Modify: chunk ingestion + ClamAV scan (Story 6.1)
          transcode_service.dart                # Create: MediaConvert template builder (Story 6.2)
          drm_license_service.dart              # Create: Widevine/FairPlay/PlayReady issuance (Story 6.3)
          watermark_service.dart                # Modify: integrate NexGuard forensic payloads (Story 6.3)
      workflows/
        media_pipeline_step_function.dart       # Create: Step Functions client & state machine definitions (Story 6.2)
      security/
        content_security_service.dart           # Modify: AES-256-GCM + capture deterrence hooks (Story 6.1)
      monitoring/
        media_pipeline_observer.dart            # Create: emit Datadog/Segment events (Story 6.3)
    test/
      endpoints/media/
        media_transcode_endpoint_test.dart      # Create: verifies auth + job orchestration
        media_protection_endpoint_test.dart     # Create: DRM issuance + rate limit tests
      services/media_pipeline/
        transcode_service_test.dart             # Create: template construction + fallback renditions
        drm_license_service_test.dart           # Create: license responses + error handling

video_window_flutter/
  packages/
    core/
      lib/
        data/
          services/
            media/
              media_upload_service.dart          # Modify: resumable upload with KMS metadata (Story 6.1)
              media_playback_service.dart        # Modify: multi-DRM playback negotiation (Story 6.3)
        security/
          forensic_watermark_client.dart         # Create: attach forensic watermark claims (Story 6.3)
      test/
        data/services/media/
          media_upload_service_test.dart         # Modify: chunk retry + checksum tests
          media_playback_service_test.dart       # Create: DRM negotiation matrix

infrastructure/
  terraform/
    media_pipeline.tf                            # Modify: S3, MediaConvert, Step Functions resources (Stories 6.1, 6.2)
    media_drm.tf                                 # Create: CloudHSM, DRM license servers, NexGuard integration (Story 6.3)
  ci/
    media_pipeline_checks.yaml                   # Create: triggers ClamAV, ffmpeg smoke tests, DRM lints
```

## Component-Level Implementation

### Implementation Guide
1. **Secure Upload & Storage Foundations**
   - Update `media_upload_endpoint.dart` and `upload_service.dart` to enforce per-chunk checksum validation, ClamAV malware scans, and envelope encryption via AWS KMS (Stories 6.1).
   - Configure S3 bucket `vw-media-origin-prod` with object lock, versioning, and lifecycle transitions (hot→warm→cold) through Terraform (`media_pipeline.tf`). (Story 6.1)
2. **Transcoding Orchestration**
   - Implement `transcode_service.dart` to assemble MediaConvert job settings from template `vw-media-hls-v3`, create renditions (360/720/1080/2160), and push to Step Functions `media-transcode-orchestrator@2025-09`. (Story 6.2)
   - Add `media_transcode_endpoint.dart` for job submission, status polling, and failure retry logic with DLQ fallback. (Story 6.2)
3. **Advanced Optimization & Packaging**
   - Integrate Shaka Packager to emit DASH manifests alongside HLS, enabling multi-DRM distribution. Cache manifests in S3 `manifests/` prefix with CloudFront invalidations. (Story 6.2)
   - Enable GPU-accelerated FFmpeg pods (EKS node group `g5-media-transcode`) and benchmark transcode times, adjusting concurrency in `transcode_service_test.dart`. (Story 6.2)
4. **DRM & Forensic Watermarking**
   - Build `drm_license_service.dart` to interface with Widevine, FairPlay, and PlayReady SDKs, issuing licenses with per-user entitlements and 5-minute TTL. (Story 6.3)
   - Enhance `watermark_service.dart` to request NexGuard forensic payloads, embed identifiers (userId, deviceId, sessionId), and log tokens for audit. (Story 6.3)
5. **Client Playback Integration**
   - Update Flutter `media_playback_service.dart` to negotiate DRM (FairPlay on iOS, Widevine on Android/web, PlayReady on supported web) and attach forensic watermark claims to requests. (Story 6.3)
   - Extend capture deterrence by wiring `forensic_watermark_client.dart` with platform channels to dim playback or lock when screen capture detected. (Stories 6.1, 6.3)
6. **Monitoring & Anti-Piracy Response**
   - Implement `media_pipeline_observer.dart` to emit Segment events (`media_upload_started`, `media_transcode_completed`, `media_drm_license_issued`, `media_piracy_alert`) and Datadog metrics (`media.transcode.duration_ms`). (Stories 6.1–6.3)
   - Configure Forter fingerprinting agent to monitor CDN traffic, forwarding alerts to Lambda `piracy-escalation@2025-10` for automated DMCA workflows. (Story 6.3)
7. **Testing & Compliance**
   - Build end-to-end integration tests simulating upload→transcode→DRM playback using mock CDN URLs. (Stories 6.1–6.3)
   - Run resilience tests via `media_pipeline_checks.yaml` (ClamAV, ffmpeg sanity, DRM smoke). Document pass/fail criteria in Test Traceability. (Stories 6.1–6.3)

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

### Test Traceability Matrix
| Acceptance Criterion | Verification Assets | Notes |
| -------------------- | ------------------- | ----- |
| AC1 – Secure upload & metadata pipeline | `media_upload_service_test.dart`, integration `media_upload_flow_test` | Validates chunk checksum, ClamAV scan, metadata extraction.
| AC2 – Signed URLs & watermark MVP | `content_security_service_test.dart`, Sentry smoke `media_pipeline_checks.yaml` | Ensures AES-256-GCM envelope encryption and visible watermark overlay.
| AC3 – Storage lifecycle & retention | Terraform integration tests `testinfra/test_media_storage.py`, AWS Config rule `media-storage-lifecycle` | Confirms tier transitions + secure deletion.
| AC4 – CDN delivery & access control | `media_transcode_endpoint_test.dart`, load test `k6/cdn_signed_url.js` | Measures signature validation, concurrent stream limits.
| AC5 – Encryption at rest/in transit | `kms_envelope_integration_test.dart`, CloudHSM audit checks | Verifies master key rotation & TLS 1.3 enforcement.
| AC6 – Transcoding & packaging | `transcode_service_test.dart`, Step Functions integration test `media_state_machine_test.dart` | Ensures renditions + manifest generation.
| AC7 – Monitoring & audit logging | `media_pipeline_observer_test.dart`, Datadog monitor `media.upload.success_rate` | Confirms analytic events + log retention.
| AC8 – Anti-piracy response | `piracy_detection_integration_test.dart`, Lambda `piracy-escalation@2025-10` canary | Validates fingerprint alert ingestion + DMCA ticket creation.

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

### Analytics Events (Segment)
- `media_upload_started`: `assetId`, `uploaderId`, `fileSizeBytes`, `ingestRegion`, `uploadMethod`.
- `media_transcode_completed`: `assetId`, `renditionsGenerated`, `totalDurationMs`, `qualityProfile`, `gpuNodeId`.
- `media_drm_license_issued`: `assetId`, `userId`, `drmType`, `ttlSeconds`, `deviceClass`.
- `media_watermark_embedded`: `assetId`, `watermarkId`, `provider`, `embeddingLatencyMs`.
- `media_piracy_alert`: `assetId`, `fingerprintHash`, `confidenceScore`, `alertId`, `escalationState`.

### Observability & Dashboards
- Grafana dashboard `Media Pipeline` tracks MediaConvert queue depth, transcode duration p95 (target ≤ 8 min for 10 min asset), and Step Functions failure rate (<1%).
- Datadog monitors: `media.upload.success_rate` (SLO ≥ 99%), `media.transcode.duration_ms` (p95 ≤ 480000), `media.drm.license_latency_ms` (p95 ≤ 250), `media.piracy.alert_count` trending.
- CloudWatch metric filters trigger alarms for failed MediaConvert jobs and CloudHSM key access anomalies.
- Kibana security dashboard aggregates forensic watermark verifications and DMCA takedown timelines.

### Logging Strategy
- Structured JSON logs via OpenTelemetry collector 0.96.0 with correlation IDs (`uploadId`, `assetId`).
- Security events streamed to AWS Security Lake with 365-day retention; DMCA workflow logs retained 7 years for legal compliance.
- Performance metrics exported to Datadog and long-term S3 cold storage for capacity planning.
- Error tracking via Sentry backend DSN `op://observability/Sentry/VIDEO_WINDOW_BACKEND_DSN` with release tagging `media-pipeline@{gitSha}`.

## Deployment Considerations

### Environment Configuration
```yaml
VIDEO_PIPELINE_CONFIG:
  AWS_REGION: "us-east-1"
  MEDIA_ORIGIN_BUCKET: "vw-media-origin-prod"
  MEDIA_MANIFEST_BUCKET: "vw-media-manifests-prod"
  CLOUDFRONT_DISTRIBUTION_ID: "E3VW6MEDIA0AB1"
  MEDIACONVERT_TEMPLATE_ARN: "arn:aws:mediaconvert:us-east-1:921533885321:presets/vw-media-hls-v3"
  STEP_FUNCTION_ARN: "arn:aws:states:us-east-1:921533885321:stateMachine:media-transcode-orchestrator"
  TRANSCODE_QUEUE_URL: "https://sqs.us-east-1.amazonaws.com/921533885321/media-transcode-work-queue"

DRM_CONFIG:
  WIDEVINE_LICENSE_URL: "https://license.widevine.videowindow.com/v1/issue"
  WIDEVINE_SIGNING_KEY: "vault://drm/widevine/signing_key"
  FAIRPLAY_LICENSE_URL: "https://fairplay.videowindow.com/license"
  FAIRPLAY_CERTIFICATE: "vault://drm/fairplay/certificate_pem"
  PLAYREADY_LICENSE_URL: "https://playready.videowindow.com/rightsmanager.asmx"
  PLAYREADY_SIGNING_KEY: "vault://drm/playready/signing_key"

FORENSIC_WATERMARK:
  PROVIDER_ENDPOINT: "https://api.nexguard.videowindow.com/v7"
  PROVIDER_API_KEY: "vault://content-protection/nexguard/api_key"
  TEMPLATE_ID: "vw-forensic-watermark-v2"
  PAYLOAD_TTL_SECONDS: 300

SECURITY_CONFIG:
  CLOUDHSM_CLUSTER_ID: "cluster-7nmediaprod"
  KMS_KEY_ALIAS: "alias/media-content-aes256"
  CAPTURE_DETER_TOPIC: "arn:aws:sns:us-east-1:921533885321:media-capture-alerts"
  CONCURRENT_STREAM_LIMIT: 2

MONITORING_CONFIG:
  DATADOG_API_KEY: "vault://observability/datadog/api_key"
  SEGMENT_BACKEND_WRITE_KEY: "op://video-window-feed/Analytics/SEGMENT_FEED_WRITE_KEY"
  PIRACY_ALERT_SNS_TOPIC: "arn:aws:sns:us-east-1:921533885321:piracy-escalations"
  GRAFANA_DASHBOARD_UID: "media-pipeline-main"
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
- Upload success rate ≥ 99.5% (Datadog `media.upload.success_rate`).
- MediaConvert job success rate ≥ 99% with p95 transcode duration ≤ 8 minutes for 10-minute assets.
- DRM license issuance success ≥ 99.7% with p95 license latency ≤ 250 ms.
- Forensic watermark verification success ≥ 99% and piracy alert false-positive rate ≤ 2%.
- Streaming startup time p95 ≤ 2.5 seconds measured via synthetic `story-startup` monitor.

## Next Steps

1. **Implement Media Upload Pipeline** - Secure upload, validation, and processing queue
2. **Develop Transcoding Service** - AWS MediaConvert integration and job management
3. **Implement Content Protection** - DRM integration and watermarking system
4. **Set Up CDN Delivery** - CloudFront configuration and signed URL generation
5. **Build Anti-Piracy System** - Content fingerprinting and monitoring
6. **Comprehensive Testing** - Security testing, performance validation, and user acceptance testing

**Dependencies:** Epic 1 (Viewer Authentication) for user access control, Epic 2 (Maker Auth) for content ownership verification
**Blocks:** Epic 7 (Admin Analytics) for content performance analytics, Epic 8 (Mobile Experience) for native video player integration

## Change Log
| Date       | Version | Description                                                                                                            | Author            |
| ---------- | ------- | ---------------------------------------------------------------------------------------------------------------------- | ----------------- |
| 2025-10-29 | v1.0    | Elevated spec to definitive status with pinned stack, source directives, implementation plan, observability, and tests | GitHub Copilot AI |

---
*This technical specification provides the foundation for implementing a secure, scalable media pipeline with comprehensive content protection and anti-piracy measures.*