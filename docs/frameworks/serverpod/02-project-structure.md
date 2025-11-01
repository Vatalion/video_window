# Serverpod Project Structure & Conventions

**Version:** Serverpod 2.9.x  
**Project:** Video Window  
**Last Updated:** 2025-10-30

---

## Overview

Video Window follows Serverpod's modular monolith architecture with clear domain boundaries. This guide explains our structure and conventions.

---

## Directory Structure

### Server Project (`video_window_server/`)

```
video_window_server/
├── lib/
│   └── src/
│       ├── endpoints/              # API endpoints (domain-organized)
│       │   ├── identity/
│       │   │   ├── auth_endpoint.dart
│       │   │   ├── user_endpoint.dart
│       │   │   └── session_endpoint.dart
│       │   ├── story/
│       │   │   ├── story_endpoint.dart
│       │   │   ├── media_endpoint.dart
│       │   │   └── feed_endpoint.dart
│       │   ├── offers/
│       │   │   ├── offer_endpoint.dart
│       │   │   └── auction_endpoint.dart
│       │   ├── payments/
│       │   │   ├── checkout_endpoint.dart
│       │   │   └── webhook_endpoint.dart
│       │   └── orders/
│       │       ├── order_endpoint.dart
│       │       └── shipping_endpoint.dart
│       │
│       ├── services/               # Business logic
│       │   ├── auth/
│       │   ├── auction/
│       │   └── payment/
│       │
│       ├── generated/              # Auto-generated (DO NOT EDIT)
│       │   └── protocol.dart
│       │
│       └── protocol/               # Protocol definitions (.yaml)
│           ├── user.yaml
│           ├── story.yaml
│           ├── offer.yaml
│           └── order.yaml
│
├── config/                         # Environment configurations
│   ├── development.yaml
│   ├── staging.yaml
│   └── production.yaml
│
├── migrations/                     # Database migrations
│   ├── 20251030120000_initial.sql
│   └── 20251030130000_add_auctions.sql
│
├── docker-compose.yaml             # Local development services
└── pubspec.yaml                    # Dependencies
```

### Client Project (`video_window_client/`)

**⚠️ AUTO-GENERATED - DO NOT EDIT MANUALLY**

```
video_window_client/
└── lib/
    └── src/
        ├── protocol/               # Generated models
        │   ├── user.dart
        │   ├── story.dart
        │   └── ...
        └── endpoints/              # Generated endpoint clients
            ├── identity_endpoint.dart
            ├── story_endpoint.dart
            └── ...
```

### Shared Project (`video_window_shared/`)

**⚠️ AUTO-GENERATED - DO NOT EDIT MANUALLY**

Contains models shared between server and client.

---

## Domain Organization

We organize code by business domain (bounded contexts):

### Identity Domain
- **Purpose:** Authentication, users, sessions
- **Endpoints:** `/identity/*`
- **Files:** `endpoints/identity/`, `services/auth/`

### Story Domain
- **Purpose:** Content creation, media, feed
- **Endpoints:** `/story/*`
- **Files:** `endpoints/story/`, `services/media/`

### Offers Domain
- **Purpose:** Marketplace offers, auctions
- **Endpoints:** `/offers/*`
- **Files:** `endpoints/offers/`, `services/auction/`

### Payments Domain
- **Purpose:** Checkout, Stripe integration
- **Endpoints:** `/payments/*`
- **Files:** `endpoints/payments/`, `services/payment/`

### Orders Domain
- **Purpose:** Order management, shipping
- **Endpoints:** `/orders/*`
- **Files:** `endpoints/orders/`, `services/fulfillment/`

---

## Naming Conventions

### Endpoints

**Pattern:** `{domain}_{resource}_endpoint.dart`

```dart
// File: endpoints/identity/auth_endpoint.dart
class AuthEndpoint extends Endpoint {
  @override
  String get name => 'identity.auth';
  
  Future<SignInResponse> signInWithEmail(
    Session session,
    String email,
    String otp,
  ) async {
    // Implementation
  }
}
```

**Endpoint Names:** `{domain}.{resource}.{action}`
- `identity.auth.signInWithEmail`
- `story.feed.getHomeFeed`
- `offers.auction.placeBid`

### Protocol Files

**Pattern:** `{entity_name}.yaml`

```yaml
# File: lib/src/protocol/user.yaml
class: User
table: users
fields:
  id: int, primary
  email: String
  createdAt: DateTime
```

### Database Tables

**Pattern:** `{plural_lowercase}`
- `users`
- `stories`
- `auction_bids`
- `payment_intents`

---

## File Organization Best Practices

### 1. Keep Endpoints Focused

```dart
// ✅ GOOD - Single responsibility
class AuthEndpoint extends Endpoint {
  Future<SignInResponse> signInWithEmail(...) async {}
  Future<void> signOut(Session session) async {}
}

// ❌ BAD - Mixed concerns
class UserEndpoint extends Endpoint {
  Future<SignInResponse> signIn(...) async {}
  Future<Story> createStory(...) async {} // Wrong domain!
}
```

### 2. Use Services for Business Logic

```dart
// Endpoint - thin controller
class OfferEndpoint extends Endpoint {
  Future<Offer> submitOffer(Session session, OfferInput input) async {
    final service = AuctionService(session);
    return await service.submitOffer(input);
  }
}

// Service - business logic
class AuctionService {
  final Session session;
  AuctionService(this.session);
  
  Future<Offer> submitOffer(OfferInput input) async {
    // Validation
    // Business rules
    // Database operations
  }
}
```

### 3. Protocol Files Match Database

```yaml
# Protocol defines structure
class: AuctionBid
table: auction_bids
fields:
  id: int, primary
  auctionId: int, parent=Auction
  userId: int, parent=User
  amount: int
  bidAt: DateTime
```

---

## Configuration Management

### Environment-Specific Configs

**Development:**
```yaml
# config/development.yaml
database:
  host: localhost
  name: video_window_dev

server:
  port: 8080
  publicHost: localhost
  publicScheme: http
```

**Production:**
```yaml
# config/production.yaml
database:
  host: ${DB_HOST}
  name: ${DB_NAME}

server:
  port: 8080
  publicHost: ${PUBLIC_HOST}
  publicScheme: https
```

### Accessing Configuration

```dart
import 'package:serverpod/serverpod.dart';

class MyEndpoint extends Endpoint {
  Future<void> doSomething(Session session) async {
    final dbHost = session.serverpod.config.database.host;
    final publicHost = session.serverpod.config.server.publicHost;
  }
}
```

---

## Migration Files

### Location
`video_window_server/migrations/`

### Naming Convention
`{timestamp}_{description}.sql`

Example: `20251030120000_add_auction_soft_close.sql`

### Content Structure
```sql
-- Migration: Add auction soft close
-- Created: 2025-10-30
-- Description: Adds soft close extension fields to auctions table

ALTER TABLE auctions
ADD COLUMN soft_close_extensions INT DEFAULT 0,
ADD COLUMN max_extensions INT DEFAULT 96; -- 24h in 15min increments

CREATE INDEX idx_auctions_end_time ON auctions(end_time);
```

---

## Related Documentation

- **Setup:** [01-setup-installation.md](./01-setup-installation.md)
- **Code Generation:** [03-code-generation.md](./03-code-generation.md)
- **Architecture:** `../../architecture/serverpod-integration-guide.md`

---

**Key Takeaway:** Our structure separates concerns by domain, keeps endpoints thin, and centralizes business logic in services.
