# Video Window Greenfield Architecture Guide

## Introduction
- **Purpose**: Guide the implementation of the Video Window Flutter marketplace from scratch using feature-package modularization and modern architecture patterns.
- **Problem Space**: The product aims to reduce the complexity between creators and buyers while making handcrafted products entertaining and shoppable.
- **Scope of Document**: Establish the complete implementation roadmap for a greenfield project with feature packages, Serverpod backend, and media pipeline.

## Product Context
- The PRD (`docs/prd.md:1`) positions Video Window as a TikTok-style marketplace where short-form stories lead into auction commerce.
- Two core business needs surfaced during elicitation: 1) simplify creator↔buyer interactions, 2) deliver compelling entertainment around handcrafted goods.
- Current Flutter project does not yet reflect the breadth of PRD functionality; most features exist only as test scaffolding or narrative documents (`parallel_draft_context/`).

## Project Foundation
- **Root layout**: Clean workspace with packages/, serverpod/, docs/, and tooling directories. Basic Flutter scaffold in place as starting point.
- **Current state**: Minimal Flutter application with basic navigation scaffold. Ready for feature-package implementation using Melos workspace management.
- **Architecture decisions**: Serverpod-first backend approach, unified package structure, centralized BLoC state management, and clean architecture patterns established.
- **Documentation assets**: Complete PRD, architecture specifications, and implementation guides ready to direct development.

## Technology Stack Implementation
- **Serverpod-first approach**: Dependencies aligned with Serverpod 2.9.x architecture, removing conflicting local database and networking libraries.
- **Core dependencies**: `flutter_bloc` for state management, `go_router` for navigation, `serverpod_client` for backend communication.
- **Media and platform**: `camera`, `video_player`, `flutter_secure_storage`, `local_auth` for video capture and security features.
- **Development tools**: Melos workspace management, code generation with Serverpod CLI, comprehensive testing framework.

## Target Application Architecture
- **Package structure**: Unified package architecture with `packages/mobile_client/`, `packages/core/`, `packages/shared_models/`, `packages/design_system/`, and `packages/features/`.
- **State management**: Centralized BLoC architecture with global app/auth state in mobile_client and feature-specific BLoCs in feature packages.
- **Data layer**: Clean architecture with domain/data/presentation layers in each feature package, Serverpod integration for all backend operations.

## Media Pipeline Implementation Plan
- **Video capture**: Flutter `camera` package for device recording, `flutter_sound` for audio capture.
- **Processing pipeline**: Serverpod backend integration with FFmpeg for HLS transcoding and watermarking.
- **Storage and delivery**: AWS S3 + CloudFront CDN with signed URLs for secure content delivery.
- **Progress tracking**: Real-time WebSocket updates for processing status via Serverpod.

## Feature Package Architecture
- **Unified package structure**: Melos workspace with `packages/` directory containing core, shared_models, design_system, and feature packages.
- **Feature isolation**: Each major feature (auth, timeline, publishing, commerce) in its own package with clean architecture layers.
- **Dependency management**: Internal packages use path dependencies, Serverpod provides generated client code for backend integration.
- **Implementation order**: Core packages first, then auth package, followed by other features in priority order.

## Domain Architecture Implementation
- **Authentication & Security**: Serverpod identity module with comprehensive security features (rate limiting, MFA, session management) integrated with Flutter secure storage.
- **Timeline Editing**: Dedicated timeline package with BLoC state management for tracks, segments, overlays, and transitions.
- **Publishing**: Complete publishing workflow with content processing, status management, and real-time progress tracking.
- **Commerce**: Full auction marketplace with offers, bidding, payments via Stripe Connect, and order fulfillment.

## Infrastructure & Observability Plan
- **Serverpod backend**: Complete infrastructure setup with PostgreSQL, Redis, and cloud storage integration.
- **Observability**: OpenTelemetry integration for metrics, traces, and logging with CloudWatch monitoring.
- **Analytics**: Event tracking for user behavior and business KPIs with BigQuery integration.
- **CI/CD**: GitHub Actions workflows for testing, building, and deployment across environments.

## Implementation Roadmap
- **Phase 1 (Foundation)**: Setup Melos workspace, create core packages, configure Serverpod integration.
- **Phase 2 (Authentication)**: Implement identity module and Flutter auth package with secure token management.
- **Phase 3 (Core Features)**: Build timeline editor, publishing workflow, and media processing pipeline.
- **Phase 4 (Commerce)**: Implement offers, auctions, payments, and order fulfillment features.
- **Phase 5 (Polish)**: Add analytics, observability, performance optimization, and comprehensive testing.

## Development Guidelines
1. **Package-First Development**: Each feature implemented as independent package with clear interfaces and dependencies.
2. **Serverpod Integration**: All backend operations use generated Serverpod client code with proper error handling.
3. **Clean Architecture**: Domain/data/presentation layer separation in all packages with dependency inversion.
4. **Progressive Enhancement**: Start with core functionality, add advanced features incrementally.
5. **Comprehensive Testing**: Unit, integration, and end-to-end tests for all packages and workflows.
6. **Documentation**: Keep architecture documents updated as implementation progresses.
7. **Performance Monitoring**: Implement observability from the beginning with performance budgets.

## Conclusion
- This greenfield project provides a clean foundation for implementing the Video Window marketplace with modern architecture patterns.
- The unified package structure with Serverpod-first approach ensures scalability and maintainability as the platform grows.
- All planned capabilities will be implemented according to the established architecture roadmap with proper testing and documentation.
