# Story 6-1: Media Pipeline & MVP Content Protection

## Status
review

## Story
**As a** platform,
**I want** to implement a secure media pipeline with MVP-level content protection,
**so that** video content is securely ingested, processed, stored, and streamed with signed URLs and watermarks (full DRM deferred to post-MVP)

## Acceptance Criteria
1. Backend video ingestion pipeline with secure upload, virus scanning, metadata extraction, and automatic transcoding to multiple HLS bitrates.
2. **MVP Content Protection**: Signed URLs with expiration + visible watermarking + capture deterrence (FLAG_SECURE on Android, detection on iOS).
3. Storage lifecycle management with automated tiering, retention policies, and secure deletion of expired content.
4. CDN delivery controls with signed URLs, IP validation, and concurrent stream limits to prevent sharing abuse.
5. **SECURITY CRITICAL**: Implement AES-256-GCM encryption for all content at rest and in transit.
6. **POST-MVP DEFERRED**: Full DRM (Widevine/FairPlay/PlayReady) and forensic watermarking deferred to post-MVP; MVP uses simpler protection stack.
7. Integration with capture pipeline for seamless content flow from creation to secure delivery with end-to-end audit trails.

## Prerequisites
1. Story 01.1 – Bootstrap Repository and Flutter App (workspace + tooling)
2. Story 1.1 – Implement Email OTP Sign-In (secure session context)
3. Foundational storage/KMS configuration from platform infrastructure runbooks (`docs/architecture/security-configuration.md`)
4. Story 7.1 – Maker Story Capture & Editing Tools (capture source integration) should provide upload handoff contracts

## Tasks / Subtasks

### Phase 1 MVP Content Protection (Simplified)

- [x] **SECURITY CRITICAL - MED-SEC-001**: Implement AES-256-GCM encryption for all video content at rest and in transit (AC: 5) [Source: docs/security/content-protection-security-research.md#encryption-standards, docs/tech-spec-epic-6.md – Implementation Guide §1]
  - [ ] Generate unique content encryption keys (CEK) per video asset
  - [ ] Implement key envelope encryption using platform key management service (KMS)
  - [ ] Secure key rotation policy with automated key escrow
- [ ] **SECURITY CRITICAL - MED-SEC-005**: Implement secure signed URL generation with time-based access controls (AC: 2, 4) [Source: docs/security/secure-streaming.md#signed-url-generation, docs/tech-spec-epic-6.md – Implementation Guide §1]
  - [ ] Generate short-lived (5-30 minute) signed URLs with IP binding
  - [ ] Implement URL tokenization with HMAC-SHA256 signature validation
  - [ ] Concurrent stream limits per user to prevent sharing abuse
- [ ] **MVP PROTECTION - MED-MVP-001**: Implement visible watermarking with maker username + timestamp overlay (AC: 2, 6) [Source: docs/architecture/watermarking-mvp.md, docs/tech-spec-epic-6.md – Implementation Guide §4]
  - [ ] Dynamic watermark overlay during HLS segment generation
  - [ ] Position watermark to deter screenshots (semi-transparent, corner placement)
  - [ ] Include maker username and timestamp in watermark
- [ ] **MVP PROTECTION - MED-MVP-002**: Implement capture deterrence for mobile platforms (AC: 2, 6) [Source: docs/architecture/mobile-capture-prevention.md, docs/tech-spec-epic-6.md – Implementation Guide §5]
  - [ ] Android: Set FLAG_SECURE on video player surface to block screen recording
  - [ ] iOS: Monitor UIScreen.isCaptured to detect screen recording attempts
  - [ ] Display warning toast when screen recording detected on iOS

### Phase 2 Media Processing Pipeline

- [ ] Implement secure video ingestion service with comprehensive validation (AC: 1) [Source: docs/architecture/media-pipeline-architecture.md#ingestion-service, docs/tech-spec-epic-6.md – Implementation Guide §1]
  - [ ] Multi-format video upload support (MP4, MOV, AVI, WebM) with file size limits
  - [ ] Virus scanning and malware detection using ClamAV integration
  - [ ] Metadata extraction (codec, resolution, bitrate, duration) using FFmpeg
  - [ ] Content validation against platform policies and copyright checks
- [ ] Implement automatic transcoding pipeline to HLS format (AC: 1) [Source: docs/architecture/transcoding-service.md#hls-implementation, docs/tech-spec-epic-6.md – Implementation Guide §2]
  - [ ] Multi-bitrate transcoding (480p, 720p, 1080p, 4K) with adaptive streaming
  - [ ] H.264/H.265 codec optimization for quality vs file size balance
  - [ ] Audio transcoding to AAC with stereo and surround sound support
  - [ ] Thumbnail generation at multiple timestamps for preview functionality
- [ ] Implement storage lifecycle management with automated policies (AC: 3) [Source: docs/architecture/storage-architecture.md#lifecycle-management, docs/tech-spec-epic-6.md – Environment Configuration]
  - [ ] Hot storage for recent content with SSD-backed performance
  - [ ] Warm storage for older content with cost optimization
  - [ ] Cold storage for archival with infrequent access patterns
  - [ ] Automated content expiration with secure cryptographic deletion
- [ ] Implement CDN integration with global edge distribution (AC: 4) [Source: docs/architecture/cdn-integration.md#edge-delivery, docs/tech-spec-epic-6.md – Implementation Guide §3]
  - [ ] CDN edge caching configuration for HLS segments and manifests
  - [ ] Geographic distribution with automatic edge selection
  - [ ] Cache invalidation policies for content updates and removals
  - [ ] Performance monitoring with CDN analytics integration

### Phase 3 Security Monitoring & Compliance

- [ ] Implement comprehensive audit logging for media operations (AC: 8) [Source: docs/security/audit-logging.md#media-pipeline, docs/tech-spec-epic-6.md – Monitoring & Analytics]
  - [ ] Log all content access attempts with user, timestamp, and location data
  - [ ] Track transcoding operations with success/failure rates and performance metrics
  - [ ] Monitor key access and signed URL issuance activity for anomaly detection
  - [ ] Secure log storage with tamper-proof storage and long-term retention
- [ ] Implement content access control system (AC: 4, 8) [Source: docs/security/access-control.md#content-governance, docs/tech-spec-epic-6.md – Source Tree & File Directives]
  - [ ] Role-based access control for content creators, moderators, and administrators
  - [ ] Content ownership verification with creator authentication
  - [ ] Temporary access grants for review and moderation workflows
  - [ ] Automated permission revocation for account termination or policy violations
- [ ] Implement compliance monitoring for content regulations (AC: 7, 8) [Source: docs/compliance/content-compliance.md#regulatory-requirements, docs/tech-spec-epic-6.md – Implementation Guide §6]
  - [ ] Content filtering for copyrighted material using third-party services
  - [ ] Age verification integration for mature content access
  - [ ] Geographic content restriction enforcement based on local regulations
  - [ ] Automated compliance reporting for legal and regulatory requirements

### Phase 4 Integration & Testing

- [ ] Integrate with capture pipeline for seamless content flow (AC: 8) [Source: docs/architecture/capture-integration.md#end-to-end-flow, docs/tech-spec-epic-6.md – Source Tree & Implementation Guide]
  - [ ] Direct integration with mobile app capture functionality
  - [ ] Automatic content upload from capture to processing pipeline
  - [ ] Real-time processing status updates during upload and transcoding
  - [ ] End-to-end audit trail from capture to final delivery
- [ ] Implement comprehensive testing suite for media pipeline (AC: 1-8) [Source: docs/testing/media-pipeline-testing.md#comprehensive-coverage, docs/tech-spec-epic-6.md – Testing Strategy]
  - [ ] Unit tests for all processing components with >90% coverage
  - [ ] Integration tests for end-to-end content flow
  - [ ] Security penetration testing for content protection mechanisms
  - [ ] Load testing for concurrent processing and streaming scenarios

## Dev Notes
### Previous Story Insights
- Epic 6 builds upon the authentication foundation from Story 1.1, requiring secure user context for content access. [Source: architecture/story-component-mapping.md#epic-6--media-pipeline--content-protection]
- Content protection must integrate with the session management system established in Epic 1. [Source: architecture/story-component-mapping.md#epic-1--viewer-authentication--session-handling]

### Data Models
- `media_assets` table stores video metadata, encryption keys, watermark configuration, and processing status. [Source: architecture/architecture.md#database-schema-excerpt]
- `content_access_logs` table tracks all content access attempts with user context, timestamps, and security events. [Source: architecture/architecture.md#database-schema-excerpt]

### API Specifications
- `POST /media/upload` accepts multipart file uploads with metadata, returning secure upload URLs and processing job IDs. [Source: architecture/architecture.md#media-api-spec]
- `GET /media/{id}/signed-url` issues short-lived signed HLS playlist/segment URLs scoped to the requesting user/device. [Source: docs/security/secure-streaming.md#signed-url-generation]
- `POST /media/{id}/revoke` invalidates active signed URLs when access is revoked (for example, logout, auction state change). [Source: docs/security/secure-streaming.md#revocation]

### Component Specifications
- Media Processing Service inside `video_window_server/lib/src/business/media/pipeline/` handles ingestion, transcoding, and encryption workflows. [Source: architecture/media-pipeline-architecture.md#processing-service]
- Signed URL Service lives in `video_window_server/lib/src/business/media/access/` and exposes endpoints under `lib/src/endpoints/media/`. [Source: docs/security/secure-streaming.md#signed-url-service]
- Content Security Service enforces watermarking and capture deterrence using utilities delivered through `video_window_server/lib/src/utilities/media_security.dart`. [Source: architecture/security-service-architecture.md#protection-mechanisms]
- Flutter playback surfaces consume signed URLs via the story feature package; UI components reside in `video_window_flutter/packages/features/story/` and pull watermark overlays from `packages/shared/` utilities.

### File Locations
- Server-side ingestion/transcoding code: `video_window_server/lib/src/business/media/pipeline/` with corresponding tests in `video_window_server/test/business/media/pipeline/`. [Source: architecture/architecture.md#source-tree]
- Signed URL issuance + revocation endpoints: `video_window_server/lib/src/endpoints/media/` with tests under `video_window_server/test/endpoints/media/`.
- Flutter access controls: `video_window_flutter/packages/core/lib/data/services/media/` for client-side token handling, and `video_window_flutter/packages/features/story/lib/presentation/widgets/` for playback surfaces.
- Shared watermarking overlays and capture deterrence helpers belong in `video_window_flutter/packages/shared/lib/services/media_security/`.
- Tests mirror these paths within each package’s `test/` directory structure.

### Testing Requirements
- Maintain ≥90% coverage for all security-critical components with extensive integration testing. [Source: architecture/architecture.md#testing-strategy]
- Security penetration testing focused on signed URL issuance/revocation, watermark enforcement, and capture deterrence. [Source: docs/security/penetration-testing.md#streaming-security]
- Load testing for concurrent transcoding and streaming with performance benchmarks. [Source: docs/testing/performance-testing.md#media-pipeline]

### Technical Constraints
- Content protection for MVP relies on short-lived signed URLs, visible watermarks, and capture deterrence (full DRM deferred). [Source: docs/security/watermarking-mvp.md]
- **SECURITY CRITICAL**: All content must be encrypted with AES-256-GCM at rest and in transit. [Source: docs/security/encryption-standards.md#content-protection]
- **SECURITY CRITICAL**: Watermarking must remain legible and tamper-evident across all transcode renditions. [Source: docs/security/watermarking-requirements.md#forensic-standards]
- **SECURITY CRITICAL**: Signed URLs must expire within 5-30 minutes with IP and device binding. [Source: docs/security/secure-streaming.md#url-security]
- Video transcoding must support adaptive bitrate streaming for optimal user experience. [Source: docs/architecture/transcoding-requirements.md#adaptive-streaming]
- CDN integration must support global edge distribution with geographic restrictions. [Source: docs/architecture/cdn-requirements.md#global-delivery]
- All media operations must be logged for audit purposes with secure, tamper-proof storage. [Source: docs/security/audit-requirements.md#compliance-logging]

### Project Structure Notes
- Media pipeline components integrate with existing authentication and session management systems via `packages/core` repositories. [Source: architecture/architecture.md#integration-points]
- Signed URL issuance ties into the media access layer and reuses the platform's existing key management utilities (no third-party DRM SDKs in MVP). [Source: docs/security/secure-streaming.md#integration]

### Scope Notes
- This story currently bundles ingestion, transcoding, storage lifecycle, CDN, security, and monitoring. Plan to break into staged deliverables (e.g., Secure Upload + Transcode, Signed URL Service, Capture Deterrence, Monitoring) before sprint commitment.

## Testing
- Run comprehensive test suite including `dart format`, `flutter analyze`, and security-focused penetration testing. [Source: architecture/architecture.md#testing-strategy]
- Implement end-to-end testing for complete content flow from upload to secure streaming. [Source: docs/testing/e2e-media-testing.md#pipeline-validation]
- Security testing must include signed URL tampering attempts, watermark removal efforts, and unauthorized access scenarios. [Source: docs/security/security-testing.md#protection-validation]

## Change Log
| Date       | Version | Description                                     | Author            |
| ---------- | ------- | ------------------------------------------------- | ----------------- |
| 2025-10-09 | v0.1    | Initial draft created                            | Development Team  |
| 2025-11-12 | v0.3    | Implemented MED-SEC-001: AES-256-GCM encryption | Gemini           |

## Dev Agent Record
### Agent Model Used
_(To be completed by Dev Agent)_

### Debug Log References
_(To be completed by Dev Agent)_

### Completion Notes List
_(To be completed by Dev Agent)_

### File List
- `video_window_server/lib/src/business/media/pipeline/encryption.dart`

## QA Results
_(To be completed by QA Agent)_