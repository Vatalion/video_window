# Epic 7: Maker Story Capture & Editing Tools - Technical Specification

**Epic Goal:** Provide comprehensive in-app video capture, timeline editing, captioning, and draft management capabilities for makers to create compelling product stories without leaving the app.

**Stories:**
- 7.1: Video Capture & Import with Security Controls
- 7.2: Timeline Editing & Captioning Implementation
- 7.3: Draft Autosave & Sync System

## Architecture Overview

### Component Mapping
- **Flutter App:** Maker Studio Module (camera capture, timeline editor, caption editor, draft management)
- **Serverpod:** Media Pipeline Service, Story Service, Security Service
- **Database:** Stories table, video_clips table, draft_versions table, caption_tracks table
- **External:** Device camera APIs, local secure storage, FFmpeg for video processing
- **Infrastructure:** Object storage for encrypted raw footage, CDN for processed content

### Technology Stack
- **Flutter SDK & Tooling:** Flutter 3.19.6, Dart 3.5.6 (repo baseline), Melos-managed workspace.
- **Capture & Device APIs:** `camera` 0.10.5, `sensors_plus` 5.0.2 for gyroscope feedback, `device_info_plus` 10.1.0 for capability detection, `permission_handler` 11.3.0 for runtime permissions.
- **Video Playback & Preview:** `video_player` 2.8.3, `chewie` 1.7.4 (preview overlays), `wakelock_plus` 1.1.3 to prevent sleep during capture.
- **Video Processing Pipeline:** `ffmpeg-kit_flutter_full_gpl` 4.5.1-LTS wrapped through isolate workers, GPU acceleration toggled via `flutter_gpu_video_processing` 1.2.0.
- **Encryption & Security:** AES-256-GCM via `cryptography` 2.7.0, secure key storage with `flutter_secure_storage` 9.2.1, device biometrics handshake using `local_auth` 2.1.7.
- **Local Persistence:** `sqflite` 2.3.3 for draft metadata, `drift` 2.17.0 for typed DAOs, `path_provider` 2.1.2 for sandbox directories, raw footage stored under encrypted application storage (`NSFileProtectionComplete`, `Scoped Storage`).
- **State Management & Utilities:** `flutter_bloc` 9.1.0, `equatable` 2.0.5, `rxdart` 0.27.7 for timeline scrubbing throttling.
- **Performance Instrumentation:** Internal `performance_monitor` utility, `package:metrics_center` 1.1.0 for frame timing, `firebase_crashlytics` 3.4.9 (crash traces forwarded via Segment bridge).
- **Design System & Accessibility:** Shared tokens from `packages/shared` (v1.4.0), `flutter_animate` 4.5.0 for micro-interactions, `flutter_accessibility_service` 0.3.2 for caption compliance.

### Source Tree & File Directives
```text
video_window_flutter/
  packages/
    features/
      timeline/
        lib/
          presentation/
            pages/
              maker_studio_page.dart              # Modify: unify capture + timeline shell (Story 7.1)
              timeline_editor_page.dart           # Create: timeline editing workspace (Story 7.2)
            widgets/
              capture_controls_panel.dart         # Create: exposure/focus/record UI (Story 7.1)
              timeline_scrubber.dart              # Create: 60fps scrubbing component (Story 7.2)
              caption_editor_sheet.dart           # Create: caption styling & positioning (Story 7.2)
            bloc/
              capture_bloc.dart                   # Modify: device adaptive capture pipeline (Story 7.1)
              timeline_editor_bloc.dart           # Modify: trim/split + performance instrumentation (Story 7.2)
              caption_editor_bloc.dart            # Modify: rich captions & analytics (Story 7.2)
              draft_sync_bloc.dart                # Create: autosave + conflict handling (Story 7.3)
        lib/
          use_cases/
            start_capture_session_use_case.dart   # Create: orchestrate capture setup + storage (Story 7.1)
            apply_timeline_edit_use_case.dart     # Create: edit operations routed through services (Story 7.2)
            resolve_draft_conflict_use_case.dart  # Create: merges & sync resolution (Story 7.3)
    core/
      lib/
        data/
          services/
            media/
              video_capture_service.dart          # Modify: hardware config + ffmpeg handoff (Story 7.1)
              timeline_processing_service.dart    # Create: isolate orchestrator & perf metrics (Story 7.2)
            storage/
              draft_repository.dart               # Modify: drift-backed versioning (Story 7.3)
          datasources/
            local/
              draft_database.dart                 # Create: drift schema for drafts/versions (Story 7.3)
        security/
          local_encryption_service.dart           # Modify: AES-256-GCM with key rotation (Story 7.1)
    shared/
      lib/
        analytics/
          analytics_events.dart                   # Modify: add maker studio events (Story 7.1-7.3)

video_window_server/
  lib/
    src/
      endpoints/
        story/
          draft_endpoint.dart                     # Modify: extend autosave + conflict APIs (Story 7.3)
      services/
        story/
          draft_sync_service.dart                 # Modify: diff sync + conflict audit (Story 7.3)
        media_pipeline/
          ingest_service.dart                     # Modify: import validation hooks (Story 7.1)
    test/
      endpoints/story/
        draft_endpoint_test.dart                  # Extend: autosave + conflict scenarios
      services/story/
        draft_sync_service_test.dart              # Add coverage for version merges

infrastructure/
  terraform/
    maker_studio.tf                               # Create: S3 raw footage prefix, CloudWatch metrics, ffmpeg lambda cache (Story 7.1-7.3)
  ci/
    maker_studio_checks.yaml                      # Create: capture linting, performance regression harness
```

### Implementation Guide
1. **Capture & Import Foundations (Story 7.1)**
   - Extend `video_capture_service.dart` to read device profile via `device_info_plus` 10.1.0, choosing resolution/bitrate presets defined in `maker_studio_profiles.yaml`.
   - Wire `capture_bloc.dart` to drive `maker_studio_page.dart` with exposure/focus controls, using `capture_controls_panel.dart` for UI.
   - Implement encryption pipeline in `local_encryption_service.dart` using AES-256-GCM keys sourced from `vault://maker-studio/crypto/raw-footage`. Ensure secure cleanup after upload via `start_capture_session_use_case.dart` `complete()` method.
   - Update `media_pipeline/ingest_service.dart` to reject DRM-protected imports by inspecting `ffprobe` metadata (FFmpeg kit 4.5.1) and log via `maker.capture.import_rejected`.
2. **Timeline Editing & Captioning (Story 7.2)**
   - Introduce `timeline_processing_service.dart` to offload trim/split/extract frame jobs onto isolates with per-job performance metrics.
   - Create `timeline_editor_page.dart` and `timeline_scrubber.dart` for 60fps scrubbing; integrate with `PerformanceMonitor.recordMetric('timeline.frame_time_ms')`.
   - Enhance `caption_editor_bloc.dart` + `caption_editor_sheet.dart` to support style presets from `packages/shared` design tokens and emit analytics via `AnalyticsEvents.makerCaptionEdited`.
   - Persist edits through `apply_timeline_edit_use_case.dart`, ensuring BLoC emits `TimelineEditorPerformanceState` with latest frame-time stats.
3. **Draft Autosave & Sync (Story 7.3)**
   - Replace existing SQLite helpers with Drift schema `draft_database.dart` to track versions, conflicts, and auto-save cadence.
   - Build `draft_sync_bloc.dart` coordinating local autosave (`AUTO_SAVE_INTERVAL_SECONDS`) and server sync using `draft_endpoint.dart`.
   - Implement `resolve_draft_conflict_use_case.dart` leveraging `DraftSyncService.threeWayMerge()`; log conflict outcomes to Segment.
   - Update server-side `draft_endpoint.dart` and `draft_sync_service.dart` to accept version vectors, returning conflict metadata for UI overlays.
4. **Infrastructure & Tooling**
   - Provision `maker_studio.tf` resources: S3 `vw-maker-raw-footage-${env}` bucket with Object Lock, CloudWatch dashboard `MakerStudioPerformance`, and IAM roles for ffmpeg lambda caches.
   - Add CI workflow `maker_studio_checks.yaml` running `melos run analyze:timeline`, ffmpeg smoke tests, and integration benchmarks.
5. **Observability & QA**
   - Integrate `performance_monitor` to push metrics to Datadog (`maker.timeline.frame_time_ms`, `maker.capture.success_rate`).
   - Configure analytics events enumerated in `AnalyticsEvents` and ensure dashboards are updated per `docs/analytics/maker-studio-dashboard.md`.
   - Map acceptance criteria to specific tests in the Test Traceability section and ensure runbook `docs/runbooks/maker-studio.md` references new instrumentation.

### Monitoring & Analytics
- **Metrics (Datadog):** `maker.capture.success_rate` (target ≥ 95%), `maker.timeline.frame_time_ms` (p95 ≤ 16.7ms), `maker.timeline.trim_duration_ms` (p95 ≤ 100ms), `maker.draft.autosave_latency_ms` (p95 ≤ 250ms).
- **Segment Events:** `maker_capture_started`, `maker_capture_completed`, `maker_clip_import_failed`, `maker_timeline_trimmed`, `maker_caption_added`, `maker_draft_conflict_detected`, `maker_draft_resolved`.
- **Dashboards:** Grafana `maker-studio-runtime` (timeline performance), Datadog dashboard `Maker Studio Experience`, Kibana index `maker-studio-logs-*` for ffmpeg isolate errors.
- **Alerting:** EventBridge rule `maker-studio-performance-alerts` routes to Slack `#eng-maker-studio` when frame time p95 > 20ms (5m); PagerDuty `Maker Studio Capture` on autosave latency > 500ms for 2 consecutive samples.

### Environment Configuration
```yaml
maker_studio:
  AUTO_SAVE_INTERVAL_SECONDS: 20
  MAX_CLIP_DURATION_SECONDS: 420
  MAX_PROJECT_DURATION_SECONDS: 900
  TIMELINE_CACHE_SIZE_MB: 128
  CONFLICT_RESOLUTION_TIMEOUT_SECONDS: 300
  ENCRYPTION_KEY_DERIVATION_SALT: "vault://maker-studio/crypto/derivation_salt"
  ENCRYPTION_MASTER_KEY_ALIAS: "alias/maker-studio-footage"
  RAW_FOOTAGE_BUCKET: "vw-maker-raw-footage-${ENV}"
  FFPROBE_BINARY_PATH: "/opt/ffmpeg-kit/4.5.1/bin/ffprobe"
  DEVICE_PROFILE_CONFIG: "config/maker_studio_profiles.yaml"

observability:
  DATADOG_NAMESPACE: "maker-studio"
  SEGMENT_WRITE_KEY: "op://video-window-feed/Analytics/SEGMENT_MAKER_WRITE_KEY"
  GRAFANA_DASHBOARD_UID: "maker-studio-runtime"
  SLACK_ALERT_CHANNEL: "#eng-maker-studio"
```

## Data Models

### Video Clip Entity
```dart
class VideoClip {
  final String id;
  final String storyId;
  final String localPath;
  final String? remoteUrl;
  final Duration duration;
  final Size resolution;
  final int fileSizeBytes;
  final String encodingFormat;
  final DateTime createdAt;
  final DateTime? uploadedAt;
  final String encryptionKeyId;
  final ClipMetadata metadata;
}

class ClipMetadata {
  final String deviceId;
  final String? originalFilename;
  final Map<String, dynamic> exifData;
  final bool isEncrypted;
  final String? drmProtection;
}
```

### Timeline Project Entity
```dart
class TimelineProject {
  final String id;
  final String storyId;
  final String makerId;
  final String title;
  final List<TimelineClip> clips;
  final List<CaptionTrack> captionTracks;
  final Duration totalDuration;
  final TimelineSettings settings;
  final DateTime lastModified;
  final ProjectStatus status;
  final String? conflictResolutionId;
}

class TimelineClip {
  final String clipId;
  final Duration startTime;
  final Duration endTime;
  final Duration timelineOffset;
  final double volume;
  final List<ClipEffect> effects;
}

enum ProjectStatus { draft, saving, synced, conflict, published }
```

### Caption Track Entity
```dart
class CaptionTrack {
  final String id;
  final String projectId;
  final List<Caption> captions;
  final CaptionStyle defaultStyle;
  final String language;
  final DateTime createdAt;
  final DateTime lastModified;
}

class Caption {
  final String id;
  final String text;
  final Duration startTime;
  final Duration endTime;
  final CaptionStyle? overrideStyle;
  final CaptionPosition position;
}

class CaptionStyle {
  final String fontFamily;
  final double fontSize;
  final Color textColor;
  final Color? backgroundColor;
  final FontWeight fontWeight;
  final TextDecoration textDecoration;
}
```

### Draft Version Entity
```dart
class DraftVersion {
  final String id;
  final String projectId;
  final int versionNumber;
  final TimelineProject projectSnapshot;
  final List<String> changedClipIds;
  final String changeDescription;
  final DateTime createdAt;
  final String deviceId;
  final bool isAutoSave;
  final String? parentVersionId;
}
```

## API Endpoints

### Media Pipeline Endpoints
```
POST /media/upload/initiate
POST /media/upload/chunk
POST /media/upload/complete
GET /media/formats/supported
POST /media/validate/import
```

### Story Service Endpoints
```
POST /story/draft/save
POST /story/draft/sync
GET /story/draft/conflicts
POST /story/draft/resolve-conflict
GET /story/draft/versions
```

### Endpoint Specifications

#### Initiate Upload
```dart
// Request
{
  "filename": "clip_001.mp4",
  "fileSize": 15728640,
  "mimeType": "video/mp4",
  "encryptionKeyId": "device_key_123",
  "storyId": "story_456"
}

// Response
{
  "uploadId": "upload_789",
  "chunkSize": 5242880,
  "totalChunks": 3,
  "presignedUrls": [
    "https://s3.amazonaws.com/bucket/...",
    "https://s3.amazonaws.com/bucket/...",
    "https://s3.amazonaws.com/bucket/..."
  ],
  "expiresAt": "2025-01-10T15:30:00Z"
}
```

#### Save Draft
```dart
// Request
{
  "projectId": "project_123",
  "versionNumber": 15,
  "projectSnapshot": { ... },
  "changedClipIds": ["clip_001", "clip_003"],
  "changeDescription": "Trimmed clip 001, added caption to clip 003",
  "deviceId": "device_456",
  "isAutoSave": true
}

// Response
{
  "versionId": "version_789",
  "conflicts": [],
  "syncStatus": "success",
  "nextVersionNumber": 16
}
```

#### Get Supported Formats
```dart
// Response
{
  "formats": [
    {
      "extension": "mp4",
      "mimeTypes": ["video/mp4"],
      "codecs": ["h264"],
      "maxFileSize": 524288000,
      "maxResolution": {"width": 1920, "height": 1080},
      "recommendedBitrate": 5000000
    }
  ],
  "deviceCapabilities": {
    "maxConcurrentClips": 8,
    "maxTimelineDuration": 600,
    "supportedEffects": ["trim", "volume", "transition"]
  }
}
```

## Implementation Details

### Flutter Maker Studio Module Structure

#### Video Capture Service
```dart
class VideoCaptureService {
  final CameraController _cameraController;
  final SecureStorageService _secureStorage;
  final EncryptionService _encryption;

  // Multi-clip recording with device-adaptive encoding
  Future<VideoClip> startRecording({
    required Duration maxDuration,
    required VideoQuality quality,
    required String deviceId,
  }) async {
    // Configure camera based on device capabilities
    final config = await _getOptimalConfig(quality);
    await _cameraController.startVideoRecording();

    // Start encryption pipeline
    final encryptionKey = await _encryption.generateKey();
    final encryptedPath = await _getSecureStoragePath();

    return VideoClip(
      id: generateId(),
      localPath: encryptedPath,
      encryptionKeyId: encryptionKey.id,
      // ... other properties
    );
  }

  // Exposure and focus controls
  Future<void> setExposurePoint(Point<double> point) async {
    await _cameraController.setExposurePoint(point);
  }

  Future<void> setFocusPoint(Point<double> point) async {
    await _cameraController.setFocusPoint(point);
  }

  // Device-adaptive encoding
  Future<VideoCaptureConfig> _getOptimalConfig(VideoQuality quality) async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;

    return VideoCaptureConfig(
      resolution: _selectResolutionForDevice(deviceInfo, quality),
      bitrate: _calculateOptimalBitrate(deviceInfo, quality),
      frameRate: _selectFrameRateForDevice(deviceInfo),
      codec: 'h264', // Hardware accelerated on most devices
    );
  }
}
```

#### Timeline Editor Implementation
```dart
class TimelineEditorBloc extends Bloc<TimelineEditorEvent, TimelineEditorState> {
  final TimelineRepository _repository;
  final VideoProcessingService _videoProcessor;
  final PerformanceMonitor _performanceMonitor;

  TimelineEditorBloc(this._repository, this._videoProcessor, this._performanceMonitor)
      : super(TimelineEditorInitial()) {

    on<TrimClipRequested>(_onTrimClipRequested);
    on<SplitClipRequested>(_onSplitClipRequested);
    on<ReorderClipsRequested>(_onReorderClipsRequested);
    on<TimelineScrubbed>(_onTimelineScrubbed);
  }

  Future<void> _onTrimClipRequested(
    TrimClipRequested event,
    Emitter<TimelineEditorState> emit,
  ) async {
    emit(TimelineEditorProcessing());

    final stopwatch = Stopwatch()..start();

    try {
      // Perform trim operation in isolate for performance
      final updatedClip = await _videoProcessor.trimClip(
        event.clip,
        event.newStartTime,
        event.newEndTime,
      );

      await _repository.updateClip(event.projectId, updatedClip);

      stopwatch.stop();
      _performanceMonitor.recordMetric('trim_operation_duration', stopwatch.elapsedMilliseconds);

      emit(TimelineEditorSuccess(
        project: await _repository.getProject(event.projectId),
      ));
    } catch (error) {
      emit(TimelineEditorError(error.toString()));
    }
  }

  // Frame-accurate preview
  Future<void> _onTimelineScrubbed(
    TimelineScrubbed event,
    Emitter<TimelineEditorState> emit,
  ) async {
    // Debounce rapid scrubbing for performance
    if (_isScrubbing) return;
    _isScrubbing = true;

    final previewFrame = await _videoProcessor.extractFrameAtTime(
      event.project,
      event.position,
    );

    emit(TimelineEditorScrubbing(
      currentPosition: event.position,
      previewFrame: previewFrame,
    ));

    _isScrubbing = false;
  }
}
```

#### Custom Timeline Rendering
```dart
class TimelineWidget extends StatelessWidget {
  final TimelineProject project;
  final Duration currentPosition;
  final Function(Duration) onPositionChanged;

  const TimelineWidget({
    super.key,
    required this.project,
    required this.currentPosition,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TimelinePainter(
        project: project,
        currentPosition: currentPosition,
        pixelsPerSecond: 100.0, // Adaptive based on zoom level
      ),
      child: GestureDetector(
        onPanUpdate: (details) {
          final newPosition = _calculatePositionFromOffset(details.localPosition);
          onPositionChanged(newPosition);
        },
        child: SizedBox(
          height: 120.0,
          width: project.totalDuration.inMilliseconds * 0.1, // 100ms per pixel
        ),
      ),
    );
  }
}

class TimelinePainter extends CustomPainter {
  final TimelineProject project;
  final Duration currentPosition;
  final double pixelsPerSecond;

  TimelinePainter({
    required this.project,
    required this.currentPosition,
    required this.pixelsPerSecond,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Draw clips
    for (final timelineClip in project.clips) {
      final clipRect = Rect.fromLTWH(
        timelineClip.timelineOffset.inMilliseconds * pixelsPerSecond / 1000,
        20.0,
        timelineClip.endTime.inMilliseconds * pixelsPerSecond / 1000,
        80.0,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(clipRect, Radius.circular(4.0)),
        paint,
      );

      // Draw clip thumbnail placeholder
      _drawClipThumbnail(canvas, clipRect, timelineClip);
    }

    // Draw playhead
    final playheadX = currentPosition.inMilliseconds * pixelsPerSecond / 1000;
    final playheadPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      playheadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return oldDelegate.currentPosition != currentPosition ||
           oldDelegate.project.clips.length != project.clips.length;
  }
}
```

#### Caption Editor Implementation
```dart
class CaptionEditorBloc extends Bloc<CaptionEditorEvent, CaptionEditorState> {
  final CaptionRepository _repository;
  final AnalyticsService _analytics;

  CaptionEditorBloc(this._repository, this._analytics)
      : super(CaptionEditorInitial()) {

    on<AddCaptionRequested>(_onAddCaptionRequested);
    on<UpdateCaptionText>(_onUpdateCaptionText);
    on<UpdateCaptionStyle>(_onUpdateCaptionStyle);
    on<DragCaptionPosition>(_onDragCaptionPosition);
  }

  Future<void> _onAddCaptionRequested(
    AddCaptionRequested event,
    Emitter<CaptionEditorState> emit,
  ) async {
    final newCaption = Caption(
      id: generateId(),
      text: '',
      startTime: event.startTime,
      endTime: event.endTime,
      position: CaptionPosition.center,
    );

    await _repository.addCaption(event.trackId, newCaption);

    _analytics.trackEvent('caption_added', {
      'track_id': event.trackId,
      'duration': event.endTime.inMilliseconds - event.startTime.inMilliseconds,
    });

    emit(CaptionEditorSuccess(
      track: await _repository.getTrack(event.trackId),
    ));
  }
}
```

### Security Implementation

#### Local Encryption Service
```dart
class EncryptionService {
  static const _algorithm = 'AES-256-GCM';

  Future<String> encryptFile(String filePath, String keyId) async {
    final key = await _retrieveEncryptionKey(keyId);
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    final encryptedData = await _encrypt(bytes, key);
    final encryptedPath = '${filePath}_encrypted';

    await File(encryptedPath).writeAsBytes(encryptedData);
    await file.delete(); // Remove unencrypted file

    return encryptedPath;
  }

  Future<Uint8List> _encrypt(Uint8List data, SecretKey key) async {
    // Use platform-specific secure encryption
    return await compute(_encryptInIsolate, {
      'data': data,
      'key': key,
      'algorithm': _algorithm,
    });
  }
}

// Isolate computation for encryption
Future<Uint8List> _encryptInIsolate(Map<String, dynamic> params) async {
  final data = params['data'] as Uint8List;
  final key = params['key'] as SecretKey;
  final algorithm = params['algorithm'] as String;

  // Implement AES-256-GCM encryption
  // ... encryption logic
  return encryptedData;
}
```

### Video Processing Pipeline

#### Background Video Processing
```dart
class VideoProcessingService {
  final IsolateManager _isolateManager;
  final CacheManager _cacheManager;

  Future<VideoClip> trimClip(
    VideoClip originalClip,
    Duration newStart,
    Duration newEnd,
  ) async {
    return await _isolateManager.run(
      _trimClipInIsolate,
      {
        'clipPath': originalClip.localPath,
        'startTime': newStart.inMilliseconds,
        'endTime': newEnd.inMilliseconds,
        'outputPath': await _generateTempPath(),
      },
    );
  }

  Future<Uint8List?> extractFrameAtTime(
    TimelineProject project,
    Duration position,
  ) async {
    final clip = _findClipAtPosition(project, position);
    if (clip == null) return null;

    // Check cache first
    final cacheKey = '${clip.clipId}_${position.inMilliseconds}';
    final cachedFrame = await _cacheManager.getFrame(cacheKey);
    if (cachedFrame != null) return cachedFrame;

    final frameData = await _isolateManager.run(
      _extractFrameInIsolate,
      {
        'clipPath': clip.localPath,
        'position': position.inMilliseconds,
        'width': 320, // Thumbnail size
        'height': 180,
      },
    );

    // Cache the extracted frame
    await _cacheManager.cacheFrame(cacheKey, frameData);

    return frameData;
  }
}
```

### Draft Autosave System

#### Local Storage with SQLite
```dart
class DraftRepository {
  final Database _database;
  final ConflictResolver _conflictResolver;

  Future<void> saveDraft(TimelineProject project, {
    bool isAutoSave = true,
    String? changeDescription,
  }) async {
    final batch = _database.batch();

    // Save project snapshot
    batch.insert(
      'draft_projects',
      {
        'id': project.id,
        'story_id': project.storyId,
        'maker_id': project.makerId,
        'project_data': jsonEncode(project.toJson()),
        'last_modified': DateTime.now().toIso8601String(),
        'device_id': await _getDeviceId(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Save version history
    batch.insert(
      'draft_versions',
      {
        'id': generateId(),
        'project_id': project.id,
        'version_number': await _getNextVersionNumber(project.id),
        'project_snapshot': jsonEncode(project.toJson()),
        'change_description': changeDescription ?? 'Auto-save',
        'is_auto_save': isAutoSave,
        'created_at': DateTime.now().toIso8601String(),
      },
    );

    await batch.commit(noResult: true);
  }

  Future<List<DraftVersion>> getConflictVersions(String projectId) async {
    final versions = await _database.query(
      'draft_versions',
      where: 'project_id = ? AND conflict_detected = 1',
      whereArgs: [projectId],
      orderBy: 'created_at DESC',
    );

    return versions.map((v) => DraftVersion.fromJson(v)).toList();
  }
}
```

#### Conflict Resolution
```dart
class ConflictResolver {
  Future<TimelineProject> resolveConflicts(
    TimelineProject localVersion,
    TimelineProject remoteVersion,
    List<DraftVersion> conflictHistory,
  ) async {
    // Implement three-way merge algorithm
    final baseVersion = conflictHistory.isNotEmpty
        ? conflictHistory.first.projectSnapshot
        : remoteVersion;

    final resolvedProject = await _threeWayMerge(
      base: baseVersion,
      local: localVersion,
      remote: remoteVersion,
    );

    return resolvedProject;
  }

  Future<TimelineProject> _threeWayMerge({
    required TimelineProject base,
    required TimelineProject local,
    required TimelineProject remote,
  }) async {
    // Compare changes and merge intelligently
    final resolvedClips = <TimelineClip>[];

    // Analyze clip changes
    final baseClipIds = base.clips.map((c) => c.clipId).toSet();
    final localClipIds = local.clips.map((c) => c.clipId).toSet();
    final remoteClipIds = remote.clips.map((c) => c.clipId).toSet();

    // Handle added clips
    for (final clipId in localClipIds.difference(baseClipIds)) {
      resolvedClips.add(local.clips.firstWhere((c) => c.clipId == clipId));
    }

    for (final clipId in remoteClipIds.difference(baseClipIds)) {
      resolvedClips.add(remote.clips.firstWhere((c) => c.clipId == clipId));
    }

    // Handle modified clips
    for (final clipId in baseClipIds.intersection(localClipIds).intersection(remoteClipIds)) {
      final baseClip = base.clips.firstWhere((c) => c.clipId == clipId);
      final localClip = local.clips.firstWhere((c) => c.clipId == clipId);
      final remoteClip = remote.clips.firstWhere((c) => c.clipId == clipId);

      if (localClip.lastModified.isAfter(baseClip.lastModified) &&
          remoteClip.lastModified.isAfter(baseClip.lastModified)) {
        // Both modified - need manual resolution
        resolvedClips.add(await _resolveClipConflict(localClip, remoteClip));
      } else {
        // Use the most recent version
        resolvedClips.add(
          localClip.lastModified.isAfter(remoteClip.lastModified)
              ? localClip
              : remoteClip,
        );
      }
    }

    return TimelineProject(
      id: local.id,
      storyId: local.storyId,
      makerId: local.makerId,
      title: local.title,
      clips: resolvedClips,
      captionTracks: _mergeCaptionTracks(local, remote, base),
      // ... other properties
    );
  }
}
```

  ### Test Traceability
  | Acceptance Criteria | Coverage Strategy | Execution Command |
  | ------------------- | ----------------- | ----------------- |
  | AC1 (Secure capture & import) | `video_capture_service_test.dart`, integration flow `maker_capture_flow_test.dart` | `melos run test -- --tags maker-capture` |
  | AC2 (Timeline editing) | `timeline_editor_bloc_test.dart`, widget test `timeline_editor_page_test.dart` | `melos run test -- --tags maker-timeline` |
  | AC3 (Caption editor) | `caption_editor_bloc_test.dart`, golden tests for caption styling | `melos run test -- --tags maker-caption` |
  | AC4 (Draft autosave & sync) | Drift-backed `draft_repository_test.dart`, server `draft_endpoint_test.dart` | `melos run test -- --tags maker-draft` |
  | AC5 (Performance metrics) | Integration benchmark `timeline_performance_test.dart` (records frame time) | `melos run benchmark -- --suite maker-studio` |
  | AC6 (Analytics & monitoring) | Telemetry assertions in `maker_studio_observability_test.dart` verifying Segment/Datadog payloads | `melos run test -- --tags maker-observability` |

## Testing Strategy

### Unit Tests
- **Video Capture Service:** Test recording, encryption, and device adaptation
- **Timeline BLoC:** Test all state transitions and performance metrics
- **Caption Editor:** Test text styling and positioning logic
- **Encryption Service:** Test file encryption/decryption with different key types
- **Draft Repository:** Test SQLite operations and conflict resolution

### Integration Tests
- **End-to-End Recording Flow:** Camera → Encryption → Timeline → Draft Save
- **Timeline Editing Performance:** Measure trim/split operations under 100ms
- **Autosave Scenarios:** Test conflict resolution and sync recovery
- **Video Import Flow:** Test format validation and DRM detection

### Performance Tests
- **Timeline Scrubbing:** Maintain 60fps during rapid scrubbing
- **Memory Usage:** Keep memory usage <500MB during editing
- **Video Processing:** Measure trim/split operation duration
- **Background Processing:** Test isolate performance and battery impact

```dart
// Performance Test Example
void main() {
  group('Timeline Performance Tests', () {
    testWidgets('Timeline scrubbing maintains 60fps', (tester) async {
      final timelineBloc = TimelineEditorBloc(mockRepository, mockVideoProcessor, mockPerformanceMonitor);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TimelineEditorBloc>.value(
            value: timelineBloc,
            child: TimelineWidget(project: testProject),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      // Simulate rapid scrubbing
      for (int i = 0; i < 60; i++) {
        await tester.drag(find.byType(TimelineWidget), Offset(10.0, 0));
        await tester.pump();
      }

      stopwatch.stop();

      // Verify average frame time is <16.67ms (60fps)
      expect(stopwatch.elapsedMilliseconds / 60, lessThan(16.67));
    });
  });
}
```

## Performance Optimization

### Mobile Performance Targets
- **Timeline Operations:** Trim/split <100ms response time
- **Clip Loading:** <500ms for mid-tier devices
- **Memory Usage:** <500MB peak during editing
- **Frame Rate:** 60fps during timeline scrubbing
- **Battery Impact:** <5% per hour of normal editing

### Optimization Strategies

#### Custom Painter Optimization
```dart
class OptimizedTimelinePainter extends CustomPainter {
  // Cache frequently used objects
  static final _clipPaint = Paint()..style = PaintingStyle.fill;
  static final _playheadPaint = Paint()
    ..color = Colors.red
    ..strokeWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Use clipping to limit drawing area
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Batch similar draw operations
    _drawClipsBatch(canvas, size);
    _drawPlayhead(canvas, size);
  }

  void _drawClipsBatch(Canvas canvas, Size size) {
    final clipPaths = <Path>[];

    // Collect all clip paths first
    for (final clip in project.clips) {
      final path = _createClipPath(clip, size);
      clipPaths.add(path);
    }

    // Draw all clips in one operation
    for (final path in clipPaths) {
      canvas.drawPath(path, _clipPaint);
    }
  }
}
```

#### Memory Management
```dart
class MemoryEfficientVideoCache {
  final Map<String, Uint8List> _cache = {};
  final int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  int _currentCacheSize = 0;

  Future<Uint8List?> getFrame(String key) async {
    final frame = _cache[key];
    if (frame != null) {
      // Move to end of LRU list
      _cache.remove(key);
      _cache[key] = frame;
      return frame;
    }
    return null;
  }

  Future<void> cacheFrame(String key, Uint8List frameData) async {
    // Evict if necessary
    while (_currentCacheSize + frameData.length > _maxCacheSize && _cache.isNotEmpty) {
      final oldestKey = _cache.keys.first;
      _currentCacheSize -= _cache[oldestKey]!.length;
      _cache.remove(oldestKey);
    }

    _cache[key] = frameData;
    _currentCacheSize += frameData.length;
  }
}
```

## Error Handling

### Error Types
```dart
abstract class MakerStudioException implements Exception {
  final String message;
  final MakerStudioErrorCode code;
}

class CameraPermissionDeniedException extends MakerStudioException { }
class InsufficientStorageException extends MakerStudioException { }
class VideoProcessingFailedException extends MakerStudioException { }
class NetworkSyncException extends MakerStudioException { }
class EncryptionFailedException extends MakerStudioException { }
```

### Recovery Strategies
- **Camera Errors:** Provide clear permission request UI, fallback to import
- **Storage Issues:** Show cleanup recommendations, provide cloud backup
- **Network Failures:** Enable offline mode, queue sync operations
- **Processing Errors:** Provide retry options, suggest quality reduction

## Deployment Considerations

### Environment Variables
```dart
// Required Environment Variables (refer to config/maker_studio.env)
ENCRYPTION_KEY_DERIVATION_SALT=vault://maker-studio/crypto/derivation_salt
ENCRYPTION_MASTER_KEY_ALIAS=alias/maker-studio-footage
MAX_CLIP_DURATION_SECONDS=420
MAX_PROJECT_DURATION_SECONDS=900
TIMELINE_CACHE_SIZE_MB=128
AUTO_SAVE_INTERVAL_SECONDS=20
CONFLICT_RESOLUTION_TIMEOUT_SECONDS=300
RAW_FOOTAGE_BUCKET=vw-maker-raw-footage-${ENV}
FFPROBE_BINARY_PATH=/opt/ffmpeg-kit/4.5.1/bin/ffprobe
DEVICE_PROFILE_CONFIG=config/maker_studio_profiles.yaml
```

### Database Schema
```sql
-- Timeline projects table
CREATE TABLE timeline_projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  maker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  project_data JSONB NOT NULL,
  total_duration_ms INTEGER NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'draft',
  last_modified TIMESTAMP DEFAULT NOW(),
  device_id VARCHAR(255),
  conflict_resolution_id UUID,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Video clips table
CREATE TABLE video_clips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES timeline_projects(id) ON DELETE CASCADE,
  local_path VARCHAR(500) NOT NULL,
  remote_url VARCHAR(500),
  duration_ms INTEGER NOT NULL,
  resolution_width INTEGER NOT NULL,
  resolution_height INTEGER NOT NULL,
  file_size_bytes INTEGER NOT NULL,
  encoding_format VARCHAR(50) NOT NULL,
  encryption_key_id VARCHAR(255) NOT NULL,
  metadata JSONB,
  uploaded_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Draft versions table
CREATE TABLE draft_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES timeline_projects(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  project_snapshot JSONB NOT NULL,
  change_description TEXT,
  is_auto_save BOOLEAN DEFAULT false,
  device_id VARCHAR(255),
  conflict_detected BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Caption tracks table
CREATE TABLE caption_tracks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES timeline_projects(id) ON DELETE CASCADE,
  language VARCHAR(10) NOT NULL DEFAULT 'en',
  default_style JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  last_modified TIMESTAMP DEFAULT NOW()
);

-- Individual captions table
CREATE TABLE captions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  track_id UUID NOT NULL REFERENCES caption_tracks(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  start_time_ms INTEGER NOT NULL,
  end_time_ms INTEGER NOT NULL,
  override_style JSONB,
  position_x DECIMAL(5,4),
  position_y DECIMAL(5,4),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_timeline_projects_maker_id ON timeline_projects(maker_id);
CREATE INDEX idx_timeline_projects_status ON timeline_projects(status);
CREATE INDEX idx_video_clips_project_id ON video_clips(project_id);
CREATE INDEX idx_draft_versions_project_id ON draft_versions(project_id);
CREATE INDEX idx_draft_versions_created_at ON draft_versions(created_at DESC);
CREATE INDEX idx_captions_track_id ON captions(track_id);
CREATE INDEX idx_captions_time_range ON captions(start_time_ms, end_time_ms);
```

## Success Criteria

### Functional Requirements
- ✅ Makers can capture multi-clip video with device-adaptive encoding
- ✅ Timeline editor provides frame-accurate trim/split operations
- ✅ Caption editor supports rich text styling and positioning
- ✅ Draft system maintains version history with conflict resolution
- ✅ Video import validates formats and detects DRM content
- ✅ Raw footage encrypted at rest with platform secure storage

### Non-Functional Requirements
- ✅ Timeline operations complete within 100ms on mid-tier devices
- ✅ Scrubbing maintains 60fps performance
- ✅ Memory usage stays below 500MB during editing
- ✅ Auto-save prevents data loss during app interruption
- ✅ Conflict resolution handles simultaneous edits across devices
- ✅ Video processing works in background without UI blocking

### Success Metrics
- Average timeline operation latency < 100ms
- Video capture success rate > 95%
- Auto-save recovery rate > 99%
- User editing session completion rate > 85%
- Memory usage compliance rate > 95%
- Conflict resolution success rate > 90%

## Next Steps

1. **Implement Video Capture Service** - Camera integration, encryption, device adaptation
2. **Develop Timeline Editor** - Custom painter, BLoC state management, performance optimization
3. **Create Caption Editor** - Rich text editing, positioning, real-time preview
4. **Build Draft System** - SQLite storage, version tracking, conflict resolution
5. **Implement Video Processing** - Isolate-based processing, memory management
6. **Performance Testing** - Benchmark timeline operations, memory profiling
7. **Security Implementation** - Encryption key management, secure storage

**Dependencies:** Epic 6 (Media Pipeline) for upload/processing integration, Epic 2 (Maker Auth) for access control
**Blocks:** Epic 8 (Story Publishing) depends on completed drafts and timeline data

## Change Log
| Date       | Version | Description                                                                 | Author            |
| ---------- | ------- | --------------------------------------------------------------------------- | ----------------- |
| 2025-10-09 | v0.1    | Initial draft created following Story 1.1 gold standard                      | Claude Code Assistant |
| 2025-10-29 | v1.0    | Promoted to definitive: pinned stack, source directives, implementation guide, monitoring, environment config, test traceability | GitHub Copilot AI |

---
*This technical specification outlines the definitive plan for Maker Studio capture, editing, and draft workflows and should be updated alongside related stories and runbooks.*