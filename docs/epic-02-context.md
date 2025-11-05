# Epic 02 Context: Core Platform Services

**Generated:** 2025-11-04  
**Epic ID:** 02  
**Epic Title:** Core Platform Services  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Design System:** Shared package with design tokens, theme, typography (packages/shared)
- **Navigation:** go_router 12.1.3+ with type-safe routing and deep linking
- **Configuration:** Environment-based config with feature flags (shared_preferences)
- **Analytics:** Event tracking foundation with BigQuery integration

### Technology Stack
- Flutter 3.35.4+, go_router 12.1.3+, shared_preferences
- Custom JSON-based design token system
- flutter_bloc for navigation state
- BigQuery for analytics pipeline

### Key Integration Points
- `packages/shared/lib/design_system/` - Design tokens and theme
- `packages/shared/lib/widgets/` - Reusable UI components
- `lib/app_shell/` - Navigation and routing infrastructure
- Analytics service foundation for event tracking

### Implementation Patterns
- **Design Tokens:** JSON-based color, typography, spacing tokens
- **Navigation:** Declarative routing with go_router
- **Feature Flags:** Runtime configuration without redeployment
- **Analytics:** Event-driven architecture with BigQuery sink

### Story Dependencies
1. **02.1:** Design system foundation (base)
2. **02.2:** Navigation infrastructure (depends on 02.1)
3. **02.3:** Configuration management (parallel with 02.2)
4. **02.4:** Analytics foundation (depends on all)

### Success Criteria
- Design system provides consistent UI across all features
- Navigation supports deep linking and type-safe routing
- Feature flags enable A/B testing and gradual rollouts
- Analytics tracks all critical user journeys

**Reference:** See `docs/tech-spec-epic-02.md` for full specification
