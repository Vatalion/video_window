# Epic 10 Context: Auction Mechanics

**Generated:** 2025-11-04  
**Epic ID:** 10  
**Epic Title:** Auction Mechanics  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Auction Duration:** 72-hour base duration with soft-close extension mechanism
- **Soft Close:** Bids in final 15min extend auction by 15min (max cumulative +24h)
- **Timer Precision:** Server authoritative time with client drift correction (NTP-like)
- **Real-time Updates:** WebSocket push for bid notifications and timer sync
- **State Machine:** Scheduled → Active → Extended → Ended → Won/Expired

### Technology Stack
- Flutter: flutter_bloc 9.1.0, web_socket_channel 2.4.0, rxdart 0.27.7, clock 1.1.1 (deterministic testing)
- Serverpod: Auction Service, WebSocket real-time, task scheduler (serverpod_cloud 2.9.2)
- Redis 7.2.4: Timer persistence, extension window tracking
- PostgreSQL 15: auctions, bids, audit_log tables
- AWS EventBridge: Scheduled timer reconciliation (cron rate 1 minute)

### Key Integration Points
- `packages/features/commerce/` - Auction timer UI and bid management
- `video_window_server/lib/src/endpoints/auction/` - Auction lifecycle endpoints
- WebSocket: Real-time bid notifications and timer sync
- Redis: Authoritative timer state with sub-second precision

### Implementation Patterns
- **Timer Management:** Server authoritative with client sync every 30s (drift correction)
- **Soft Close Logic:** Automatic 15min extension on bids within final 15min window
- **Drift Correction:** Client adjusts local timer based on server delta
- **Real-time Push:** WebSocket events for immediate bid and timer updates (<500ms latency)

### Story Dependencies
1. **10.1:** Auction timer creation and management (foundation)
2. **10.2:** Soft-close extension logic (depends on 10.1)
3. **10.3:** Auction state transitions (depends on 10.1, 10.2)
4. **10.4:** Timer precision & synchronization (depends on all above)

### Success Criteria
- Timer accuracy within ±1 second across all clients
- Soft-close triggers automatically within 1s of qualifying bid
- WebSocket latency <500ms (P95)
- State transitions logged with audit trail
- Drift correction keeps clients synchronized

**Reference:** See `docs/tech-spec-epic-10.md` for full specification
