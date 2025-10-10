# Architecture Review Notes for Leads

Status: Draft v0.2 — Companion to `docs/architecture.md` (updated 2025-09-30).

## Purpose
Summarize key decisions from the architecture blueprint and capture items requiring confirmation or additional local conventions before development begins.

## Highlights to Confirm
- **Infrastructure Baseline:** ✅ Leads aligned on AWS (Fargate, RDS, ElastiCache, S3/CloudFront). Future multi-cloud requirements will be handled via Terraform modules.
- **Stripe Connect Express:** ✅ Approved by finance/legal for MVP. Settlement SLAs tracked in PRD; no additional PSP needed.
- **Notification Providers:** ✅ Proceed with SendGrid + Twilio. Internal platform prefers leveraging existing contracts; procurement ticket opened (#PROC-582).
- **Analytics Warehouse:** ✅ BigQuery accepted for MVP. Data team flagged lightweight export path should we pivot to Snowflake later.
- **Observability Stack:** ✅ Use OpenTelemetry → Prometheus/Grafana. Datadog optional for prod mirrors; leave hooks in IaC for enablement.

## Local Conventions & Guardrails
- **Branching/Commits:** Use `story/<id>-<slug>` branches with Conventional Commits referencing the story id (per `.bmad-core/core-config.yaml`).
- **Story Files:** Update `docs/stories/...` with status, tasks, and change log before requesting review (guardrail enforced by PM/QA personas).
- **Secrets Handling:** Local `.env` files stay untracked; production credentials sourced via AWS Secrets Manager. Git hooks/pre-commit enforce leak prevention.
- **Testing Expectations:** Minimum 80% coverage per package; PRs must include unit/integration tests relevant to their scope. Utilize `melos run test` or `melos run validate` before pushing.
- **Code Style:** Follow `docs/architecture/coding-standards.md` (unified package structure, BLoC patterns, Serverpod integration). Any deviations require architecture sign-off and documentation.
- **Workspace Commands:** Use `melos run <command>` for all workspace operations (deps, test, build, generate).

## Open Questions for Leads — Resolutions
1. **Internationalization Roadmap:** ✅ MVP ships English-only; i18n hooks added during Epic 3. Future locales planned post-pilot.
2. **Legal Copy Ownership:** ✅ Product Legal (owner: J. Rivera) will maintain policy documents; PM ensures updates reflected in-app each release.
3. **Support Workflow Tooling:** ✅ Issues sync to existing Zendesk via webhook export (Epic 14 backlog task). Internal support portal remains system of record.
4. **Media Storage Compliance:** ✅ No additional residency constraints beyond us-east-1 for pilot. Reassess before EU launch.
5. **Analytics Access:** ✅ Weekly dashboard delivery to PM, Marketing, Operations; monthly executive digest auto-generated from Looker Studio.

All confirmations captured 2025-09-30 during leadership sync. Revisit if business or compliance scope shifts.

## Open Actions (Track to Closure)
- **#PROC-582 Notification Providers:** Procurement following up with vendor management; due 2025-10-05 to unblock Epic 11.
- **Hi-Fi UX Mockups:** UX expert to deliver final visuals by 2025-10-07 (see `docs/architecture/ux-dev-handoff.md`).
- **Design Tokens:** Populate `packages/design_system/lib/tokens.dart` post mockup delivery; reference unified package architecture.
- **Melos Workspace Setup:** Complete `melos.yaml` configuration and package structure setup.
