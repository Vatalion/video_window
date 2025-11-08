# Story 6-3: Content Security & Anti-Piracy System

## Status
Ready for Dev

## Story
**As a** security engineering lead,
**I want** multi-DRM licensing, forensic watermarking, and automated anti-piracy response,
**so that** premium video assets remain protected and enforcement actions trigger immediately when misuse is detected.

## Acceptance Criteria
1. `drm_license_service.dart` issues Widevine, FairPlay, and PlayReady licenses with per-user entitlements, device binding, and 5-minute TTL, persisting audit logs for every issuance. *(Ref: docs/tech-spec-epic-6.md – Implementation Guide §4 & DRM License Service pseudocode)*
2. NexGuard forensic watermark payloads embed `userId`, `deviceId`, and `sessionId` metadata in every distributed asset; extraction tooling can recover identifiers from sampled leaks. *(Ref: docs/tech-spec-epic-6.md – Forensic Watermarking Service)*
3. Flutter playback integrates multi-DRM negotiation plus capture deterrence (FLAG_SECURE, UIScreen.isCaptured hooks) and attaches forensic claims via `forensic_watermark_client.dart`. *(Ref: docs/tech-spec-epic-6.md – Implementation Guide §5)*
4. Forter fingerprinting agent 3.2.2 monitors CDN traffic, emitting piracy alerts to EventBridge `media-pipeline-events`; Lambda `piracy-escalation@2025-10` files takedown tickets within 10 minutes. *(Ref: docs/tech-spec-epic-6.md – Implementation Guide §6)*
5. Security dashboards in Grafana and Kibana surface DRM success rate ≥ 99.7%, forensic verification ≥ 99%, and piracy alert false positives ≤ 2%. *(Ref: docs/tech-spec-epic-6.md – Monitoring & Analytics & Success Metrics)*
6. Infrastructure codified in `infrastructure/terraform/media_drm.tf` provisions CloudHSM cluster, DRM license endpoints, NexGuard integration, and SNS `piracy-escalations` topic with environment-specific secrets fetched from Vault. *(Ref: docs/tech-spec-epic-6.md – Environment Configuration & Infrastructure Requirements)*

## Prerequisites
1. Story 6.1 – Media Pipeline & MVP Content Protection (baseline encryption and signed URLs).
2. Story 6.2 – Advanced Video Processing & Optimization (multi-rendition pipeline available for protection overlay).
3. Security runbooks and KMS policies defined in `docs/security/content-protection-security-research.md`. 
4. Vault namespaces and CloudHSM cluster activated per `docs/architecture/security-configuration.md`.

## Tasks / Subtasks

### Phase 1 – Multi-DRM Licensing
- [ ] Implement `drm_license_service.dart` with adapters for Widevine, FairPlay, and PlayReady SDKs 17.0.0/4.1.0/4.5.3 respectively; include usage policy enforcement (resolution caps, concurrent streams). *(Ref: docs/tech-spec-epic-6.md – DRM License Service)*
  - [ ] Build unit tests in `drm_license_service_test.dart` covering entitlement checks, device binding, and error handling paths. *(Ref: docs/tech-spec-epic-6.md – Source Tree)*
  - [ ] Expose `media_protection_endpoint.dart` for license requests with rate limiting and audit logging via `media_pipeline_observer.dart`. *(Ref: docs/tech-spec-epic-6.md – Source Tree & Implementation Guide)*
- [ ] Configure CloudHSM-backed key storage and Vault secret sync for DRM signing keys, documenting rotation workflow. *(Ref: docs/tech-spec-epic-6.md – Security & Key Management)*

### Phase 2 – Forensic Watermarking & Client Enforcement
- [ ] Extend `watermark_service.dart` to request NexGuard payloads (`TEMPLATE_ID: vw-forensic-watermark-v2`), embed per-session markers, and log metadata in relational store. *(Ref: docs/tech-spec-epic-6.md – Environment Configuration FORENSIC_WATERMARK block)*
- [ ] Create Flutter `forensic_watermark_client.dart` to attach claims to playback requests and respond to extraction callbacks. *(Ref: docs/tech-spec-epic-6.md – Source Tree)*
- [ ] Update `media_playback_service.dart` to negotiate DRM across platforms (Widevine, FairPlay, PlayReady) and enforce capture deterrence (FLAG_SECURE, UIScreen.isCaptured observer, brightness dimming). *(Ref: docs/architecture/mobile-capture-prevention.md)*
- [ ] Implement automated watermark extraction CLI for security ops to validate suspected leaks. *(Ref: docs/security/watermarking-requirements.md#forensic-tooling)*

### Phase 3 – Anti-Piracy Monitoring & Response
- [ ] Deploy Forter agent 3.2.2 across CloudFront logs, streaming telemetry to EventBridge `media-pipeline-events`. *(Ref: docs/tech-spec-epic-6.md – Implementation Guide §6)*
- [ ] Implement Lambda `piracy-escalation@2025-10` to correlate alerts, enrich with user/device metadata, and open tickets in security queue + send to SNS `piracy-escalations`. *(Ref: docs/tech-spec-epic-6.md – Monitoring & Analytics)*
- [ ] Create Kibana dashboards for piracy trends and DMCA response times; Grafana panels for DRM license success and watermark extraction latency. *(Ref: docs/tech-spec-epic-6.md – Monitoring & Analytics)*
- [ ] Define escalation runbook `docs/runbooks/piracy-response.md` with SLA (10 minutes) and communication steps. *(Ref: docs/security/incident-response.md)*

### Phase 4 – Compliance, Auditing & Testing
- [ ] Populate `content_access_logs` with license issuance, playback attempts, and takedown actions; secure retention policy ≥ 1 year. *(Ref: docs/tech-spec-epic-6.md – Content Access Log Entity)*
- [ ] Write integration tests under `video_window_server/test/endpoints/media/` validating license issuance, watermark embedding, and piracy alert webhooks (mocked). *(Ref: docs/tech-spec-epic-6.md – Source Tree)*
- [ ] Add CI checks in `media_pipeline_checks.yaml` for DRM linting (key expiry, license formats) and watermark smoke tests. *(Ref: docs/tech-spec-epic-6.md – Workflow Orchestration)*
- [ ] Conduct red-team style tests simulating token theft and watermark stripping; document findings in `docs/security/pentest/media-pipeline-2025q4.md`. *(Ref: docs/security/security-testing.md#protection-validation)*

## Dev Notes
- Audit logging is mandatory; use `SecurityLogger` to push to tamper-proof storage defined in `docs/security/audit-logging.md#media-pipeline`. 
- License issuance service must handle geo-restrictions and age gating using policies from `docs/compliance/content-compliance.md`. 
- Coordinate with infrastructure team for Vault access policies; secrets should reference `vault://observability/...` patterns already present in environment config. 
- Mobile DRM players require platform-specific SDK initialization; reuse guidelines in `docs/architecture/mobile-drm-integration.md`.

## Testing
- Execute `melos run test:unit` plus targeted suite `melos run test -- --tags drm` for new license logic. *(Ref: docs/tech-spec-epic-6.md – Testing Strategy)*
- Run integration harness that simulates playback requests across Widevine/FairPlay/PlayReady using QA keys. *(Ref: docs/testing/media-pipeline-testing.md#integration)*
- Validate Forter and EventBridge flows in staging by triggering synthetic piracy events; ensure Lambda escalations complete within SLA. *(Ref: docs/tech-spec-epic-6.md – Success Metrics)*
- Perform forensic watermark extraction on staging leaks to confirm payload decodes to originating user/device. *(Ref: docs/security/watermarking-requirements.md#verification)*

## Change Log
| Date       | Version | Description                  | Author            |
| ---------- | ------- | ---------------------------- | ----------------- |
| 2025-10-29 | v0.1    | Initial story definition     | GitHub Copilot AI |

## Dev Agent Record

### Context Reference

- `docs/stories/6-3-content-security-and-anti-piracy-system.context.xml`

### Agent Model Used

<!-- Will be populated during dev-story execution -->

### Debug Log References

<!-- Will be populated during dev-story execution -->

### Completion Notes List

<!-- Will be populated during dev-story execution -->

### File List

<!-- Will be populated during dev-story execution -->
