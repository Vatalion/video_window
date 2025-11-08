# Story 6-2: Advanced Video Processing & Optimization

## Status
Ready for Dev

## Story
**As a** platform video pipeline owner,
**I want** optimized, automated transcoding and packaging workflows with performance observability,
**so that** every uploaded asset delivers the best possible quality and startup latency across devices while staying cost efficient.

## Acceptance Criteria
1. MediaConvert jobs are orchestrated through Step Functions `media-transcode-orchestrator@2025-09` with automatic retries, DLQ routing, and job status reporting. *(Ref: docs/tech-spec-epic-6.md – Implementation Guide §2)*
2. GPU-accelerated FFmpeg workers (EKS `g5-media-transcode`) produce HLS renditions at 360p, 720p, 1080p, and 2160p with bitrate ladders matching template `vw-media-hls-v3`. *(Ref: docs/tech-spec-epic-6.md – Technology Stack & Transcode Service blueprint)*
3. Shaka Packager outputs coordinated HLS + DASH manifests, stored under `s3://vw-media-origin-prod/manifests/`, with CloudFront cache invalidations issued on completion. *(Ref: docs/tech-spec-epic-6.md – Implementation Guide §3)*
4. Rendition health metrics (per-rung transcode duration, error rates, p95 startup) are emitted via `media_pipeline_observer.dart` to Datadog (`media.transcode.duration_ms`) and Segment events (`media_transcode_completed`). *(Ref: docs/tech-spec-epic-6.md – Monitoring & Analytics)*
5. End-to-end integration tests cover upload → transcode → manifest availability, including fallback path when a rendition fails; failures surface actionable alerts in Slack via EventBridge rule `media-transcode-alerts`. *(Ref: docs/tech-spec-epic-6.md – Testing & Compliance)*
6. Terraform definitions in `infrastructure/terraform/media_pipeline.tf` capture MediaConvert roles, queues, and Step Functions resources with parameterized environment overlays. *(Ref: docs/tech-spec-epic-6.md – Environment Configuration & Infrastructure Requirements)*

## Prerequisites
1. Story 6.1 – Media Pipeline & MVP Content Protection (ensures secure upload + KMS metadata handoff).
2. Terraform base networking/observability modules from Epic 2 infrastructure stories. *(Ref: docs/architecture/project-structure-implementation.md)*
3. Access to AWS accounts with MediaConvert, Elemental, and Step Functions quotas validated. *(Ref: docs/security/security-configuration.md#cloud-accounts)*

## Tasks / Subtasks

### Phase 1 – Transcode Orchestration
- [ ] Implement `transcode_service.dart` to assemble MediaConvert requests using template `vw-media-hls-v3`, injecting per-asset renditions and Speke key provider settings. *(Ref: docs/tech-spec-epic-6.md – Transcode Service pseudo-code)*
  - [ ] Map quality ladder presets (360p/720p/1080p/2160p) to job outputs with bitrate targets and GOP sizing. *(Ref: docs/architecture/transcoding-requirements.md)*
  - [ ] Add GPU acceleration flags aligned with FFmpeg image `ghcr.io/videowindow/ffmpeg:6.1.1-gpu` for high-resolution jobs. *(Ref: docs/tech-spec-epic-6.md – Technology Stack)*
- [ ] Create `media_transcode_endpoint.dart` handling job submission, polling, and exponential backoff retries with DLQ fallback. *(Ref: docs/tech-spec-epic-6.md – Source Tree & File Directives)*
- [ ] Wire AWS Step Functions client in `media_pipeline_step_function.dart`, defining state transitions (SubmitJob → WaitStatus → Success/Fail) with CloudWatch alarms for timeout. *(Ref: docs/tech-spec-epic-6.md – Implementation Guide §2)*

### Phase 2 – Packaging & Distribution Optimization
- [ ] Integrate Shaka Packager invocation post MediaConvert to emit DASH alongside HLS manifests; persist under `manifests/` prefix with versioned naming (`assetId/rendition.mpd`). *(Ref: docs/tech-spec-epic-6.md – Implementation Guide §3)*
- [ ] Configure CloudFront invalidations via Terraform when manifests update (use Lambda@Edge or Step Functions task). *(Ref: docs/architecture/cdn-integration.md#cache-invalidation)*
- [ ] Extend `media_pipeline_observer.dart` to publish Segment `media_packaged` and Datadog gauge for manifest generation latency. *(Ref: docs/tech-spec-epic-6.md – Monitoring & Analytics)*
- [ ] Add fallback routine that marks missing renditions as degraded but still serves available qualities with alerting. *(Ref: docs/tech-spec-epic-6.md – Resilience Considerations)*

### Phase 3 – Performance Benchmarking & Tooling
- [ ] Build `transcode_service_test.dart` covering job assembly, rendition fallback, and template overrides. *(Ref: docs/tech-spec-epic-6.md – Testing & Compliance)*
- [ ] Add integration tests under `video_window_server/test/endpoints/media/` validating end-to-end job lifecycle with mocked AWS clients. *(Ref: docs/tech-spec-epic-6.md – Source Tree)*
- [ ] Update `media_pipeline_checks.yaml` CI workflow to run ffmpeg smoke tests (`ffprobe`, decode) and assert GPU nodes registered. *(Ref: docs/tech-spec-epic-6.md – Workflow Orchestration)*
- [ ] Instrument Datadog synthetic `story-startup` to log pre/post optimization metrics and capture 2.5s p95 goal breaches. *(Ref: docs/tech-spec-epic-6.md – Success Metrics)*
- [ ] Document runbooks in `docs/runbooks/media-transcode.md` for investigating job failures and scaling GPU node groups. *(Ref: docs/architecture/performance-optimization-guide.md)*

## Dev Notes
- Server-side files live under `video_window_server/lib/src/services/media_pipeline/` and `.../endpoints/media/` as outlined in the epic spec. Ensure tests mirror in `video_window_server/test`. *(Ref: docs/tech-spec-epic-6.md – Source Tree & File Directives)*
- Coordinate Terraform updates (`media_pipeline.tf`) with environment overlays defined in `docs/environment/config/media-pipeline*.yaml`. *(Ref: docs/tech-spec-epic-6.md – Environment Configuration)*
- GPU workload scheduling requires node taints `gpu=true:NoSchedule`; update Kubernetes manifests accordingly. *(Ref: docs/architecture/media-pipeline-architecture.md#kubernetes-workloads)*
- Shaka Packager binary is bundled via our build pipeline; ensure version `2.6.1` is pinned in CI cache. *(Ref: docs/tech-spec-epic-6.md – Technology Stack)*

## Testing
- Execute `melos run test:unit` covering new services and endpoints. *(Ref: docs/tech-spec-epic-6.md – Testing Strategy)*
- Run targeted integration suite `melos run test -- --tags media-transcode` once AWS mocks configured. *(Ref: docs/testing/media-pipeline-testing.md#integration)*
- Schedule synthetic playback tests post-deploy to confirm p95 startup ≤ 2.5s. *(Ref: docs/tech-spec-epic-6.md – Success Metrics)*
- Verify Terraform plan/apply in staging with `terraform workspace select staging && terraform apply -target=module.media_pipeline`. *(Ref: docs/tech-spec-epic-6.md – Infrastructure Requirements)*

## Change Log
| Date       | Version | Description                  | Author            |
| ---------- | ------- | ---------------------------- | ----------------- |
| 2025-10-29 | v0.1    | Initial story definition     | GitHub Copilot AI |

## Dev Agent Record

### Context Reference

- `docs/stories/6-2-advanced-video-processing-and-optimization.context.xml`

### Agent Model Used

<!-- Will be populated during dev-story execution -->

### Debug Log References

<!-- Will be populated during dev-story execution -->

### Completion Notes List

<!-- Will be populated during dev-story execution -->

### File List

<!-- Will be populated during dev-story execution -->
