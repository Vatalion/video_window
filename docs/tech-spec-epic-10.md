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
- **Flutter:** Timer widgets, WebSocket integration, BLoC state management
- **Serverpod:** Scheduled tasks, Redis integration, WebSocket support
- **Database:** PostgreSQL for transaction integrity, Redis for timer state
- **Real-time:** WebSocket for live updates, Redis pub/sub for event distribution

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

1. **Implement Timer Service** - Core timer logic and Redis integration
2. **Develop State Machine** - Auction state transitions and validation
3. **Build WebSocket Infrastructure** - Real-time event broadcasting
4. **Create Flutter Timer UI** - Interactive timer components and bid interface
5. **Implement Soft-close Logic** - Extension mechanisms and bid validation
6. **Comprehensive Testing** - Timer precision, concurrency, and failure scenarios

**Dependencies:** Epic 9 (Offer Submission) for bid placement, Epic 12 (Payment Processing) for payment window trigger
**Blocks:** Epic 11 (Notifications) for auction event notifications, Epic 13 (Orders) for order creation