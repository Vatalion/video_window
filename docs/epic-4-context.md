# Epic 4 Context: Video Feed (Discovery)

**Generated:** 2025-11-04  
**Epic ID:** 4  
**Epic Title:** Video Feed (Discovery)  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Feed Style:** TikTok-style vertical video pager with autoplay
- **Playback:** HLS streaming with adaptive bitrate (360p/720p/1080p)
- **Performance:** 60fps target, <2% jank rate, 120Hz display mode
- **Preloading:** Smart video cache with 3-5 ahead strategy
- **Personalization:** Recommendation engine (LightFM) with user preferences
- **CDN:** CloudFront with signed cookies, 120s edge cache

### Technology Stack
- Flutter: video_player 2.8.1, infinite_scroll_pagination 4.0.0, wakelock_plus 1.2.5, flutter_displaymode 0.6.0
- Streaming: AWS S3 + CloudFront + MediaConvert (HLS renditions)
- Backend: Serverpod feed endpoints, Redis cursor tracking
- Recommendation: LightFM 1.17 Python microservice via gRPC
- Analytics: Segment SDK, Datadog RUM, Firebase Analytics, Sentry

### Key Integration Points
- `packages/features/timeline/` - Feed UI and video player widgets
- `video_window_server/lib/src/endpoints/feed/` - Feed and interaction endpoints
- AWS CloudFront: HLS video delivery with signed cookies (300s TTL)
- Recommendation microservice: Personalized feed ranking via gRPC

### Implementation Patterns
- **Infinite Scroll:** Cursor-based pagination with Redis state caching
- **Video Preloading:** Queue 3-5 videos ahead, maintain cache of 10 viewed
- **Performance:** Display mode 120Hz, visibility detector for autoplay triggers
- **Personalization:** User interaction signals (views, likes, shares) feed recommendation model

### Story Dependencies
1. **4.1:** Video feed implementation (foundation)
2. **4.2:** Infinite scroll & pagination (depends on 4.1)
3. **4.3:** Preloading & caching strategy (depends on 4.1, 4.2)
4. **4.4:** Performance optimization (depends on all above)
5. **4.5:** Recommendation engine integration (parallel with 4.3)
6. **4.6:** Feed personalization (depends on 4.5)

### Success Criteria
- Feed maintains 60fps scrolling on target devices
- Video playback starts in <2 seconds
- Jank rate <2% measured via flutter_displaymode
- Personalization improves engagement by 20%+ vs non-personalized
- Preloading reduces buffer events by 80%

**Reference:** See `docs/tech-spec-epic-4.md` for full specification
