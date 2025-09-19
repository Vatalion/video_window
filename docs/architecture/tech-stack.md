# Video Window Tech Stack Overview

## Codebase Structure
- **Flutter client** (`crypto_market/lib/`): Vertical video app targeting iOS first, structured with feature modules for feed, stories, commerce, and community interactions.
- **Shared UI toolkit** (`crypto_market/lib/ui/`): Houses theming, typography, and reusable components aligned with the artisan brand direction.
- **Data layer** (`crypto_market/lib/data/`): Repository pattern talking to Serverpod-generated clients for stories, commerce, authentication, and interactions.
- **Testing suites**
  - Unit & widget tests under `crypto_market/test/`
  - Integration & golden tests under `crypto_market/integration_test/`
  - Tooling scripts in `scripts/` orchestrate CI formatting/analyze/test gates.

## Core Services
| Capability | Provider | Notes |
|------------|----------|-------|
| Backend runtime | Serverpod on AWS (EC2 + RDS) | REST/gRPC endpoints for feed, stories, commerce, moderation; WebSocket hub for interactions. |
| Media storage & CDN | Amazon S3 + CloudFront | Handles vertical video uploads, transcoded variants, and thumbnails. |
| Payments & payouts | Stripe Checkout + Stripe Connect Standard | Supports object purchases and service booking deposits; KYC/AML triggers after $600. |
| Maps & navigation | Mapbox SDK | Service radius visualization, deep links to Apple Maps for directions. |
| Notifications | Firebase Cloud Messaging (APNs bridge) | Real-time updates for creators and buyers. |
| Email messaging | Twilio SendGrid | Transactional receipts, booking confirmations, account updates. |

## Environment Strategy
- **Local Development**: Flutter 3.35.1 toolchain, Serverpod dev server via Docker, Stripe/Mapbox sandbox keys from `.env.local` (excluded from git). `scripts/dev-validate.sh` mirrors CI gates.
- **Staging**: Auto-deployed from `develop` branch, using Stripe test mode and Mapbox staging token; limited to internal testers.
- **Production**: Manual promotion from staging after QA sign-off with `qa:approved`. Infrastructure codified via Terraform (future item) and monitored with CloudWatch dashboards.

## Data & Telemetry
- Event capture via Serverpod logging tables; aggregated metrics feed the Phase 2 Vitality Dashboard.
- Crash analytics handled via Sentry (Flutter SDK) to expedite triage.
- Privacy: All personally identifiable information stored encrypted at rest; audit logs retained for 12 months.

## Integration Boundaries
- API models shared through generated Dart clients checked into `crypto_market/lib/api/`.
- Third-party SDKs reviewed in architecture review to avoid binary bloat.
- Feature flags managed via remote config document (`lib/config/feature_flags.dart`) to gate deferred backlog items.

Refer to [coding-standards.md](coding-standards.md) for implementation conventions and [development-workflow.md](development-workflow.md) for Dev↔QA collaboration agreements.
