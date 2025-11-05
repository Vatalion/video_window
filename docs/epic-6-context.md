# Epic 6 Context: Media Pipeline & Content Protection

**Generated:** 2025-11-04  
**Epic ID:** 6  
**Epic Title:** Media Pipeline & Content Protection  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Media Pipeline:** S3 upload → MediaConvert transcoding → HLS output → CloudFront delivery
- **Transcoding:** Multi-bitrate HLS (360p/720p/1080p) via AWS MediaConvert templates
- **DRM:** Multi-DRM support (Widevine, FairPlay, PlayReady) with license server
- **Watermarking:** NAGRA NexGuard forensic watermarks (per-user payload injection)
- **Security:** AES-256-GCM encryption, AWS KMS key management, CloudHSM for DRM keys

### Technology Stack
- Processing: AWS MediaConvert (template vw-media-hls-v3), FFmpeg 6.1.1 (GPU-accelerated), Shaka Packager 2.6.1
- Storage: AWS S3 (intelligent tiering), CloudFront distribution, AWS Global Accelerator
- DRM: Widevine CAS SDK 17.0.0, FairPlay Streaming SDK 4.1.0, PlayReady Server SDK 4.5.3
- Watermark: NAGRA NexGuard forensic watermark SaaS v7.4
- Security: AWS KMS (multi-region key), CloudHSM cluster, HashiCorp Vault 1.15.3
- Orchestration: AWS Step Functions, EventBridge, SQS with DLQ

### Key Integration Points
- `video_window_server/lib/src/endpoints/media/` - Media upload and transcoding endpoints
- `video_window_server/lib/src/services/media_pipeline/` - Upload, transcode, DRM, watermark services
- AWS MediaConvert: Video transcoding job orchestration
- DRM License Services: Widevine, FairPlay, PlayReady token issuance

### Implementation Patterns
- **Upload Flow:** Chunked upload → ClamAV virus scan → KMS envelope encryption → S3 storage
- **Transcoding:** MediaConvert jobs orchestrated by Step Functions with EventBridge triggers
- **DRM Licensing:** Per-device/session license generation with token expiry
- **Forensic Watermarking:** Per-user payload injection for content leak tracing

### Story Dependencies
1. **6.1:** Media pipeline & content protection (foundation)
2. **6.2:** Advanced video processing & optimization (depends on 6.1)
3. **6.3:** Content security & anti-piracy system (depends on 6.1, 6.2)

### Success Criteria
- Video transcoding completes in <5 minutes for 10min source
- DRM licenses issued in <500ms (P95)
- Watermarking enables forensic content leak tracing
- Pipeline handles 1000 concurrent uploads
- Security audit passes for KMS/CloudHSM configuration

**Reference:** See `docs/tech-spec-epic-6.md` for full specification
