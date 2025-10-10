# ADR-0001: Direction Pivot to Auctions Platform

**Date:** 2025-09-22
**Status:** Accepted
**Decider(s):** Product Team, Technical Leadership
**Reviewers:** Development Team, QA Team

## Context
The original vision for the platform was a general video marketplace. However, market analysis and strategic considerations indicated that a specialized auctions platform would provide better value proposition and market differentiation. The pivot requires significant architectural changes to support real-time bidding, auction mechanics, and associated business logic.

## Decision
Pivot the platform from a general video marketplace to a specialized video auctions marketplace with real-time bidding capabilities, focusing on US market initially with plans for expansion.

## Options Considered

1. **Option A** - Continue with General Video Marketplace
   - Pros: Less architectural changes, broader market appeal
   - Cons: High competition, less differentiation, complex monetization
   - Market Risk: High competition from established platforms

2. **Option B** - Pivot to Video Auctions Platform (Chosen)
   - Pros: Unique value proposition, clear monetization, competitive differentiation
   - Cons: Complex real-time requirements, auction-specific regulations, specialized UI/UX
   - Market Risk: New market but with clear niche

3. **Option C** - Hybrid Model (Marketplace + Auctions)
   - Pros: Flexible approach, multiple revenue streams
   - Cons: Increased complexity, diluted focus, resource constraints
   - Market Risk: Complex go-to-market strategy

## Decision Outcome
Chose Option B: Video Auctions Platform. This provides:
- Clear market differentiation
- Simplified value proposition
- Better monetization opportunities
- Reduced competition in specialized niche

## Consequences

- **Positive:**
  - Clear market positioning and value proposition
  - Simplified business model and monetization
  - Strong competitive differentiation
  - Focused development priorities

- **Negative:**
  - Significant architectural changes required
  - Real-time system complexity
  - Auction-specific compliance requirements
  - Initial market limitation to US-only

- **Neutral:**
  - Technology stack remains largely the same
  - Development team skills transfer well
  - Infrastructure needs increase modestly

## Implementation

### Phase 1: Core Auction Infrastructure (Sprint 1-2)
- Real-time bidding system using WebSockets
- Auction state management
- Timer system with Redis
- Basic bidding interface

### Phase 2: US Market Launch (Sprint 3-4)
- US-only geographic restrictions
- Basic auction creation and management
- Minimal viable bidding experience
- Integration with payment processing

### Phase 3: Enhanced Features (Sprint 5-6)
- Advanced auction types
- Bid history and analytics
- Notification systems
- Enhanced UI/UX

### Phase 4: Expansion Readiness (Sprint 7-8)
- Internationalization foundation
- Regulatory compliance framework
- Advanced analytics
- Performance optimization

## Related ADRs
- ADR-0002: Flutter + Serverpod Architecture
- ADR-0003: Database Architecture: PostgreSQL + Redis
- ADR-0004: Payment Processing: Stripe Connect Express
- ADR-0008: API Design: Serverpod RPC + REST

## References
- [Platform Vision Document](../../vision-craft-auctions.md)
- [Market Analysis](../experiments/2025-09-22-spike-auction-rules-mvp.md)
- [Technical Spike Results](../experiments/summaries/README.md)

## Status Updates
- **2025-09-22**: Accepted - Direction pivot approved
- **2025-09-23**: Implementation planning started
- **2025-10-09**: Architecture documentation update

---

*This ADR documents the fundamental strategic decision that shaped the current platform architecture.*