# Serverpod Integration Guide

## Overview

This comprehensive guide covers the integration of Serverpod 2.9.x with the Craft Video Marketplace Flutter application, including setup, configuration, deployment, and best practices.

## Serverpod Architecture Overview

### Project Structure
```
video_window/
├── packages/
│   ├── mobile_client/          # Flutter app
│   ├── serverpod_backend/      # Serverpod backend
│   ├── shared_models/          # Shared data models
│   └── design_system/          # UI components
├── tools/
│   └── scripts/                # Development tools
└── docs/                       # Documentation
```

### Serverpod Modules
- **Identity**: User authentication, sessions, roles
- **Story**: Content management, video processing
- **Marketplace**: Listings, offers, auctions
- **Payment**: Stripe integration, transactions
- **Notifications**: Real-time messaging
- **Analytics**: Event tracking, metrics

## Installation and Setup

### 1. Prerequisites

```bash
# Required versions
Flutter >= 3.35.1
Dart >= 3.8.0
PostgreSQL >= 15.0
Redis >= 7.0

# Development tools
Docker & Docker Compose
PostgreSQL client
Redis CLI
```

### 2. Serverpod Installation

```bash
# Navigate to backend directory
cd video_window/packages/serverpod_backend

# Install Serverpod CLI
dart pub global activate serverpod_cli

# Generate server code
serverpod generate

# Install dependencies
dart pub get
```

### 3. Database Setup

#### PostgreSQL Configuration

```yaml
# config/config.yaml
database:
  host: localhost
  port: 5432
  name: craft_marketplace_dev
  user: postgres
  password: your_password_here

  # Connection pool settings
  minConnections: 5
  maxConnections: 20
  connectionTimeout: 30000

  # SSL settings
  sslMode: require
```

#### Database Migration

```bash
# Run migrations
dart run bin/main.dart --migrate

# Create sample data (development only)
dart run bin/main.dart --create-sample-data
```

#### Redis Configuration

```yaml
# config/config.yaml
redis:
  host: localhost
  port: 6379
  password: null  # Set if using password

  # Key prefix
  keyPrefix: craft_marketplace:

  # Connection settings
  maxConnections: 10
  connectionTimeout: 5000
```

## Core Configuration

### 1. Server Configuration

```dart
// config/serverpod.dart
import 'package:serverpod/serverpod.dart';

class CraftMarketplaceServer extends Serverpod {
  @override
  Future<void> initialize() async {
    // Initialize modules
    await _initializeModules();

    // Set up authentication
    await _setupAuthentication();

    // Configure middleware
    await _configureMiddleware();

    // Initialize background jobs
    await _initializeBackgroundJobs();
  }

  Future<void> _initializeModules() async {
    // Initialize each module
    await IdentityModule().initialize(this);
    await StoryModule().initialize(this);
    await MarketplaceModule().initialize(this);
    await PaymentModule().initialize(this);
    await NotificationModule().initialize(this);
  }

  Future<void> _setupAuthentication() async {
    // Configure authentication
    this.endpoints.add(AuthEndpoint());

    // Set up session handling
    this.sessionManager = CraftSessionManager();
  }

  Future<void> _configureMiddleware() async {
    // Add logging middleware
    this.addMiddleware(LoggingMiddleware());

    // Add performance monitoring
    this.addMiddleware(PerformanceMiddleware());

    // Add rate limiting
    this.addMiddleware(RateLimitMiddleware());

    // Add security headers
    this.addMiddleware(SecurityMiddleware());
  }

  Future<void> _initializeBackgroundJobs() async {
    // Schedule background tasks
    this.jobs.add(AuctionTimerJob());
    this.jobs.add(PaymentReminderJob());
    this.jobs.add(ContentProcessingJob());
    this.jobs.add(AnalyticsAggregationJob());
  }
}
```

### 2. Environment Configuration

```yaml
# config/development.yaml
environment: development
debugMode: true
logLevel: debug

# Database settings
database:
  host: localhost
  port: 5432
  name: craft_marketplace_dev

# Redis settings
redis:
  host: localhost
  port: 6379

# External services
services:
  stripe:
    apiKey: sk_test_...
    webhookSecret: whsec_...

  cloud_storage:
    provider: aws_s3
    bucket: craft-marketplace-dev
    region: us-east-1
    accessKey: YOUR_ACCESS_KEY
    secretKey: YOUR_SECRET_KEY

  email:
    provider: sendgrid
    apiKey: SG.api_key

  push_notifications:
    provider: firebase
    serverKey: YOUR_FIREBASE_SERVER_KEY
```

```yaml
# config/production.yaml
environment: production
debugMode: false
logLevel: info

# Production database
database:
  host: prod-db.craftmarketplace.com
  port: 5432
  name: craft_marketplace_prod
  sslMode: require

# Production Redis
redis:
  host: prod-redis.craftmarketplace.com
  port: 6379
  password: ${REDIS_PASSWORD}

# Production services
services:
  stripe:
    apiKey: ${STRIPE_SECRET_KEY}
    webhookSecret: ${STRIPE_WEBHOOK_SECRET}

  cloud_storage:
    provider: aws_s3
    bucket: craft-marketplace-prod
    region: us-east-1
    accessKey: ${AWS_ACCESS_KEY}
    secretKey: ${AWS_SECRET_KEY}
```

## Data Models and Serialization

### 1. Shared Models

```dart
// packages/shared_models/lib/src/models/user.dart
import 'package:serverpod/serverpod.dart';

class User extends SerializableModel {
  int? id;
  String email;
  String username;
  String? displayName;
  String? avatarUrl;
  UserRole role;
  UserStatus status;
  DateTime createdAt;
  DateTime updatedAt;

  User({
    required this.email,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.role = UserRole.viewer,
    this.status = UserStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      status: UserStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

enum UserRole {
  viewer,
  maker,
  admin,
}

enum UserStatus {
  active,
  suspended,
  pending_verification,
}
```

### 2. Database Tables

```dart
// packages/serverpod_backend/src/generated/tables.dart
import 'package:serverpod/serverpod.dart';

class UserTable extends Table {
  int id = integer().autoIncrement()();
  String email = text().unique()();
  String username = text().unique()();
  String? displayName = text()();
  String? avatarUrl = text()();
  String role = text().withDefault(constant('viewer'))();
  String status = text().withDefault(constant('active'))();
  DateTime createdAt = timestamp().withDefault(currentTimestamp)();
  DateTime updatedAt = timestamp().withDefault(currentTimestamp)();

  // Indexes
  Index get emailIndex => index([email]);
  Index get usernameIndex => index([username]);
  Index get roleIndex => index([role]);
  Index get statusIndex => index([status]);
  Index get createdAtIndex => index([createdAt]);
}

class StoryTable extends Table {
  int id = integer().autoIncrement()();
  int makerId = integer().reference(UserTable, #id)();
  String title = text()();
  String description = text()();
  String primaryVideoUrl = text()();
  List<String> videoUrls = textList()();
  decimal price = decimal()();
  int minimumOffer = integer()();
  bool isAuctionActive = boolean().withDefault(constant(false))();
  DateTime auctionEndTime = timestamp().nullable()();
  DateTime createdAt = timestamp().withDefault(currentTimestamp)();
  DateTime updatedAt = timestamp().withDefault(currentTimestamp)();

  // Indexes
  Index get makerIdIndex => index([makerId]);
  Index get auctionActiveIndex => index([isAuctionActive]);
  Index get createdAtIndex => index([createdAt]);
  Index get auctionEndTimeIndex => index([auctionEndTime]);
}
```

## API Endpoints

### 1. Authentication Endpoint

```dart
// packages/serverpod_backend/src/endpoints/auth_endpoint.dart
import 'package:serverpod/serverpod.dart';

class AuthEndpoint extends Endpoint {
  Future<UserResponse> signInWithEmail(
    Session session,
    String email,
    String oneTimeCode,
  ) async {
    // Validate OTP
    final isValidOtp = await _validateOneTimeCode(email, oneTimeCode);
    if (!isValidOtp) {
      throw ArgumentError('Invalid or expired verification code');
    }

    // Find or create user
    var user = await User.findSingleRow(
      session,
      where: (t) => t.email.equals(email),
    );

    if (user == null) {
      user = await _createUser(session, email);
    }

    // Create session
    final sessionToken = await _createSessionToken(user);

    // Log successful sign in
    session.log('User signed in: ${user.email}', level: LogLevel.info);

    return UserResponse(
      user: user,
      sessionToken: sessionToken,
      expiresIn: Duration(minutes: 15),
    );
  }

  Future<UserResponse> signInWithSocial(
    Session session,
    SocialSignInRequest request,
  ) async {
    // Verify social token
    final socialUser = await _verifySocialToken(request);
    if (socialUser == null) {
      throw ArgumentError('Invalid social authentication');
    }

    // Find or create user
    var user = await User.findSingleRow(
      session,
      where: (t) => t.email.equals(socialUser.email),
    );

    if (user == null) {
      user = await _createUserFromSocial(session, socialUser);
    }

    // Create session
    final sessionToken = await _createSessionToken(user);

    return UserResponse(
      user: user,
      sessionToken: sessionToken,
      expiresIn: Duration(minutes: 15),
    );
  }

  Future<void> signOut(Session session) async {
    final token = session.authenticatedToken;
    if (token != null) {
      await _invalidateSession(token);
    }
  }

  Future<UserResponse> refreshToken(
    Session session,
    String refreshToken,
  ) async {
    // Validate refresh token
    final tokenData = await _validateRefreshToken(refreshToken);
    if (tokenData == null) {
      throw ArgumentError('Invalid refresh token');
    }

    // Create new session token
    final newSessionToken = await _createSessionToken(tokenData.user);

    return UserResponse(
      user: tokenData.user,
      sessionToken: newSessionToken,
      expiresIn: Duration(minutes: 15),
    );
  }

  // Helper methods
  Future<User> _createUser(Session session, String email) async {
    final user = User(
      email: email,
      username: _generateUsername(email),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await User.insert(session, user);
    return user;
  }

  String _generateUsername(String email) {
    return email.split('@')[0] + '_${DateTime.now().millisecondsSinceEpoch}';
  }
}
```

### 2. Story Endpoint

```dart
// packages/serverpod_backend/src/endpoints/story_endpoint.dart
import 'package:serverpod/serverpod.dart';

class StoryEndpoint extends Endpoint {
  Future<StoryListResponse> getStories(
    Session session,
    StoryListRequest request,
  ) async {
    final query = Story.find(
      session,
      where: (t) => t.isAuctionActive.equals(false),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: request.limit,
      offset: request.offset,
    );

    final stories = await query.toList();
    final totalCount = await Story.count(session);

    return StoryListResponse(
      stories: stories,
      totalCount: totalCount,
      hasMore: (request.offset + stories.length) < totalCount,
    );
  }

  Future<StoryDetailResponse> getStory(
    Session session,
    int storyId,
  ) async {
    final story = await Story.findById(session, storyId);
    if (story == null) {
      throw ArgumentValueError('Story not found');
    }

    // Increment view count
    await _incrementViewCount(session, storyId);

    // Get maker information
    final maker = await User.findById(session, story.makerId);

    return StoryDetailResponse(
      story: story,
      maker: maker,
      viewCount: await _getViewCount(session, storyId),
    );
  }

  Future<StoryResponse> createStory(
    Session session,
    CreateStoryRequest request,
  ) async {
    // Validate user is a maker
    final user = await _getCurrentUser(session);
    if (user.role != UserRole.maker) {
      throw ArgumentError('Only makers can create stories');
    }

    // Process uploaded videos
    final processedVideos = await _processVideos(request.videoUrls);

    // Create story
    final story = Story(
      makerId: user.id!,
      title: request.title,
      description: request.description,
      primaryVideoUrl: processedVideos.first,
      videoUrls: processedVideos,
      price: request.price,
      minimumOffer: request.minimumOffer,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await Story.insert(session, story);

    // Trigger video processing pipeline
    await _enqueueVideoProcessing(story);

    session.log('Story created: ${story.id}', level: LogLevel.info);

    return StoryResponse(story: story);
  }

  Future<void> deleteStory(
    Session session,
    int storyId,
  ) async {
    final user = await _getCurrentUser(session);
    final story = await Story.findById(session, storyId);

    if (story == null || story.makerId != user.id) {
      throw ArgumentError('Story not found or access denied');
    }

    // Check if story has active auction
    if (story.isAuctionActive) {
      throw ArgumentError('Cannot delete story with active auction');
    }

    await Story.delete(session, story);

    // Clean up video files
    await _cleanupVideoFiles(story.videoUrls);

    session.log('Story deleted: $storyId', level: LogLevel.info);
  }

  // Helper methods
  Future<List<String>> _processVideos(List<String> videoUrls) async {
    final processedUrls = <String>[];

    for (final url in videoUrls) {
      // Transcode to HLS
      final hlsUrl = await _transcodeToHls(url);

      // Add watermark
      final watermarkedUrl = await _addWatermark(hlsUrl);

      processedUrls.add(watermarkedUrl);
    }

    return processedUrls;
  }

  Future<String> _transcodeToHls(String inputUrl) async {
    // Implementation would use FFmpeg or similar service
    return 'https://cdn.craftmarketplace.com/hls/${_generateId()}.m3u8';
  }

  Future<String> _addWatermark(String hlsUrl) async {
    // Implementation would overlay watermark on video segments
    return hls; // For now, return same URL
  }
}
```

### 3. Marketplace Endpoint

```dart
// packages/serverpod_backend/src/endpoints/marketplace_endpoint.dart
import 'package:serverpod/serverpod.dart';

class MarketplaceEndpoint extends Endpoint {
  Future<OfferResponse> submitOffer(
    Session session,
    SubmitOfferRequest request,
  ) async {
    final user = await _getCurrentUser(session);
    final story = await Story.findById(session, request.storyId);

    if (story == null) {
      throw ArgumentError('Story not found');
    }

    // Validate offer amount
    if (request.amount < story.minimumOffer) {
      throw ArgumentError('Offer amount below minimum');
    }

    // Check if user already has active offer
    final existingOffer = await Offer.findSingleRow(
      session,
      where: (t) => t.storyId.equals(request.storyId) &
               t.userId.equals(user.id!) &
               t.isActive.equals(true),
    );

    if (existingOffer != null) {
      throw ArgumentError('You already have an active offer for this story');
    }

    // Create offer
    final offer = Offer(
      storyId: request.storyId,
      userId: user.id!,
      amount: request.amount,
      status: OfferStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await Offer.insert(session, offer);

    // Check if this should trigger auction
    await _checkAndStartAuction(session, story);

    // Send notification to maker
    await _notifyMaker(session, story.makerId, offer);

    return OfferResponse(offer: offer);
  }

  Future<BidResponse> placeBid(
    Session session,
    PlaceBidRequest request,
  ) async {
    final user = await _getCurrentUser(session);
    final story = await Story.findById(session, request.storyId);

    if (story == null || !story.isAuctionActive) {
      throw ArgumentError('Auction not found or not active');
    }

    // Validate bid amount
    final currentHighestBid = await _getHighestBid(session, request.storyId);
    final minimumBid = currentHighestBid?.amount ?? story.minimumOffer;
    final requiredBid = (minimumBid * 1.01).ceil() + 5;

    if (request.amount < requiredBid) {
      throw ArgumentError('Bid amount too low. Minimum: $requiredBid');
    }

    // Create bid
    final bid = Bid(
      storyId: request.storyId,
      userId: user.id!,
      amount: request.amount,
      status: BidStatus.active,
      createdAt: DateTime.now(),
    );

    await Bid.insert(session, bid);

    // Update auction end time if within soft close period
    await _updateAuctionEndTime(session, story);

    // Notify outbid users
    await _notifyOutbidUsers(session, story, bid);

    return BidResponse(bid: bid);
  }

  Future<void> acceptBid(
    Session session,
    int bidId,
  ) async {
    final user = await _getCurrentUser(session);
    final bid = await Bid.findById(session, bidId);

    if (bid == null) {
      throw ArgumentError('Bid not found');
    }

    final story = await Story.findById(session, bid.storyId);
    if (story == null || story.makerId != user.id) {
      throw ArgumentError('Access denied');
    }

    // Start payment window
    final paymentWindow = PaymentWindow(
      storyId: story.id!,
      winningBidId: bid.id!,
      expiresAt: DateTime.now().add(Duration(hours: 24)),
      status: PaymentWindowStatus.active,
      createdAt: DateTime.now(),
    );

    await PaymentWindow.insert(session, paymentWindow);

    // Update story status
    story.isAuctionActive = false;
    story.updatedAt = DateTime.now();
    await Story.update(session, story);

    // Create Stripe checkout session
    final checkoutSession = await _createStripeCheckoutSession(bid);

    // Notify winner
    await _notifyWinner(session, bid.userId, checkoutSession);

    session.log('Bid accepted: $bidId', level: LogLevel.info);
  }

  // Helper methods
  Future<void> _checkAndStartAuction(Session session, Story story) async {
    final activeOffers = await Offer.count(
      session,
      where: (t) => t.storyId.equals(story.id!) &
               t.isActive.equals(true),
    );

    if (activeOffers >= 1 && !story.isAuctionActive) {
      // Start auction
      story.isAuctionActive = true;
      story.auctionEndTime = DateTime.now().add(Duration(hours: 72));
      story.updatedAt = DateTime.now();
      await Story.update(session, story);

      // Schedule auction end job
      await _scheduleAuctionEnd(session, story.id!);
    }
  }

  Future<String> _createStripeCheckoutSession(Bid bid) async {
    // Implementation would create Stripe checkout session
    return 'https://checkout.stripe.com/pay/...';
  }
}
```

## Background Jobs and Scheduled Tasks

### 1. Auction Timer Job

```dart
// packages/serverpod_backend/src/jobs/auction_timer_job.dart
import 'package:serverpod/serverpod.dart';

class AuctionTimerJob extends ScheduledJob {
  @override
  String get name => 'auction_timer';

  @override
  Duration get defaultInterval => Duration(minutes: 1);

  @override
  Future<void> run(Session session) async {
    final now = DateTime.now();

    // Find expired auctions
    final expiredAuctions = await Story.find(
      session,
      where: (t) => t.isAuctionActive.equals(true) &
               t.auctionEndTime.lessThan(now),
    );

    for (final story in expiredAuctions) {
      await _endAuction(session, story);
    }
  }

  Future<void> _endAuction(Session session, Story story) async {
    final highestBid = await Bid.findSingleRow(
      session,
      where: (t) => t.storyId.equals(story.id!) &
               t.status.equals(BidStatus.active),
      orderBy: (t) => t.amount,
      orderDescending: true,
    );

    if (highestBid != null) {
      // Winner found - start payment window
      await _startPaymentWindow(session, story, highestBid);
    } else {
      // No bids - cancel auction
      await _cancelAuction(session, story);
    }

    session.log('Auction ended: ${story.id}', level: LogLevel.info);
  }

  Future<void> _startPaymentWindow(Session session, Story story, Bid bid) async {
    final paymentWindow = PaymentWindow(
      storyId: story.id!,
      winningBidId: bid.id!,
      expiresAt: DateTime.now().add(Duration(hours: 24)),
      status: PaymentWindowStatus.active,
      createdAt: DateTime.now(),
    );

    await PaymentWindow.insert(session, paymentWindow);

    // Update story
    story.isAuctionActive = false;
    story.updatedAt = DateTime.now();
    await Story.update(session, story);
  }

  Future<void> _cancelAuction(Session session, Story story) async {
    story.isAuctionActive = false;
    story.updatedAt = DateTime.now();
    await Story.update(session, story);

    // Notify offerers that auction ended without winner
    await _notifyAuctionCanceled(session, story);
  }
}
```

### 2. Payment Reminder Job

```dart
// packages/serverpod_backend/src/jobs/payment_reminder_job.dart
import 'package:serverpod/serverpod.dart';

class PaymentReminderJob extends ScheduledJob {
  @override
  String get name => 'payment_reminder';

  @override
  Duration get defaultInterval => Duration(hours: 1);

  @override
  Future<void> run(Session session) async {
    final now = DateTime.now();
    final warnings = [Duration(hours: 2), Duration(hours: 6), Duration(hours: 12)];

    for (final warning in warnings) {
      final reminderTime = now.add(warning);

      final paymentWindows = await PaymentWindow.find(
        session,
        where: (t) => t.status.equals(PaymentWindowStatus.active) &
                 t.expiresAt.lessThan(reminderTime),
      );

      for (final window in paymentWindows) {
        await _sendPaymentReminder(session, window, warning);
      }
    }
  }

  Future<void> _sendPaymentReminder(
    Session session,
    PaymentWindow window,
    Duration timeUntilExpiry,
  ) async {
    final bid = await Bid.findById(session, window.winningBidId);
    if (bid == null) return;

    // Send push notification
    await NotificationService.sendPushNotification(
      userId: bid.userId,
      title: 'Payment Reminder',
      body: 'Complete your payment within ${timeUntilExpiry.inHours} hours',
      data: {'type': 'payment_reminder', 'bidId': bid.id},
    );

    // Send email reminder
    await EmailService.sendPaymentReminder(
      userEmail: bid.userEmail,
      bidId: bid.id,
      timeUntilExpiry: timeUntilExpiry,
    );
  }
}
```

## Testing

### 1. Unit Tests

```dart
// test/unit/endpoints/auth_endpoint_test.dart
import 'package:test/test.dart';
import 'package:serverpod_test/serverpod_test.dart';
import '../src/endpoints/auth_endpoint.dart';

void main() {
  group('AuthEndpoint Tests', () {
    late ServerpodTestEndpoint endpoint;
    late Session session;

    setUp(() async {
      endpoint = AuthEndpoint();
      session = await createTestSession();
    });

    test('signInWithEmail with valid code', () async {
      final testEmail = 'test@example.com';
      final testCode = '123456';

      // Mock OTP validation
      mockValidateOneTimeCode(testEmail, testCode, true);

      final response = await endpoint.signInWithEmail(
        session,
        testEmail,
        testCode,
      );

      expect(response.user.email, equals(testEmail));
      expect(response.sessionToken, isNotEmpty);
      expect(response.expiresIn, equals(Duration(minutes: 15)));
    });

    test('signInWithEmail with invalid code throws error', () async {
      final testEmail = 'test@example.com';
      final invalidCode = '000000';

      // Mock OTP validation failure
      mockValidateOneTimeCode(testEmail, invalidCode, false);

      expect(
        () => endpoint.signInWithEmail(session, testEmail, invalidCode),
        throwsArgumentError,
      );
    });
  });
}
```

### 2. Integration Tests

```dart
// test/integration/api_integration_test.dart
import 'package:test/test.dart';
import 'package:serverpod_test/serverpod_test.dart';

void main() {
  group('API Integration Tests', () {
    late ServerpodTestServer server;

    setUpAll(() async {
      server = await createTestServer();
    });

    tearDownAll(() async {
      await server.close();
    });

    test('Complete user journey', () async {
      final session = await createTestSession();

      // 1. User signs up
      final authResponse = await server.auth.signInWithEmail(
        session,
        'newuser@example.com',
        '123456',
      );

      expect(authResponse.user, isNotNull);

      // 2. User browses stories
      final storiesResponse = await server.story.getStories(
        session,
        StoryListRequest(limit: 10, offset: 0),
      );

      expect(storiesResponse.stories, isNotEmpty);

      // 3. User views story
      final story = storiesResponse.stories.first;
      final storyResponse = await server.story.getStory(session, story.id!);

      expect(storyResponse.story.id, equals(story.id));

      // 4. User submits offer
      final offerResponse = await server.marketplace.submitOffer(
        session,
        SubmitOfferRequest(
          storyId: story.id!,
          amount: story.minimumOffer + 10,
        ),
      );

      expect(offerResponse.offer.amount, equals(story.minimumOffer + 10));
    });
  });
}
```

## Deployment

### 1. Docker Configuration

```dockerfile
# packages/serverpod_backend/Dockerfile
FROM dart:3.8.0-slim

WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Install dependencies
RUN dart pub get

# Copy source code
COPY . .

# Generate server code
RUN dart run serverpod generate

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the server
CMD ["dart", "run", "bin/main.dart"]
```

### 2. Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  serverpod:
    build:
      context: ./packages/serverpod_backend
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - DATABASE_HOST=postgres
      - REDIS_HOST=redis
    depends_on:
      - postgres
      - redis
    volumes:
      - ./config:/app/config

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: craft_marketplace
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### 3. Kubernetes Deployment

```yaml
# k8s/serverpod-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: serverpod-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: serverpod-backend
  template:
    metadata:
      labels:
        app: serverpod-backend
    spec:
      containers:
      - name: serverpod
        image: craftmarketplace/serverpod:latest
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_HOST
          value: "postgres-service"
        - name: REDIS_HOST
          value: "redis-service"
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: password
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: serverpod-service
spec:
  selector:
    app: serverpod-backend
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
```

## Monitoring and Observability

### 1. Logging Configuration

```dart
// packages/serverpod_backend/src/config/logging.dart
import 'package:serverpod/serverpod.dart';

class LoggingConfig {
  static void configure(Server server) {
    // Structured logging
    server.serializationManager.addCodec(
      DurationSerializationCodec(),
    );
    server.serializationManager.addCodec(
      DateTimeSerializationCodec(),
    );

    // Custom log formatters
    server.logger = CraftLogger();
  }
}

class CraftLogger extends Logger {
  @override
  void log(String message, {LogLevel? level, dynamic error, StackTrace? stackTrace}) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level?.name ?? 'info',
      'message': message,
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
    };

    // Send to external logging service
    _sendToLoggingService(logEntry);

    // Also log to console for development
    if (server.isDevelopmentMode) {
      print('${logEntry['level']}: ${logEntry['message']}');
    }
  }

  void _sendToLoggingService(Map<String, dynamic> logEntry) {
    // Send to CloudWatch, DataDog, or similar
  }
}
```

### 2. Metrics Collection

```dart
// packages/serverpod_backend/src/monitoring/metrics.dart
import 'package:serverpod/serverpod.dart';

class MetricsCollector {
  static final Map<String, Counter> _counters = {};
  static final Map<String, Histogram> _histograms = {};

  static void incrementCounter(String name, {Map<String, String>? tags}) {
    final key = _generateKey(name, tags);
    _counters.putIfAbsent(key, () => Counter(name, tags: tags));
    _counters[key]!.increment();
  }

  static void recordHistogram(String name, double value, {Map<String, String>? tags}) {
    final key = _generateKey(name, tags);
    _histograms.putIfAbsent(key, () => Histogram(name, tags: tags));
    _histograms[key]!.observe(value);
  }

  static String _generateKey(String name, Map<String, String>? tags) {
    if (tags == null || tags.isEmpty) return name;
    final tagString = tags.entries.map((e) => '${e.key}=${e.value}').join(',');
    return '$name{$tagString}';
  }
}

// Usage in endpoints
class StoryEndpoint extends Endpoint {
  Future<StoryListResponse> getStories(Session session, StoryListRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await _fetchStories(session, request);

      MetricsCollector.incrementCounter('stories_fetched_success');
      return result;
    } catch (e) {
      MetricsCollector.incrementCounter('stories_fetched_error');
      rethrow;
    } finally {
      stopwatch.stop();
      MetricsCollector.recordHistogram(
        'stories_fetch_duration',
        stopwatch.elapsedMilliseconds.toDouble(),
      );
    }
  }
}
```

## Best Practices

### 1. Error Handling
- Use structured error responses
- Log errors with context
- Implement graceful degradation
- Provide meaningful error messages

### 2. Performance Optimization
- Use database indexes effectively
- Implement caching strategies
- Monitor and optimize slow queries
- Use connection pooling

### 3. Security
- Validate all inputs
- Use parameterized queries
- Implement rate limiting
- Secure sensitive configuration

### 4. Scalability
- Design for horizontal scaling
- Use background jobs for heavy tasks
- Implement proper monitoring
- Plan for capacity growth

This comprehensive Serverpod integration guide provides everything needed to successfully integrate and deploy the backend infrastructure for the Craft Video Marketplace.