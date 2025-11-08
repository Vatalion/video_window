# Story 7-1: Maker Story Capture & Editing Tools with Carousel Support

## Status
Ready for Dev

## Story
**As a** maker,
**I want to** capture, edit, and assemble multiple videos for carousel display, create Process Timeline journal entries, and add captions,
**so that** I can create compelling multi-perspective product stories without leaving the app

## Acceptance Criteria
1. In-app video capture with multi-clip recording for carousel (3-7 videos), exposure/focus controls, and secure local encryption of raw footage until upload completion.
2. Carousel creation interface allowing makers to assign context labels ("In Use," "Details," "Making Process," "Variations," custom) to 3-7 video clips with drag-to-reorder and set primary video.
3. Timeline editor with drag-to-reorder clips, split/trim functionality, frame-accurate preview transitions, and real-time performance optimization for mobile devices.
4. Caption editor with manual text input, styling options (font, size, position), time-synchronized display, and auto-save after each edit with conflict resolution.
5. Process Timeline journal interface for makers to log development entries with photos, sketches, text notes, and timestamps in chronological vertical-scroll format.
6. Import pipeline supporting device gallery access with format validation (MP4, MOV, H.264), DRM content warnings, and secure temporary storage processing.
7. Draft autosave system with local encrypted storage, incremental sync to cloud, device conflict resolution, and recovery from interruption during editing.
8. Mobile performance optimization maintaining 60fps timeline scrubbing, memory-efficient video processing, background rendering, and adaptive quality for device capabilities.
9. Integration with content pipeline including metadata tagging, preview generation, publishing workflow handoff, and compliance with media protection standards.
10. **PERFORMANCE CRITICAL**: Ensure smooth timeline interaction with <100ms response time for trim/split operations and <500ms clip loading on mid-tier mobile devices.

## Prerequisites
1. Story 01.1 – Bootstrap Repository and Flutter App
2. Story 1.1 – Implement Email OTP Sign-In (for secure maker sessions)
3. Story 6.1 – Media Pipeline & MVP Content Protection (upload + signed URL contracts)
4. Device security baseline (camera permissions and encryption guidance) from `docs/architecture/security-configuration.md`

## Tasks / Subtasks

### Phase 1 Critical Video Capture & Security Controls (PERF-001 & SEC-002 Mitigation)

- [ ] **PERFORMANCE CRITICAL - PERF-001**: Implement optimized video capture service with multi-clip recording and device-adaptive encoding (AC: 1, 6) [Source: architecture/front-end-architecture.md#mobile-performance-optimization, docs/tech-spec-epic-7.md – Implementation Guide §1]
  - [ ] Use camera package with H.264 hardware encoding and adaptive bitrate based on device capabilities
  - [ ] Implement exposure/focus lock controls with tap-to-adjust functionality
  - [ ] Add real-time preview overlay with recording indicators and clip boundaries
  - [ ] Optimize for 60fps preview with minimal battery impact
- [ ] **PERFORMANCE CRITICAL - PERF-001**: Implement secure local encryption for raw video footage (AC: 1, 5) [Source: architecture/architecture.md#security, docs/tech-spec-epic-7.md – Implementation Guide §1]
  - [ ] Use AES-256-GCM encryption for local storage with device-specific key derivation
  - [ ] Implement secure key storage using platform keychain/keystore
  - [ ] Add automatic cleanup of encrypted temporary files after upload completion
  - [ ] Prevent iCloud/Google Photos sync of raw footage
- [ ] **SECURITY CRITICAL - SEC-002**: Implement format validation and DRM detection for imported media (AC: 4) [Source: architecture/architecture.md#content-protection, docs/tech-spec-epic-7.md – Implementation Guide §1]
  - [ ] Validate file formats (MP4, MOV, H.264) with MIME type and magic number verification
  - [ ] Detect DRM-protected content and display clear warnings with import prevention
  - [ ] Implement virus scanning for imported files using mobile security APIs
  - [ ] Add file size limits with progressive compression options
- [ ] **PERFORMANCE CRITICAL - PERF-001**: Implement memory-efficient video processing pipeline (AC: 6) [Source: architecture/front-end-architecture.md#mobile-performance-optimization, docs/tech-spec-epic-7.md – Implementation Guide §2]
  - [ ] Use streaming video processing to minimize memory footprint
  - [ ] Implement background rendering queue with priority-based task management
  - [ ] Add adaptive quality scaling based on device memory and processing capabilities
  - [ ] Optimize for 2GB RAM minimum device specification

### Phase 2 Timeline Editor & Captioning Implementation

- [ ] Implement timeline editor with drag-to-reorder, split/trim, and frame-accurate preview using Flutter performance patterns (AC: 2) [Source: architecture/front-end-architecture.md#state-management, architecture/front-end-architecture.md#mobile-performance-optimization, docs/tech-spec-epic-7.md – Implementation Guide §2]
  - [ ] Create custom timeline widget with gesture-based clip manipulation
  - [ ] Implement precise trim handles with frame-level accuracy and magnetic snap
  - [ ] Add split functionality with visual preview and confirmation
  - [ ] Optimize rendering with widget rebuilding optimization and lazy loading
- [ ] Implement caption editor with text styling, positioning, and time synchronization using shared design tokens (AC: 3) [Source: architecture/front-end-architecture.md#module-overview, architecture/front-end-architecture.md#design-system, docs/tech-spec-epic-7.md – Implementation Guide §2]
  - [ ] Add rich text editor with font family, size, color, and background styling
  - [ ] Implement drag-and-drop caption positioning with preset placement options
  - [ ] Create time-synchronized caption display with waveform visualization
  - [ ] Add caption preview in real-time during timeline playback
- [ ] Implement draft autosave system with incremental sync and conflict resolution (AC: 5) [Source: architecture/architecture.md#data-persistence, docs/tech-spec-epic-7.md – Implementation Guide §3]
  - [ ] Create local encrypted storage with SQLite database for draft metadata
  - [ ] Implement incremental sync algorithm to minimize bandwidth usage
  - [ ] Add conflict resolution UI for simultaneous edits across devices
  - [ ] Provide draft recovery flow for interrupted editing sessions

### Phase 3 Integration & Publishing Pipeline

- [ ] Connect capture and editing tools to media pipeline service with secure upload and processing (AC: 7) [Source: architecture/architecture.md#media-pipeline, architecture/story-component-mapping.md#epic-7--maker-story-capture--editing-tools, docs/tech-spec-epic-7.md – Implementation Guide §1]
  - [ ] Integrate with `media_pipeline` service for upload ingestion and transcoding
  - [ ] Implement progress tracking for upload with retry logic for network failures
  - [ ] Add metadata tagging (creator, timestamp, device info) to uploaded content
  - [ ] Generate preview thumbnails and story covers automatically
- [ ] Implement publishing workflow handoff with draft review and status management (AC: 7) [Source: architecture/story-component-mapping.md#epic-7--maker-story-capture--editing-tools, docs/tech-spec-epic-7.md – Implementation Guide §3]
  - [ ] Create publishing preview with story layout simulation
  - [ ] Add content validation checks (duration, quality, compliance)
  - [ ] Implement status tracking for moderation and publishing workflow
  - [ ] Provide rollback functionality for published content

### Mobile Performance & UX Optimization

- [ ] Optimize timeline interaction for 60fps performance with <100ms response time (AC: 6, 8) [Source: architecture/front-end-architecture.md#mobile-performance-optimization, docs/tech-spec-epic-7.md – Monitoring & Analytics]
  - [ ] Implement custom painter for timeline rendering with optimized draw calls
  - [ ] Add gesture recognition with predictive scrolling and momentum
  - [ ] Use Isolate for heavy computation tasks (video processing, thumbnail generation)
  - [ ] Implement caching strategy for frequently accessed timeline segments
- [ ] Implement adaptive UI for different device sizes and orientations (AC: 6) [Source: architecture/front-end-architecture.md#responsive-design, docs/tech-spec-epic-7.md – Source Tree & File Directives]
  - [ ] Create responsive timeline layout for portrait and landscape orientations
  - [ ] Add touch-optimized controls with appropriate hit targets
  - [ ] Implement keyboard shortcuts for external keyboard usage
  - [ ] Design for one-handed operation on smaller screens

### Analytics & Error Handling

- [ ] Emit comprehensive analytics events for story creation workflow using analytics service (AC: 2, 3, 4) [Source: architecture/front-end-architecture.md#analytics-instrumentation, analytics/mvp-analytics-events.md#conventions, docs/tech-spec-epic-7.md – Monitoring & Analytics]
  - [ ] Track capture events (start, duration, clip count, quality settings)
  - [ ] Monitor editing actions (trim, split, reorder, caption addition)
  - [ ] Record import attempts (success, failures, format issues)
  - [ ] Measure performance metrics (timeline responsiveness, processing time)
- [ ] Implement comprehensive error handling with user-friendly recovery options (AC: 1, 4, 5) [Source: architecture/front-end-architecture.md#error-handling]
  - [ ] Add camera permission handling with graceful fallbacks
  - [ ] Implement storage space monitoring and cleanup suggestions
  - [ ] Create network-aware sync with offline mode support
  - [ ] Provide contextual help and tutorials for complex editing features

## Dev Notes
### Previous Story Insights
- No prior Epic 7 stories are recorded, so this is the foundational implementation for the maker studio suite. Performance and security patterns should be established for subsequent stories (7.2, 7.3). [Source: architecture/story-component-mapping.md#epic-7--maker-story-capture--editing-tools]

### Data Models
- Video clips stored with metadata (duration, resolution, encoding, encryption key) in local SQLite and synced to `story_service` via Serverpod. [Source: architecture/architecture.md#database-schema-excerpt]
- Timeline projects reference multiple clips with time-based positioning, caption tracks, and edit history for versioning and conflict resolution. [Source: architecture/story-component-mapping.md#epic-7--maker-story-capture--editing-tools]
- Caption data includes text content, styling properties, timing information, and localization support for multiple languages. [Source: architecture/architecture.md#story-service]

### API Specifications
- `POST /media/upload` accepts encrypted video chunks with resumable upload support and returns processing job IDs. [Source: architecture/architecture.md#media-pipeline]
- `PUT /story/draft` saves timeline state with incremental diff updates and conflict resolution metadata. [Source: architecture/architecture.md#story-service]
- `GET /media/formats` returns supported video formats, size limits, and encoding recommendations for device optimization. [Source: architecture/architecture.md#media-pipeline]

### Component Specifications
- Flutter timeline feature package (`video_window_flutter/packages/features/timeline/`) owns camera capture, timeline editor, caption editor, and draft management UX. [Source: architecture/story-component-mapping.md#epic-7--maker-story-capture--editing-tools]
- BLoC-based state management with separate BLoCs for capture, timeline, captions, and draft persistence housed in `.../lib/presentation/bloc/`. [Source: architecture/front-end-architecture.md#state-management]
- Performance-optimized widgets and painters live in `.../lib/presentation/widgets/`, leveraging shared design system components from `video_window_flutter/packages/shared/`. [Source: architecture/front-end-architecture.md#design-system]

### File Locations
- Presentation layer: `video_window_flutter/packages/features/timeline/lib/presentation/` (pages, widgets, blocs) with tests in `.../test/presentation/`. [Source: architecture/architecture.md#source-tree]
- Feature use cases: `video_window_flutter/packages/features/timeline/lib/use_cases/` orchestrating workflows against repositories.
- Core services (video processing, encryption, draft storage) belong in `video_window_flutter/packages/core/lib/data/services/media/` and `.../security/` with unit tests under `packages/core/test/`.
- Local persistence utilities reside in `video_window_flutter/packages/core/lib/data/datasources/local/` (e.g., SQLite adapters).
- Server integration endpoints for media uploads remain in `video_window_server/lib/src/endpoints/media/` with tests under `video_window_server/test/endpoints/media/`.

### Testing Requirements
- Maintain ≥80% coverage with additional performance tests for timeline responsiveness and memory usage. [Source: architecture/architecture.md#testing-strategy]
- Include integration tests for camera capture, video import, timeline editing, and autosave functionality. [Source: architecture/front-end-architecture.md#testing-strategy-client]
- Performance benchmarks for timeline operations (trim <100ms, scrub 60fps, clip loading <500ms). [Source: testing/performance/performance-testing-guide.md]

### Technical Constraints
- Video capture and editing must work offline with local encryption and sync when connectivity is restored. [Source: architecture/architecture.md#security]
- **PERFORMANCE CRITICAL**: Timeline operations must respond in <100ms with smooth 60fps scrubbing on mid-tier devices. [Source: architecture/front-end-architecture.md#mobile-performance-optimization]
- **SECURITY CRITICAL**: Raw footage must be encrypted at rest with platform-specific secure storage (iOS Keychain, Android Keystore). [Source: architecture/architecture.md#security]
- **PERFORMANCE CRITICAL**: Memory usage must stay <500MB during editing with efficient streaming and cleanup. [Source: architecture/front-end-architecture.md#mobile-performance-optimization]
- Video processing must be interruptible and resumable with graceful handling of app backgrounding/foregrounding. [Source: architecture/architecture.md#media-pipeline]
- All editing actions must be tracked for analytics with performance metrics and error monitoring. [Source: architecture/front-end-architecture.md#analytics-instrumentation]

### Project Structure Notes
- Implementation aligns with the unified melos package structure using `packages/features/timeline/` for story creation tools and delegating shared utilities to `packages/core/` and `packages/shared/`. [Source: architecture/front-end-architecture.md#video-marketplace-unified-package-structure]
- Timeline editor will be a reusable component that can be extended for future editing features. [Source: architecture/front-end-architecture.md#component-reusability]

### Scope Notes
- The story bundles capture, editing, captions, autosave, analytics, and publishing handoff. Break into focused slices (Capture + Secure Storage, Timeline Editing, Captioning, Draft Sync, Publishing Handoff) before sprint planning to preserve predictability.

## Testing
- Follow the project testing pipeline by running `dart format`, `flutter analyze`, and `flutter test --no-pub` before submission. [Source: architecture/architecture.md#testing-strategy]
- Add performance benchmarks for timeline operations using `integration_test` package with frame time measurements. [Source: testing/performance/performance-testing-guide.md]
- Include widget tests for timeline gestures, caption editor styling, and camera capture controls with mock providers. [Source: architecture/front-end-architecture.md#testing-strategy-client]

## Change Log
| Date       | Version | Description        | Author             |
| ---------- | ------- | ------------------ | ------------------ |
| 2025-10-09 | v0.1    | Initial draft created following Story 1.1 gold standard | Claude Code Assistant |
| 2025-10-29 | v0.2    | Linked tasks to definitive Epic 7 spec sections and monitoring directives | GitHub Copilot AI |

## Dev Agent Record
### Agent Model Used
_(To be completed by Dev Agent)_

### Debug Log References
_(To be completed by Dev Agent)_

### Completion Notes List
_(To be completed by Dev Agent)_

### File List
_(To be completed by Dev Agent)_

## QA Results
_(To be completed by QA Agent)_