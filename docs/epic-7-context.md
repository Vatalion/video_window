# Epic 7 Context: Video Capture & Editing

**Generated:** 2025-11-04  
**Epic ID:** 7  
**Epic Title:** Video Capture & Editing  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Capture:** In-app camera with security controls (screen recording prevention)
- **Editing:** Timeline editor with trim/split operations, caption overlay
- **Processing:** FFmpeg isolate workers with GPU acceleration toggle
- **Storage:** Encrypted local storage (NSFileProtectionComplete iOS, Scoped Storage Android)
- **Sync:** Draft autosave every 30s with conflict resolution

### Technology Stack
- Capture: camera 0.10.5, sensors_plus 5.0.2 (gyro stabilization), wakelock_plus 1.1.3, permission_handler 11.3.0
- Editing: ffmpeg-kit_flutter 4.5.1-LTS, flutter_gpu_video_processing 1.2.0
- Preview: video_player 2.8.3, chewie 1.7.4
- Security: AES-256-GCM via cryptography 2.7.0, flutter_secure_storage 9.2.1, local_auth 2.1.7
- Storage: sqflite 2.3.3, drift 2.17.0, path_provider 2.1.2
- State: flutter_bloc 9.1.0, rxdart 0.27.7

### Key Integration Points
- `packages/features/timeline/` - Maker Studio UI (capture, editing, captions)
- `video_window_server/lib/src/endpoints/story/` - Draft sync and versioning endpoints
- FFmpeg: Timeline editing operations via isolate workers
- Local encrypted storage: Draft persistence with AES-256-GCM

### Implementation Patterns
- **Capture:** Device-adaptive resolution (1080p60 target), gyroscope feedback for stabilization
- **Timeline Editing:** 60fps scrubbing, non-destructive operations (trim/split), frame-accurate seeking
- **Caption Editor:** Rich text styling with positioning and timing controls
- **Autosave:** 30-second interval with optimistic concurrency control and conflict resolution

### Story Dependencies
1. **7.1:** Video capture & import with security (foundation)
2. **7.2:** Timeline editing & captioning (depends on 7.1)
3. **7.3:** Draft autosave & sync system (depends on 7.1, 7.2)

### Success Criteria
- Capture supports 1080p60 on target devices (iPhone 12+, Pixel 6+)
- Timeline operations maintain 60fps during scrubbing
- Autosave prevents data loss (30s max data loss window)
- Security prevents screen recording during capture
- FFmpeg operations complete in <5s for 30s clips

**Reference:** See `docs/tech-spec-epic-7.md` for full specification
