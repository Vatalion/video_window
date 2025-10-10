# Technology Stack

## Technology Stack Table
| Category | Technology | Version | Purpose | Rationale |
| --- | --- | --- | --- | --- |
| Language (Client) | Dart | 3.5.6 | Flutter application logic | Matches Version Policy (Flutter 3.19.6) |
| Framework (Client) | Flutter | 3.19.6 | Cross-platform mobile UI | Single codebase, video-friendly, team alignment |
| Language (Backend) | Dart | 3.5.6 | Serverpod modules shared with client | Keeps models/shared libs consistent |
| Backend Framework | Serverpod | 2.9.x | Modular monolith server | Native Dart, built-in RPC, scheduler |
| Client Generated | serverpod_client | 2.9.x | Type-safe API client | Auto-generated from Serverpod endpoints |
| Database | PostgreSQL | 15.x | Primary relational store | Strong transactions, timer queries, JSONB support |
| Cache/Queues | Redis (ElastiCache) | 7.x | Timer queue, caching, pub/sub | Integrates with Serverpod task runner |
| Object Storage | Amazon S3 | Latest | Raw uploads + HLS renditions | Durable, integrates with CloudFront |
| CDN | CloudFront | Latest | Secure HLS delivery | Signed URL support, global distribution |
| Payment PSP | Stripe Connect Express | Latest API | Checkout, payouts, compliance | SAQ A scope, mature features |
| Notification Push | Firebase Cloud Messaging / APNs | Latest | Buyer/maker notifications | Platform standard |
| Notification Email | SendGrid / Postmark | Latest | Transactional email | Reliable deliverability, templating |
| Notification SMS | Twilio | Latest | OTP + auction alerts | Global reach, proven |
| State Management | flutter_bloc | 8.1.5 | Client state management | Centralized BLoC architecture |
| Navigation | go_router | 12.1.3 | Declarative routing | Type-safe navigation, deep linking |
| Workspace | Melos | Latest | Multi-package management | Monorepo with unified packages |
| Observability | OpenTelemetry + Prometheus/Grafana | Latest | Metrics/traces/logs | NFR compliance |
| CI/CD | GitHub Actions | Latest | Format/analyze/test gates | Mirrors PRD flows |
| IaC | Terraform | 1.7.x | Provision AWS resources | Declarative, widely adopted |
| Secrets Management | AWS Secrets Manager | Latest | Secure credential storage | Rotation support, API access |
| Analytics Warehouse | BigQuery or Snowflake (pilot: BigQuery) | Latest | KPI aggregation | Supports SQL-based ETL |
| BI / Dashboards | Looker Studio | Latest | KPI visualization | Quick iteration, integrates with BigQuery |

## Removed Dependencies (Serverpod-First Approach)
The following technologies have been removed in favor of Serverpod's built-in capabilities:

| Removed Technology | Replaced By | Reason |
| --- | --- | --- |
| drift | Serverpod Database | Serverpod handles database operations |
| retrofit | serverpod_client | Auto-generated type-safe clients |
| hive | Serverpod Storage | Serverpod manages file storage |
| dio | serverpod_client | No need for manual HTTP clients |
| shared_preferences | Serverpod Config | Serverpod handles configuration |
| path_provider | Serverpod Storage | Serverpod manages file paths |
| encrypt | Serverpod Security | Serverpod handles encryption |
| jwt_decode | Serverpod Auth | Built-in authentication |