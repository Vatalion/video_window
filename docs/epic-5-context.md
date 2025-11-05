# Epic 5 Context: Story Detail & Playback

**Generated:** 2025-11-04  
**Epic ID:** 5  
**Epic Title:** Story Detail & Playback  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Story Detail:** Full-screen video player with product metadata overlay
- **Video Player:** HLS with adaptive bitrate, custom controls (chewie)
- **Accessibility:** WCAG 2.1 AA compliance with captions and transcripts
- **Content Protection:** Forensic watermarking, screenshot detection, FLAG_SECURE
- **Sharing:** Deep links with social preview generation, save to wishlist

### Technology Stack
- Flutter: video_player 2.8.1, chewie 1.7.0, share_plus 7.2.0, screen_capture_detector 1.1.0, url_launcher 6.2.5
- Serverpod: Story endpoints, media token service, analytics ingestion
- Streaming: AWS MediaConvert HLS (360p/720p/1080p), CloudFront signed cookies (300s TTL)
- Protection: Watermark microservice (forensic overlay), SecureFlag SDK, ReplayKit hooks
- Sharing: Firebase Dynamic Links, social preview renderer Lambda

### Key Integration Points
- `packages/features/story/` - Story detail UI and secure video player
- `video_window_server/lib/src/endpoints/story/` - Story metadata and signed URL endpoints
- AWS CloudFront: Signed video delivery with token validation
- Watermark service: Per-user forensic watermark injection

### Implementation Patterns
- **Video Playback:** HLS with signed URLs (300s TTL), adaptive quality switching
- **Accessibility:** Synchronized captions (WebVTT), searchable transcripts, screen reader support
- **Content Protection:** Dynamic watermark overlay, capture deterrence (FLAG_SECURE Android, ReplayKit iOS)
- **Deep Linking:** Firebase Dynamic Links with UTM tracking, social preview cards

### Story Dependencies
1. **5.1:** Story detail page implementation (foundation)
2. **5.2:** Accessible playback & transcripts (depends on 5.1)
3. **5.3:** Share & save functionality (depends on 5.1)

### Success Criteria
- Story detail loads in <3 seconds
- Captions/transcripts available for 100% of content
- Content protection prevents recording/screenshots
- Deep links generate proper social preview cards
- Accessibility audit passes WCAG 2.1 AA

**Reference:** See `docs/tech-spec-epic-5.md` for full specification
