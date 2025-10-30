# Epic 10: Auction Timer & State Management - Technical Specification

**Epic Goal:** Implement reliable 72-hour auction lifecycle with soft-close extensions, precise timer management, and comprehensive state transitions with audit logging.

**Stories:**
- 10.1: Auction Timer Creation and Management
- 10.2: Soft-Close Extension Logic
- 10.3: Auction State Transitions
- 10.4: Timer Precision and Synchronization

## Architecture Overview

### Component Mapping
- **Flutter App:** Auction Module (timer UI, bid management, real-time updates)
- **Serverpod:** Auction Service (timer logic, state management, WebSocket events)
- **Database:** Auctions table, bids table, audit_log table
- **Infrastructure:** Redis for timer persistence, WebSocket for real-time updates

### Technology Stack
- **Flutter SDK & Packages:** Flutter 3.19.6, Dart 3.5.6, `flutter_bloc` 9.1.0 for timer state orchestration, `rxdart` 0.27.7 for stream throttling, `web_socket_channel` 2.4.0 for auction updates, `intl` 0.19.0 for localized countdowns, `equatable` 2.0.5 for state comparison.
- **Client Timing & Storage:** `clock` 1.1.1 for deterministic testing, `synchronized` 3.1.0 for drift correction mutexes, `flutter_secure_storage` 9.2.1 for trace token persistence, `sentry_flutter` 8.4.0 for crash reporting.
- **Server Platform:** Serverpod 2.9.2, `serverpod_cloud` 2.9.2 task scheduler, `redis_client` 3.3.0 (Redis 7.2.4 cluster), `web_socket_serverpod` 2.9.2 for real-time push, `cronet_adapter` 1.2.0 for high precision HTTP callbacks.
- **Scheduling & Workers:** AWS EventBridge Scheduler (cron `rate(1 minute)`), Serverpod task queue, Redis streams for timer reconciliation.
- **Observability:** Datadog Agent 7.53.0 (`auctions.timer.drift_ms`, `auctions.soft_close.trigger_count`), CloudWatch metrics for scheduler execution, Kibana 8.14 dashboards (`auction-timer-*` index), PagerDuty service `Auction Timer`.
- **Security & Secrets:** HashiCorp Vault 1.15.3 for WebSocket signing keys, 1Password Connect 1.7.3 for API tokens.

### Source Tree & File Directives
```text
video_window_flutter/
  packages/
    features/
      commerce/
        lib/
          presentation/
            pages/
              auction_timer_page.dart             # Modify: render countdown + soft-close indicators (Story 10.1)
            widgets/
              auction_timer_banner.dart           # Create: countdown + latency badge (Story 10.1)
              soft_close_indicator.dart          # Create: highlight extension windows (Story 10.2)
            bloc/
              auction_timer_bloc.dart             # Modify: drift correction + WebSocket handling (Story 10.1)
              auction_soft_close_bloc.dart        # Create: extension state machine (Story 10.2)
              auction_state_bloc.dart             # Create: status transitions + UI hooks (Story 10.3)
          use_cases/
            sync_auction_timer_use_case.dart      # Create: client drift correction (Story 10.4)
            subscribe_auction_updates_use_case.dart # Modify: WebSocket subscription with trace context (Story 10.1)
    core/
      lib/
        data/
          repositories/
            auctions_repository.dart              # Modify: timer fetch + soft-close operations (Story 10.1-10.3)
          services/
            auction_timer_service.dart            # Create: reconciliation helpers (Story 10.4)
            websocket_connection_service.dart     # Modify: heartbeat + backoff tweaks (Story 10.1)
        telemetry/
          drift_monitor.dart                     # Create: aggregates drift metrics (Story 10.4)

video_window_server/
  lib/
    src/
      endpoints/
        auctions/
          auction_timer_endpoint.dart            # Modify: status fetch incl. soft-close metadata (Story 10.1)
          auction_soft_close_endpoint.dart       # Create: manual override API (Story 10.2)
      services/
        auctions/
          auction_timer_scheduler.dart           # Create: cron scheduler for timer ticks (Story 10.1)
          soft_close_service.dart                # Create: extension evaluation logic (Story 10.2)
          auction_state_service.dart             # Modify: transitions + audit logging (Story 10.3)
          timer_reconciliation_service.dart      # Create: drift detection & Redis reconciliation (Story 10.4)
      websocket/
        auction_updates_channel.dart             # Modify: push timer + state payloads (Story 10.1)
      tasks/
        auction_timer_task.dart                  # Create: background worker executing timer ticks (Story 10.1)
    test/
      endpoints/auctions/
        auction_timer_endpoint_test.dart         # Create: timer fetch scenarios
        auction_soft_close_endpoint_test.dart    # Create: extension eligibility tests
      services/auctions/
        auction_timer_scheduler_test.dart        # Create: scheduler accuracy tests
        soft_close_service_test.dart             # Create: extension rules coverage
        auction_state_service_test.dart          # Expand: transition sequencing tests
        timer_reconciliation_service_test.dart   # Create: drift correction + conflict resolution tests

infrastructure/
  terraform/
    auctions_timer.tf                            # Modify: EventBridge schedule, Redis cluster params, WebSocket scaling
    auctions_observability.tf                    # Create: Datadog monitors, CloudWatch alarms
  ci/
    auctions_checks.yaml                         # Create: timer integration + drift regression suite
```

## Data Models

### Auction Entity
```dart
class Auction {
  final String id;
  final String storyId;
  final Money startingOffer;
  final Money? currentHighBid;
  final String? currentHighBidderId;
  final Money reservePrice;
  final DateTime startsAt;
  final DateTime endsAt;
  final DateTime? softCloseUntil;
  final AuctionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum AuctionStatus {
  pending,    // Waiting for first qualified offer
  active,     // Auction running
  ended,      // Auction ended without winner
  accepted,   // Auction won, waiting for payment
  completed   // Payment completed, transaction finished
}

class Money {
  final double amount;
  final String currency;
  final int precision;
}
```

### Bid Entity
```dart
class Bid {
  final String id;
  final String auctionId;
  final String bidderId;
  final Money amount;
  final DateTime placedAt;
  final BidStatus status;
  final String? note;
}

enum BidStatus {
  active,
  outbid,
  winning,
  rejected
}
```

### Timer State Entity
```dart
class TimerState {
  final String auctionId;
  final DateTime endsAt;
  final Duration remainingTime;
  final bool isSoftClose;
  final DateTime lastUpdated;
  final int version; // For conflict resolution
}
```

## API Endpoints

### Auction Management Endpoints
```
GET /auctions/{id}
GET /auctions/{id}/timer
GET /auctions/{id}/bids
POST /auctions/{id}/bid
WebSocket /auctions/{id}/updates
```

### Timer Management Endpoints
```
GET /timers/active
POST /timers/sync
GET /timers/{id}/status
```

### Endpoint Specifications

#### Get Auction Timer Status
```dart
// Request: GET /auctions/{id}/timer

// Response
{
  "auctionId": "uuid",
  "endsAt": "2025-10-10T15:30:00Z",
  "remainingTime": "48:15:30",
  "isSoftClose": false,
  "currentHighBid": {
    "amount": 250.00,
    "currency": "USD"
  },
  "currentHighBidder": {
    "id": "uuid",
    "displayName": "John Doe"
  },
  "status": "active"
}
```

#### Place Bid
```dart
// Request: POST /auctions/{id}/bid
{
  "amount": 275.50,
  "note": "Excited to win this!"
}

// Response
{
  "bid": {
    "id": "uuid",
    "amount": 275.50,
    "status": "winning",
    "placedAt": "2025-10-08T10:15:30Z"
  },
  "auction": {
    "currentHighBid": 275.50,
    "currentHighBidder": "bidder-uuid",
    "endsAt": "2025-10-10T15:45:30Z", // Extended by soft-close
    "softCloseUntil": "2025-10-10T16:15:30Z"
  }
}
```

## Implementation Details

### Flutter Auction Module

#### Timer Management BLoC
```dart
// Auction Timer Events
abstract class AuctionTimerEvent {}
class TimerStarted extends AuctionTimerEvent {
  final String auctionId;
  final DateTime endsAt;
}
class TimerUpdated extends AuctionTimerEvent {
  final Duration remainingTime;
  final bool isSoftClose;
}
class TimerExpired extends AuctionTimerEvent {}
class BidPlaced extends AuctionTimerEvent {
  final Bid bid;
}
class AuctionStatusChanged extends AuctionTimerEvent {
  final AuctionStatus status;
}

// Auction Timer States
abstract class AuctionTimerState {}
class TimerInitial extends AuctionTimerState {}
class TimerRunning extends AuctionTimerState {
  final Duration remainingTime;
  final bool isSoftClose;
  final Money currentHighBid;
  final String currentHighBidderName;
}
class TimerEnded extends AuctionTimerState {
  final AuctionStatus finalStatus;
  final Money finalPrice;
  final String winnerName;
}
class TimerError extends AuctionTimerState {
  final String error;
}
```

### Implementation Guide
1. **Auction Timer Creation & Baseline (Story 10.1)**
   - Extend `auction_timer_scheduler.dart` to register auctions when Story 9 emits `offers.auction.started`, persisting timer metadata (start/end, soft-close rules) in Redis hash `auction:timer:{id}` with versioning.
   - Implement `auction_timer_task.dart` to poll active timers every 15 seconds, decrement remaining duration, and publish updates to `auction_updates_channel.dart` with `TimerTick` payloads.
   - Update `auction_timer_bloc.dart` to consume WebSocket ticks, reconcile with local monotonic clock (`clock.now()`), and surface drift via `auction_timer_banner.dart`.
   - Modify `auctions_repository.dart` to expose `fetchTimerStatus()` and `subscribeToTimer()` bridging HTTP fallback plus WebSocket subscription for high availability.
2. **Soft-Close Extension Logic (Story 10.2)**
   - Create `soft_close_service.dart` evaluating incoming bids: extend auction by `SOFT_CLOSE_EXTENSION_MINUTES` when bids arrive within final 15 minutes, capping at `SOFT_CLOSE_MAX_EXTENSION_MINUTES`.
   - Persist soft-close windows in Redis sorted set to avoid duplicate extensions; record audit entries in `auction_state_service.dart`.
   - Build `auction_soft_close_bloc.dart` to display active extensions and countdown UI animations via `soft_close_indicator.dart`.
   - Introduce manual override endpoint `auction_soft_close_endpoint.dart` for operations to extend/terminate soft-close windows; secure with admin RBAC.
3. **Auction State Transitions & Notifications (Story 10.3)**
   - Enhance `auction_state_service.dart` to manage state machine: `pending → active → ended|accepted → completed`, with transitions triggered by timer expiry, maker acceptance, or cancellation.
   - Emit EventBridge events (`auctions.state.changed`) and SNS notifications for maker/buyer updates.
   - Update `auction_state_bloc.dart` to respond to state events, refreshing UI and disabling bid controls accordingly.
   - Ensure `auction_timer_endpoint.dart` includes state + bid delta metadata so client can rehydrate after reconnects.
4. **Timer Precision & Synchronization (Story 10.4)**
   - Implement `timer_reconciliation_service.dart` to detect drift >250ms between Redis clock and Serverpod `DateTime.now()`; schedule corrective writes and raise Datadog events when thresholds exceeded.
   - Add `sync_auction_timer_use_case.dart` to request `POST /timers/sync` when client drift >500ms, applying `synchronized` mutex to prevent concurrent adjustments.
   - Create `drift_monitor.dart` to aggregate client drift metrics and ship to Datadog using `offers.client.validation_latency_ms` equivalent metric `auctions.client.timer_drift_ms`.
   - Expand CI workflow `auctions_checks.yaml` with integration test `auction_timer_drift_test.dart` simulating clock skew and ensuring recovery within SLA.
5. **Infrastructure & Operations**
   - Update Terraform `auctions_timer.tf` provisioning Redis with replica, enable multi-AZ, and configure EventBridge Scheduler `rate(1 minute)` for reconciliation tasks.
   - Add Datadog monitors/CloudWatch alarms in `auctions_observability.tf` for drift, task failures, and WebSocket disconnect spikes.
   - Document operational procedures in `docs/runbooks/auction-timer.md` and analytics coverage in `docs/analytics/auction-timer-dashboard.md`.

### Monitoring & Analytics
- **Datadog Metrics:** `auctions.timer.drift_ms` (p95 ≤ 250ms), `auctions.timer.tick_delay_ms` (p95 ≤ 1200ms), `auctions.soft_close.trigger_count`, `auctions.state.transition_count`, `auctions.websocket.active_connections`, `auctions.scheduler.failures`.
- **Client Metrics:** `auctions.client.timer_drift_ms`, `auctions.client.websocket_reconnects_per_hour` via Sentry breadcrumbs + Datadog custom series.
- **Segment Events:** `auction_timer_started`, `auction_soft_close_extended`, `auction_state_changed`, `auction_timer_resynced` with `submission_trace_id` and `drift_ms` properties.
- **Kibana Dashboards:** Index `auction-timer-*` monitoring soft-close decisions, scheduler logs, and reconciliation adjustments.
- **Alerting:** Slack `#eng-offers` alerts when drift p95 > 300ms (5min), PagerDuty `Auction Timer` triggered on scheduler failures or timer success rate < 99%, Opsgenie on WebSocket disconnect surge > 20% of clients.
- **Synthetic Checks:** Nightly cron verifying timer start → soft-close → completion using staging auctions; results stored in Datadog service checks.

### Environment Configuration
```yaml
auction_timer_service:
  REDIS_CLUSTER_ENDPOINT: "rediss://auction-timer.${REGION}.amazonaws.com:6379"
  TIMER_TICK_INTERVAL_SECONDS: 15
  SOFT_CLOSE_THRESHOLD_MINUTES: 15
  SOFT_CLOSE_EXTENSION_MINUTES: 15
  SOFT_CLOSE_MAX_EXTENSION_MINUTES: 1440
  TIMER_RECONCILIATION_INTERVAL_SECONDS: 60
  MAX_ALLOWED_DRIFT_MS: 250
  AUCTION_STATE_EVENT_BUS: "commerce-auctions-events@2025-09"
  WEBSOCKET_HEARTBEAT_INTERVAL_SECONDS: 20

integrations:
  DATADOG_API_KEY: "op://video-window-observability/datadog/API_KEY"
  SEGMENT_WRITE_KEY: "op://video-window-commerce/segment/AUCTIONS_WRITE_KEY"
  PAGERDUTY_SERVICE_ID: "PD_AUCTION_TIMER_SERVICE"
  SLACK_ALERT_WEBHOOK: "op://video-window-ops/slack/AUCTION_TIMER_WEBHOOK"

security:
  WEBSOCKET_SIGNING_KEY: "vault://auction-timer/keys/websocket"
  REDIS_TLS_CA_CERT: "vault://auction-timer/redis/ca_cert"

client:
  TIMER_RESYNC_THRESHOLD_MS: 500
  WEBSOCKET_BACKOFF_SECONDS: [1, 2, 4, 8]
  CLOCK_SKEW_SAMPLE_SIZE: 5
```

### Test Traceability
| Story | Acceptance Criteria | Automated Coverage |
| ----- | ------------------- | ------------------ |
| 10.1 Auction Timer Creation & Management | AC1 timer registration, AC2 WebSocket updates, AC3 drift reporting | Unit tests `auction_timer_scheduler_test.dart`, integration `auction_timer_task_test.dart`, widget tests `auction_timer_page_test.dart`, WebSocket contract test `auction_updates_channel_test.dart` |
| 10.2 Soft-Close Extension Logic | AC1 extension eligibility, AC2 cap enforcement, AC3 audit logging | Service tests `soft_close_service_test.dart`, endpoint tests `auction_soft_close_endpoint_test.dart`, repository tests `auctions_repository_test.dart` |
| 10.3 Auction State Transitions | AC1 state machine coverage, AC2 notifications, AC3 audit trail | Service tests `auction_state_service_test.dart`, EventBridge contract test `auctions_state_event_test.dart`, bloc tests `auction_state_bloc_test.dart` |
| 10.4 Timer Precision & Synchronization | AC1 drift detection, AC2 resync flow, AC3 monitoring | Service tests `timer_reconciliation_service_test.dart`, use case tests `sync_auction_timer_use_case_test.dart`, synthetic integration `auction_timer_drift_test.dart`, Datadog reporter tests `drift_monitor_test.dart` |

#### Real-time Timer Widget
```dart
class AuctionTimerWidget extends StatelessWidget {
  final String auctionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuctionTimerBloc(auctionId),
      child: BlocBuilder<AuctionTimerBloc, AuctionTimerState>(
        builder: (context, state) {
          if (state is TimerRunning) {
            return Column(
              children: [
                _buildCountdownDisplay(state.remainingTime),
                _buildSoftCloseIndicator(state.isSoftClose),
                _buildCurrentBidInfo(state.currentHighBid, state.currentHighBidderName),
                _buildBidButton(auctionId),
              ],
            );
          } else if (state is TimerEnded) {
            return _buildAuctionEnded(state);
          }
          return Container();
        },
      ),
    );
  }

  Widget _buildCountdownDisplay(Duration remainingTime) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: remainingTime.inHours < 1 ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Time Remaining',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            _formatDuration(remainingTime),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: remainingTime.inHours < 1 ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
```

#### WebSocket Integration
```dart
class AuctionWebSocketService {
  final WebSocketChannel _channel;
  final StreamController<AuctionTimerEvent> _eventController;

  AuctionWebSocketService(String auctionId)
    : _channel = WebSocketChannel.connect(
        Uri.parse('wss://api.craftmarketplace.com/auctions/$auctionId/updates')
      ),
      _eventController = StreamController.broadcast();

  void connect() {
    _channel.stream.listen(
      (data) {
        final event = _parseWebSocketEvent(data);
        _eventController.add(event);
      },
      onError: (error) => _eventController.add(TimerError(error.toString())),
      onDone: () => _eventController.add(TimerExpired()),
    );
  }

  Stream<AuctionTimerEvent> get events => _eventController.stream;

  void dispose() {
    _channel.sink.close();
    _eventController.close();
  }
}
```

### Serverpod Auction Service

#### Auction Timer Service
```dart
class AuctionTimerService {
  final RedisClient _redis;
  final AuctionRepository _auctionRepository;
  final BidRepository _bidRepository;
  final WebSocketManager _webSocketManager;

  // Core timer management
  Future<void> startAuctionTimer(String auctionId, Duration duration) async {
    final auction = await _auctionRepository.findById(auctionId);
    if (auction == null || auction.status != AuctionStatus.pending) {
      throw AuctionException('Invalid auction state for timer start');
    }

    final endsAt = DateTime.now().add(duration);

    // Update auction in database
    await _auctionRepository.updateStatus(
      auctionId,
      AuctionStatus.active,
      endsAt: endsAt
    );

    // Store timer state in Redis with expiration
    await _storeTimerState(auctionId, endsAt, false);

    // Schedule background task for timer expiration
    await _scheduleExpirationTask(auctionId, endsAt);

    // Broadcast timer start event
    await _broadcastTimerUpdate(auctionId, endsAt, false);

    // Log audit event
    await _logAuctionEvent(auctionId, 'timer_started', {
      'duration': duration.inSeconds,
      'endsAt': endsAt.toIso8601String(),
    });
  }

  // Soft-close extension logic
  Future<void> handleBidPlaced(String auctionId, Bid bid) async {
    final auction = await _auctionRepository.findById(auctionId);
    if (auction == null || auction.status != AuctionStatus.active) {
      throw AuctionException('Auction not active');
    }

    final timerState = await _getTimerState(auctionId);
    final now = DateTime.now();

    // Check if bid is within soft-close period
    if (timerState.isSoftClose && now.isBefore(timerState.endsAt)) {
      // Extend soft-close period
      final newSoftCloseUntil = timerState.endsAt.add(Duration(minutes: 15));

      // Update Redis timer state
      await _updateTimerState(
        auctionId,
        timerState.endsAt,
        true, // isSoftClose
        newSoftCloseUntil
      );

      // Reschedule expiration task
      await _scheduleExpirationTask(auctionId, newSoftCloseUntil);

      // Broadcast extension event
      await _broadcastSoftCloseExtension(auctionId, newSoftCloseUntil);

      // Log extension event
      await _logAuctionEvent(auctionId, 'soft_close_extended', {
        'extendedUntil': newSoftCloseUntil.toIso8601String(),
        'triggeringBid': bid.id,
      });
    }

    // Broadcast bid update
    await _broadcastBidUpdate(auctionId, bid);
  }

  // Timer expiration handling
  Future<void> handleTimerExpiration(String auctionId) async {
    final auction = await _auctionRepository.findById(auctionId);
    if (auction == null) return;

    final timerState = await _getTimerState(auctionId);
    final now = DateTime.now();

    if (now.isAfter(timerState.endsAt)) {
      // Check if there's a winning bid
      final winningBid = await _bidRepository.getWinningBid(auctionId);

      if (winningBid != null) {
        // Auction won
        await _auctionRepository.updateStatus(
          auctionId,
          AuctionStatus.accepted,
          winningBidId: winningBid.id
        );

        // Start 24-hour payment window
        await _startPaymentWindow(auctionId, winningBid);

        // Broadcast auction won event
        await _broadcastAuctionWon(auctionId, winningBid);

        // Log auction completion
        await _logAuctionEvent(auctionId, 'auction_won', {
          'winningBidId': winningBid.id,
          'finalPrice': winningBid.amount.amount,
          'winnerId': winningBid.bidderId,
        });
      } else {
        // Auction ended without winner
        await _auctionRepository.updateStatus(auctionId, AuctionStatus.ended);

        // Broadcast auction ended event
        await _broadcastAuctionEnded(auctionId);

        // Log auction ended without winner
        await _logAuctionEvent(auctionId, 'auction_ended_no_winner', {
          'finalPrice': auction.startingOffer.amount,
        });
      }

      // Clean up timer state
      await _cleanupTimerState(auctionId);
    }
  }

  // Redis timer state management
  Future<void> _storeTimerState(String auctionId, DateTime endsAt, bool isSoftClose) async {
    final timerState = {
      'auctionId': auctionId,
      'endsAt': endsAt.millisecondsSinceEpoch,
      'isSoftClose': isSoftClose,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      'version': 1,
    };

    await _redis.hset('auction_timers', auctionId, jsonEncode(timerState));
    await _redis.expire('auction_timers', endsAt.difference(DateTime.now()).inSeconds + 3600);
  }

  Future<TimerState> _getTimerState(String auctionId) async {
    final timerData = await _redis.hget('auction_timers', auctionId);
    if (timerData == null) {
      throw AuctionException('Timer state not found');
    }

    final json = jsonDecode(timerData);
    return TimerState(
      auctionId: json['auctionId'],
      endsAt: DateTime.fromMillisecondsSinceEpoch(json['endsAt']),
      remainingTime: DateTime.fromMillisecondsSinceEpoch(json['endsAt']).difference(DateTime.now()),
      isSoftClose: json['isSoftClose'],
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated']),
      version: json['version'],
    );
  }
}
```

#### Auction State Machine
```dart
class AuctionStateMachine {
  static final Map<AuctionStatus, Set<AuctionStatus>> _validTransitions = {
    AuctionStatus.pending: {AuctionStatus.active},
    AuctionStatus.active: {AuctionStatus.ended, AuctionStatus.accepted},
    AuctionStatus.accepted: {AuctionStatus.completed, AuctionStatus.ended},
    AuctionStatus.ended: {AuctionStatus.completed},
    AuctionStatus.completed: {}, // Terminal state
  };

  static bool canTransition(AuctionStatus from, AuctionStatus to) {
    return _validTransitions[from]?.contains(to) ?? false;
  }

  static Future<void> transition(
    String auctionId,
    AuctionStatus newStatus,
    {String? reason, Map<String, dynamic>? metadata}
  ) async {
    final auction = await _auctionRepository.findById(auctionId);
    if (auction == null) {
      throw AuctionException('Auction not found');
    }

    if (!canTransition(auction.status, newStatus)) {
      throw AuctionException(
        'Invalid transition from ${auction.status} to $newStatus'
      );
    }

    // Update auction status
    await _auctionRepository.updateStatus(auctionId, newStatus);

    // Log state transition
    await _logAuctionEvent(auctionId, 'status_changed', {
      'fromStatus': auction.status.toString(),
      'toStatus': newStatus.toString(),
      'reason': reason,
      'metadata': metadata,
    });

    // Trigger appropriate actions based on new status
    await _handleStatusChange(auctionId, newStatus, auction);
  }

  static Future<void> _handleStatusChange(
    String auctionId,
    AuctionStatus newStatus,
    Auction auction
  ) async {
    switch (newStatus) {
      case AuctionStatus.active:
        await _startAuctionTimers(auctionId);
        break;
      case AuctionStatus.accepted:
        await _notifyWinner(auctionId);
        await _startPaymentWindow(auctionId);
        break;
      case AuctionStatus.ended:
        await _notifyParticipants(auctionId, 'auction_ended');
        break;
      case AuctionStatus.completed:
        await _finalizeTransaction(auctionId);
        break;
    }
  }
}
```

## WebSocket Real-time Updates

### Auction Event Broadcasting
```dart
class AuctionWebSocketManager {
  final Map<String, Set<WebSocketChannel>> _subscriptions = {};

  Future<void> subscribe(String auctionId, WebSocketChannel channel) {
    _subscriptions.putIfAbsent(auctionId, () => <WebSocketChannel>{});
    _subscriptions[auctionId]!.add(channel);
  }

  Future<void> unsubscribe(String auctionId, WebSocketChannel channel) {
    _subscriptions[auctionId]?.remove(channel);
    if (_subscriptions[auctionId]?.isEmpty == true) {
      _subscriptions.remove(auctionId);
    }
  }

  Future<void> broadcastTimerUpdate(String auctionId, TimerState timerState) async {
    final event = {
      'type': 'timer_update',
      'auctionId': auctionId,
      'data': {
        'remainingTime': timerState.remainingTime.inSeconds,
        'isSoftClose': timerState.isSoftClose,
        'endsAt': timerState.endsAt.toIso8601String(),
      },
    };

    await _broadcastToSubscribers(auctionId, event);
  }

  Future<void> broadcastBidUpdate(String auctionId, Bid bid) async {
    final event = {
      'type': 'bid_update',
      'auctionId': auctionId,
      'data': {
        'bidId': bid.id,
        'amount': bid.amount.amount,
        'currency': bid.amount.currency,
        'bidderName': bid.bidderDisplayName,
        'placedAt': bid.placedAt.toIso8601String(),
      },
    };

    await _broadcastToSubscribers(auctionId, event);
  }

  private Future<void> _broadcastToSubscribers(String auctionId, Map<String, dynamic> event) async {
    final channels = _subscriptions[auctionId] ?? <WebSocketChannel>{};
    final message = jsonEncode(event);

    for (final channel in channels) {
      try {
        channel.sink.add(message);
      } catch (e) {
        // Remove dead channels
        await unsubscribe(auctionId, channel);
      }
    }
  }
}
```

## Database Schema

### Auctions Table
```sql
CREATE TABLE auctions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES stories(id),
  starting_offer DECIMAL(10,2) NOT NULL,
  current_high_bid DECIMAL(10,2),
  current_high_bidder_id UUID REFERENCES users(id),
  reserve_price DECIMAL(10,2),
  starts_at TIMESTAMP WITH TIME ZONE NOT NULL,
  ends_at TIMESTAMP WITH TIME ZONE NOT NULL,
  soft_close_until TIMESTAMP WITH TIME ZONE,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  winning_bid_id UUID REFERENCES bids(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_auctions_status ON auctions(status);
CREATE INDEX idx_auctions_ends_at ON auctions(ends_at);
CREATE INDEX idx_auctions_story_id ON auctions(story_id);
```

### Bids Table
```sql
CREATE TABLE bids (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id UUID NOT NULL REFERENCES auctions(id),
  bidder_id UUID NOT NULL REFERENCES users(id),
  amount DECIMAL(10,2) NOT NULL,
  note TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  placed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_bids_auction_id ON bids(auction_id);
CREATE INDEX idx_bids_bidder_id ON bids(bidder_id);
CREATE INDEX idx_bids_amount ON bids(amount) WHERE status = 'active';
```

### Audit Log Table
```sql
CREATE TABLE auction_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id UUID NOT NULL REFERENCES auctions(id),
  event_type VARCHAR(50) NOT NULL,
  event_data JSONB,
  user_id UUID REFERENCES users(id),
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_audit_log_auction_id ON auction_audit_log(auction_id);
CREATE INDEX idx_audit_log_created_at ON auction_audit_log(created_at);
```

## Testing Strategy

### Unit Tests
- **Timer Logic:** Test duration calculations, soft-close extensions, expiration handling
- **State Machine:** Test valid/invalid state transitions, error handling
- **Bid Validation:** Test minimum bid rules, bid amount validation
- **WebSocket Events:** Test event broadcasting, subscription management

### Integration Tests
- **Auction Lifecycle:** End-to-end auction from start to completion
- **Real-time Updates:** WebSocket connectivity and event delivery
- **Timer Persistence:** Redis timer state storage and recovery
- **Concurrent Bidding:** Multiple simultaneous bids, race conditions

### Performance Tests
- **Timer Precision:** Sub-second accuracy under load
- **WebSocket Scaling:** 1000+ concurrent connections
- **Redis Performance:** Timer state operations at scale
- **Database Performance:** High-frequency bid updates

## Error Handling

### Timer Errors
```dart
abstract class TimerException implements Exception {
  final String message;
  final TimerErrorCode code;
}

class TimerAlreadyStartedException extends TimerException { }
class TimerNotFoundException extends TimerException { }
class TimerExpiredException extends TimerException { }
class TimerSyncException extends TimerException { }
```

### Bid Validation Errors
```dart
abstract class BidException implements Exception {
  final String message;
  final BidErrorCode code;
}

class InsufficientBidException extends BidException { }
class AuctionNotActiveException extends BidException { }
class BidderBlacklistedException extends BidException { }
class RateLimitExceededException extends BidException { }
```

## Performance Considerations

### Timer Precision
- Use server time as source of truth
- Synchronize client timers every 30 seconds
- Implement drift correction for client-side timers
- Use Redis for reliable timer state persistence

### Real-time Updates
- WebSocket connection pooling
- Event batching for high-frequency updates
- Connection recovery and state synchronization
- Fallback to polling for unreliable connections

### Database Optimization
- Indexes on frequently queried columns (status, ends_at, auction_id)
- Partitioning for large audit log tables
- Read replicas for auction browsing
- Connection pooling for high concurrency

## Monitoring and Analytics

### Key Metrics
- Auction completion rate
- Average auction duration
- Bid frequency and patterns
- Timer accuracy and drift
- WebSocket connection success rate
- Soft-close extension frequency

### Alerting
- Timer failures or missed expirations
- WebSocket connection issues
- Database performance degradation
- Unusual bidding patterns (potential fraud)

## Success Criteria

### Functional Requirements
- ✅ Accurate 72-hour timer execution with 1-second precision
- ✅ Soft-close extensions triggered by last-minute bids
- ✅ Complete auction state management with audit logging
- ✅ Real-time updates delivered to all participants
- ✅ Robust error handling and recovery mechanisms

### Non-Functional Requirements
- ✅ Timer accuracy within ±5 seconds under normal load
- ✅ Support for 100+ concurrent auctions
- ✅ WebSocket latency < 100ms for timer updates
- ✅ 99.9% uptime for timer service
- ✅ Complete audit trail for all auction events

## Next Steps


## Change Log
| Date       | Version | Description                                                                                           | Author            |
| ---------- | ------- | ----------------------------------------------------------------------------------------------------- | ----------------- |
| 2025-10-29 | v0.5    | Promoted to definitive: pinned stack, source directives, implementation guide, monitoring, environment, traceability | GitHub Copilot AI |

---
*This technical specification defines the definitive implementation plan for Auction Timer & State Management and must be kept in sync with related stories, workflows, and operational playbooks.*
1. **Implement Timer Service** - Core timer logic and Redis integration
2. **Develop State Machine** - Auction state transitions and validation
3. **Build WebSocket Infrastructure** - Real-time event broadcasting
4. **Create Flutter Timer UI** - Interactive timer components and bid interface
5. **Implement Soft-close Logic** - Extension mechanisms and bid validation
6. **Comprehensive Testing** - Timer precision, concurrency, and failure scenarios

**Dependencies:** Epic 9 (Offer Submission) for bid placement, Epic 12 (Payment Processing) for payment window trigger
**Blocks:** Epic 11 (Notifications) for auction event notifications, Epic 13 (Orders) for order creation