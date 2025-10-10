# Knowledge Transfer Materials

**Comprehensive Documentation Handoff Package**
**Version:** 1.0
**Date:** 2025-10-09

## Overview

This knowledge transfer package ensures comprehensive documentation of all systems, processes, and domain knowledge required for successful project execution. It serves as the definitive reference for the Craft Video Marketplace project.

## Documentation Structure

### 1. System Architecture Documentation
### 2. API Specifications and Contracts
### 3. Database Schema and Design
### 4. Security and Compliance Documentation
### 5. Operational Procedures and Runbooks
### 6. Decision Records and Rationale
### 7. Code Standards and Guidelines
### 8. Testing and Quality Assurance

## 1. System Architecture Documentation

### High-Level Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile Apps   │    │   Web Client    │    │  Admin Portal   │
│  (Flutter)      │    │   (Flutter Web) │    │    (React)      │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │      API Gateway          │
                    │     (Load Balancer)       │
                    └─────────────┬─────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │   Serverpod Backend       │
                    │   (Modular Monolith)      │
                    └─────────────┬─────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
┌─────────▼───────┐    ┌─────────▼───────┐    ┌─────────▼───────┐
│   PostgreSQL   │    │      Redis      │    │  File Storage   │
│   (Primary)    │    │    (Cache)      │    │     (S3)        │
└────────────────┘    └────────────────┘    └────────────────┘
```

### Technology Stack Overview

#### Client-Side Technologies
| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Mobile Framework | Flutter | 3.19.6 | Cross-platform mobile development |
| Language | Dart | 3.5.6 | Application logic and UI |
| State Management | flutter_bloc | 8.1.5 | State management and business logic |
| Navigation | go_router | 12.1.3 | Declarative routing and deep linking |
| Video Player | video_player | 2.8.1 | Video playback functionality |
| Image Loading | cached_network_image | 3.3.0 | Optimized image loading and caching |

#### Server-Side Technologies
| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Backend Framework | Serverpod | 2.9.x | Modular monolith server framework |
| Language | Dart | 3.5.6 | Server-side business logic |
| Database | PostgreSQL | 15.x | Primary data storage |
| Cache | Redis | 7.x | Caching and session storage |
| File Storage | AWS S3 | Latest | Media file storage |
| CDN | CloudFront | Latest | Content delivery and streaming |

#### Third-Party Services
| Service | Purpose | Integration |
|---------|---------|-------------|
| Stripe | Payment processing | Checkout and payout management |
| Firebase | Push notifications | Mobile push notifications |
| SendGrid | Email delivery | Transactional emails |
| Twilio | SMS services | Phone verification and alerts |
| Sentry | Error tracking | Application monitoring |

### Microservices Architecture (Future State)

#### Bounded Contexts
```
┌─────────────────────────────────────────────────────────────┐
│                    Serverpod Backend                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Auth      │  │    Content   │  │      Commerce       │  │
│  │   Module    │  │   Module     │  │       Module        │  │
│  │             │  │             │  │                     │  │
│  │ • Users     │  │ • Stories    │  │ • Offers           │  │
│  │ • Sessions  │  │ • Media      │  │ • Auctions         │  │
│  │ • Profiles  │  │ • Comments   │  │ • Payments         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Admin     │  │  Analytics  │  │      Notifications  │  │
│  │   Module    │  │   Module    │  │        Module       │  │
│  │             │  │             │  │                     │  │
│  │ • Users     │  │ • Events     │  │ • Email            │  │
│  │ • Content   │  │ • Metrics    │  │ • Push             │  │
│  │ • Reports   │  │ • Reports    │  │ • SMS              │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 2. API Specifications and Contracts

### API Design Principles
1. **RESTful Design**: Follow REST conventions for API design
2. **Versioning**: Use URL versioning (e.g., `/api/v1/`)
3. **Consistent Response Format**: Standardized response structure
4. **Error Handling**: Proper HTTP status codes and error messages
5. **Rate Limiting**: Implement appropriate rate limiting
6. **Authentication**: JWT-based authentication
7. **Documentation**: OpenAPI/Swagger specifications

### API Response Format

#### Success Response
```json
{
  "success": true,
  "data": {
    // Response data here
  },
  "meta": {
    "timestamp": "2025-10-09T10:00:00Z",
    "request_id": "req_123456789",
    "version": "v1"
  }
}
```

#### Error Response
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input parameters",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  },
  "meta": {
    "timestamp": "2025-10-09T10:00:00Z",
    "request_id": "req_123456789",
    "version": "v1"
  }
}
```

### Core API Endpoints

#### Authentication Endpoints
```yaml
# User Registration
POST /api/v1/auth/register
Content-Type: application/json

Request:
{
  "email": "user@example.com",
  "password": "secure_password",
  "user_type": "viewer|maker",
  "profile": {
    "display_name": "John Doe",
    "bio": "Optional bio"
  }
}

Response:
{
  "success": true,
  "data": {
    "user_id": "user_12345",
    "email": "user@example.com",
    "user_type": "viewer",
    "profile": {
      "display_name": "John Doe",
      "bio": "Optional bio"
    },
    "access_token": "jwt_token_here",
    "refresh_token": "refresh_token_here"
  }
}

# User Login
POST /api/v1/auth/login
Content-Type: application/json

Request:
{
  "email": "user@example.com",
  "password": "secure_password"
}

Response:
{
  "success": true,
  "data": {
    "user_id": "user_12345",
    "email": "user@example.com",
    "user_type": "viewer",
    "access_token": "jwt_token_here",
    "refresh_token": "refresh_token_here"
  }
}
```

#### Content Endpoints
```yaml
# Get Feed
GET /api/v1/feed
Authorization: Bearer {access_token}
Query Parameters:
  - page: integer (default: 1)
  - limit: integer (default: 20, max: 100)
  - category: string (optional)

Response:
{
  "success": true,
  "data": {
    "stories": [
      {
        "story_id": "story_12345",
        "title": "Handmade Ceramic Mug",
        "maker": {
          "maker_id": "maker_123",
          "display_name": "Jane Potter",
          "avatar_url": "https://example.com/avatar.jpg"
        },
        "thumbnail_url": "https://example.com/thumbnail.jpg",
        "video_duration": 60,
        "created_at": "2025-10-09T10:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 150,
      "has_more": true
    }
  }
}

# Get Story Details
GET /api/v1/stories/{story_id}
Authorization: Bearer {access_token}

Response:
{
  "success": true,
  "data": {
    "story_id": "story_12345",
    "title": "Handmade Ceramic Mug",
    "description": "Beautiful handmade ceramic mug with unique glaze",
    "maker": {
      "maker_id": "maker_123",
      "display_name": "Jane Potter",
      "avatar_url": "https://example.com/avatar.jpg",
      "bio": "Ceramic artist with 10 years experience"
    },
    "media": {
      "carousel": [
        {
          "video_url": "https://example.com/video1.m3u8",
          "thumbnail_url": "https://example.com/thumb1.jpg",
          "context": "In Use",
          "duration": 30
        },
        {
          "video_url": "https://example.com/video2.m3u8",
          "thumbnail_url": "https://example.com/thumb2.jpg",
          "context": "Making Process",
          "duration": 45
        }
      ]
    },
    "sections": [
      {
        "type": "overview",
        "content": "Description of the ceramic mug..."
      },
      {
        "type": "materials",
        "content": "High-quality clay, food-safe glaze..."
      }
    ],
    "pricing": {
      "minimum_offer": 25.00,
      "currency": "USD"
    },
    "created_at": "2025-10-09T10:00:00Z",
    "updated_at": "2025-10-09T10:00:00Z"
  }
}
```

#### Commerce Endpoints
```yaml
# Submit Offer
POST /api/v1/offers
Authorization: Bearer {access_token}
Content-Type: application/json

Request:
{
  "story_id": "story_12345",
  "offer_amount": 35.00,
  "message": "I love this mug! Would you ship to New York?",
  "currency": "USD"
}

Response:
{
  "success": true,
  "data": {
    "offer_id": "offer_12345",
    "story_id": "story_12345",
    "offer_amount": 35.00,
    "currency": "USD",
    "status": "pending",
    "created_at": "2025-10-09T10:00:00Z"
  }
}

# Place Bid
POST /api/v1/auctions/{auction_id}/bids
Authorization: Bearer {access_token}
Content-Type: application/json

Request:
{
  "bid_amount": 45.00,
  "currency": "USD"
}

Response:
{
  "success": true,
  "data": {
    "bid_id": "bid_12345",
    "auction_id": "auction_12345",
    "bid_amount": 45.00,
    "currency": "USD",
    "status": "active",
    "is_current_high_bid": true,
    "created_at": "2025-10-09T10:00:00Z"
  }
}
```

## 3. Database Schema and Design

### Database Design Principles
1. **Normalization**: Follow database normalization principles
2. **Indexing**: Proper indexing for performance
3. **Constraints**: Use foreign keys and constraints for data integrity
4. **Naming**: Consistent naming conventions (snake_case)
5. **Auditing**: Include created_at, updated_at, and deleted_at fields
6. **Soft Deletes**: Use soft deletes instead of hard deletes

### Core Tables

#### Users Table
```sql
CREATE TABLE users (
  user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('viewer', 'maker', 'admin')),
  email_verified BOOLEAN DEFAULT FALSE,
  phone VARCHAR(20),
  phone_verified BOOLEAN DEFAULT FALSE,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'deleted')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_type ON users(user_type);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created_at ON users(created_at);
```

#### User Profiles Table
```sql
CREATE TABLE user_profiles (
  profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  display_name VARCHAR(100) NOT NULL,
  bio TEXT,
  avatar_url VARCHAR(500),
  location VARCHAR(100),
  website VARCHAR(500),
  instagram_handle VARCHAR(50),
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_user_profiles_display_name ON user_profiles(display_name);
```

#### Stories Table
```sql
CREATE TABLE stories (
  story_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  maker_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(50),
  tags TEXT[],
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved', 'published', 'rejected', 'archived')),
  minimum_offer DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  carousel_config JSONB NOT NULL DEFAULT '[]',
  sections JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  published_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_stories_maker_id ON stories(maker_id);
CREATE INDEX idx_stories_status ON stories(status);
CREATE INDEX idx_stories_category ON stories(category);
CREATE INDEX idx_stories_published_at ON stories(published_at);
CREATE INDEX idx_stories_created_at ON stories(created_at);
CREATE INDEX idx_stories_tags ON stories USING GIN(tags);
```

#### Media Files Table
```sql
CREATE TABLE media_files (
  media_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID REFERENCES stories(story_id) ON DELETE CASCADE,
  file_type VARCHAR(20) NOT NULL CHECK (file_type IN ('video', 'image', 'audio')),
  original_filename VARCHAR(255) NOT NULL,
  file_path VARCHAR(500) NOT NULL,
  file_size BIGINT NOT NULL,
  mime_type VARCHAR(100) NOT NULL,
  duration INTEGER, -- for video/audio in seconds
  width INTEGER, -- for video/image
  height INTEGER, -- for video/image
  thumbnail_url VARCHAR(500),
  processing_status VARCHAR(20) DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_media_files_story_id ON media_files(story_id);
CREATE INDEX idx_media_files_type ON media_files(file_type);
CREATE INDEX idx_media_files_status ON media_files(processing_status);
```

#### Offers Table
```sql
CREATE TABLE offers (
  offer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES stories(story_id) ON DELETE CASCADE,
  buyer_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  offer_amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  message TEXT,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'withdrawn', 'expired')),
  responded_at TIMESTAMP WITH TIME ZONE,
  response_message TEXT,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_offers_story_id ON offers(story_id);
CREATE INDEX idx_offers_buyer_id ON offers(buyer_id);
CREATE INDEX idx_offers_status ON offers(status);
CREATE INDEX idx_offers_created_at ON offers(created_at);
```

#### Auctions Table
```sql
CREATE TABLE auctions (
  auction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES stories(story_id) ON DELETE CASCADE,
  starting_offer_id UUID REFERENCES offers(offer_id) ON DELETE SET NULL,
  current_bid_amount DECIMAL(10,2),
  current_bidder_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'ended', 'cancelled')),
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  actual_end_time TIMESTAMP WITH TIME ZONE,
  minimum_bid_increment DECIMAL(10,2) DEFAULT 5.00,
  soft_close_duration_minutes INTEGER DEFAULT 15,
  max_soft_close_minutes INTEGER DEFAULT 1440, -- 24 hours
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_auctions_story_id ON auctions(story_id);
CREATE INDEX idx_auctions_status ON auctions(status);
CREATE INDEX idx_auctions_end_time ON auctions(end_time);
CREATE INDEX idx_auctions_current_bidder ON auctions(current_bidder_id);
```

#### Bids Table
```sql
CREATE TABLE bids (
  bid_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id UUID NOT NULL REFERENCES auctions(auction_id) ON DELETE CASCADE,
  bidder_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  bid_amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'outbid', 'withdrawn', 'winning')),
  is_auto_bid BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_bids_auction_id ON bids(auction_id);
CREATE INDEX idx_bids_bidder_id ON bids(bidder_id);
CREATE INDEX idx_bids_status ON bids(status);
CREATE INDEX idx_bids_amount ON bids(bid_amount DESC);
```

## 4. Security and Compliance Documentation

### Security Architecture

#### Authentication and Authorization
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client App    │    │   API Gateway   │    │   Auth Service  │
│                 │    │                 │    │                 │
│ JWT Token       │───▶│ Validate Token  │───▶│ Verify JWT      │
│ Storage         │    │ Extract Claims  │    │ Check Status    │
│ Refresh Logic   │    │ Rate Limiting   │    │ Rate Limits     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

#### Security Measures
1. **Authentication**
   - JWT-based authentication with RS256 signing
   - Refresh token rotation
   - Multi-factor authentication for sensitive operations
   - Social login integration (Google, Apple)

2. **Authorization**
   - Role-based access control (RBAC)
   - Resource-level permissions
   - API endpoint protection
   - Feature flags for access control

3. **Data Protection**
   - Encryption at rest (AES-256)
   - Encryption in transit (TLS 1.3)
   - PII data masking in logs
   - Secure key management

4. **API Security**
   - Rate limiting per user and endpoint
   - Request size limits
   - Input validation and sanitization
   - SQL injection prevention
   - XSS protection

### Compliance Requirements

#### Data Protection (GDPR/CCPA)
```yaml
data_subject_rights:
  - access: "Users can request their personal data"
  - rectification: "Users can correct inaccurate data"
  - erasure: "Users can request data deletion"
  - portability: "Users can export their data"
  - objection: "Users can object to processing"
  - restriction: "Users can limit processing"

data_retention:
  user_data: "7 years after account deletion"
  transaction_data: "10 years for legal compliance"
  analytics_data: "25 months"
  logs: "90 days"
  backups: "1 year"

data_categories:
  personal_data:
    - email
    - name
    - phone
    - address
  sensitive_data:
    - payment_information
    - biometric_data
    - location_data
```

#### PCI DSS Compliance
```yaml
pci_scope: "SAQ A - Card-not-present merchants"
payment_security:
  - stripe_connect_express: "Payment processing"
  - tokenization: "Card data never stored"
  - ssl_tls: "All payment data encrypted"
  - access_control: "Strict access controls"
  - monitoring: "Continuous security monitoring"

network_security:
  - firewalls: "Web application firewalls"
  - intrusion_detection: "IDS/IPS systems"
  - vulnerability_scanning: "Regular security scans"
  - penetration_testing: "Annual pen tests"
```

### Security Incident Response

#### Incident Classification
```yaml
severity_levels:
  critical:
    description: "System compromise, data breach, service outage"
    response_time: "15 minutes"
    escalation: "Executive team, legal, PR"

  high:
    description: "Security vulnerability, degraded service"
    response_time: "1 hour"
    escalation: "Security team, engineering lead"

  medium:
    description: "Minor security issue, feature impact"
    response_time: "4 hours"
    escalation: "Engineering team"

  low:
    description: "Informational, non-urgent"
    response_time: "24 hours"
    escalation: "Team lead"
```

#### Incident Response Plan
```yaml
phases:
  preparation:
    - establish incident response team
    - define communication channels
    - prepare response tools
    - conduct regular drills

  detection:
    - monitoring alerts
    - user reports
    - automated scanning
    - third-party notifications

  analysis:
    - assess impact
    - determine scope
    - identify root cause
    - document findings

  containment:
    - isolate affected systems
    - block malicious activity
    - preserve evidence
    - implement temporary fixes

  eradication:
    - remove malware
    - patch vulnerabilities
    - restore clean systems
    - validate cleanup

  recovery:
    - restore services
    - monitor for recurrence
    - update defenses
    - document lessons learned

  lessons_learned:
    - post-incident review
    - update procedures
    - improve monitoring
    - train team
```

## 5. Operational Procedures and Runbooks

### Deployment Procedures

#### Standard Deployment Process
```yaml
prerequisites:
  - all_tests_passing: "All automated tests must pass"
  - code_review_approved: "Code review must be approved"
  - security_scan_passed: "Security scan must pass"
  - documentation_updated: "Documentation must be updated"

steps:
  1. create_release_branch:
      command: "git checkout -b release/v{{ version }}"
      description: "Create release branch from develop"

  2. run_full_test_suite:
      command: "flutter test && serverpod test"
      description: "Run complete test suite"

  3. build_artifacts:
      command: "flutter build apk && flutter build ios"
      description: "Build mobile application artifacts"

  4. deploy_backend:
      command: "serverpod deploy"
      description: "Deploy backend to staging"

  5. smoke_tests:
      command: "scripts/smoke-tests.sh"
      description: "Run smoke tests on staging"

  6. deploy_production:
      command: "serverpod deploy --environment=production"
      description: "Deploy to production"

  7. verify_deployment:
      command: "scripts/verify-deployment.sh"
      description: "Verify production deployment"

  8. tag_release:
      command: "git tag v{{ version }}"
      description: "Tag release version"

  9. merge_to_main:
      command: "git checkout main && git merge release/v{{ version }}"
      description: "Merge release to main branch"

  10. cleanup:
      command: "git branch -d release/v{{ version }}"
      description: "Clean up release branch"
```

#### Rollback Procedures
```yaml
database_rollback:
  steps:
    1. assess_impact:
        description: "Determine rollback scope and impact"

    2. backup_current:
        command: "pg_dump video_window_prod > backup_rollback.sql"
        description: "Create backup before rollback"

    3. stop_services:
        command: "serverpod stop"
        description: "Stop application services"

    4. rollback_database:
        command: "psql video_window_prod < migration_rollback.sql"
        description: "Rollback database migrations"

    5. restore_code:
        command: "git checkout v{{ previous_version }}"
        description: "Checkout previous version"

    6. restart_services:
        command: "serverpod start"
        description: "Restart application services"

    7. verify_rollback:
        command: "scripts/verify-rollback.sh"
        description: "Verify rollback was successful"

    8. communicate:
        description: "Notify stakeholders of rollback"
```

### Monitoring and Alerting

#### Health Checks
```yaml
endpoints:
  api_health:
    url: "/health"
    method: "GET"
    expected_status: 200
    expected_response: '{"status": "healthy"}"

  database_health:
    query: "SELECT 1"
    expected_response: "1"

  redis_health:
    command: "redis-cli ping"
    expected_response: "PONG"

  external_services:
    stripe_api:
      url: "https://api.stripe.com/v1"
      method: "GET"
      expected_status: 200

    sendgrid_api:
      url: "https://api.sendgrid.com/v3"
      method: "GET"
      expected_status: 401  # Expected unauthorized without key
```

#### Monitoring Metrics
```yaml
application_metrics:
  - name: "http_requests_total"
    type: "counter"
    description: "Total HTTP requests"
    labels: ["method", "endpoint", "status"]

  - name: "http_request_duration_seconds"
    type: "histogram"
    description: "HTTP request duration"
    labels: ["method", "endpoint"]

  - name: "active_users"
    type: "gauge"
    description: "Number of active users"

  - name: "story_views_total"
    type: "counter"
    description: "Total story views"
    labels: ["story_id", "user_type"]

infrastructure_metrics:
  - name: "cpu_usage_percent"
    type: "gauge"
    description: "CPU usage percentage"

  - name: "memory_usage_bytes"
    type: "gauge"
    description: "Memory usage in bytes"

  - name: "disk_usage_percent"
    type: "gauge"
    description: "Disk usage percentage"

  - name: "network_bytes_sent"
    type: "counter"
    description: "Network bytes sent"

  - name: "network_bytes_received"
    type: "counter"
    description: "Network bytes received"
```

### Backup and Recovery

#### Database Backup Strategy
```yaml
backup_schedule:
  daily_full:
    time: "02:00 UTC"
    retention: "30 days"
    command: "pg_dump video_window_prod | gzip > backup_$(date +%Y%m%d).sql.gz"

  weekly_incremental:
    time: "03:00 UTC"
    retention: "90 days"
    command: "pg_basebackup -h localhost -D backup_incr_$(date +%Y%m%d) -U replica_user"

  point_in_time_recovery:
    wal_archive: "enabled"
    wal_retention: "7 days"
    recovery_target: "any time within 7 days"

restore_procedures:
  1. assess_restoration_need:
      description: "Determine what needs to be restored and why"

  2. select_backup:
      description: "Choose appropriate backup based on recovery point objective"

  3. prepare_database:
      command: "systemctl stop postgresql"
      description: "Stop database service"

  4. restore_data:
      command: "gunzip -c backup_20251009.sql.gz | psql video_window_prod"
      description: "Restore database from backup"

  5. verify_restoration:
      command: "psql -c 'SELECT COUNT(*) FROM users;' video_window_prod"
      description: "Verify data restoration"

  6. restart_services:
      command: "systemctl start postgresql && serverpod start"
      description: "Restart all services"

  7. post_restore_validation:
      command: "scripts/post-restore-validation.sh"
      description: "Run comprehensive validation"
```

## 6. Decision Records and Rationale

### Architecture Decision Records (ADRs)

#### ADR-001: Technology Stack Selection
```markdown
# ADR-001: Technology Stack Selection

## Status
Accepted

## Context
We need to select the technology stack for the Craft Video Marketplace platform. The requirements include:
- Cross-platform mobile development (iOS and Android)
- Real-time video streaming
- E-commerce functionality
- Scalable backend
- Rapid development timeline

## Decision
We selected Flutter for the mobile frontend and Serverpod for the backend.

## Rationale
**Flutter:**
- Single codebase for iOS and Android
- Excellent performance for video playback
- Strong ecosystem and community support
- Fast development with hot reload
- Native integration capabilities

**Serverpod:**
- Native Dart integration with Flutter
- Built-in database ORM and migrations
- Real-time WebSocket support
- Automatic API documentation generation
- Scalable architecture

**Alternatives Considered:**
- React Native + Node.js: More complex integration
- Native iOS/Android: Higher development cost
- Flutter + Firebase: Limited backend flexibility

## Consequences
- Positive: Unified language (Dart) across stack
- Positive: Fast development cycles
- Positive: Good performance for mobile use case
- Risk: Serverpod is newer technology
- Risk: Smaller ecosystem compared to Node.js
```

#### ADR-002: Database Choice
```markdown
# ADR-002: Database Choice

## Status
Accepted

## Context
We need to select a database for storing user data, content metadata, and e-commerce transactions. Requirements include:
- ACID compliance for transactions
- JSON support for flexible schemas
- Good performance for read-heavy workloads
- Strong reliability and backup features

## Decision
We selected PostgreSQL as the primary database with Redis for caching.

## Rationale
**PostgreSQL:**
- ACID compliance for transaction integrity
- Excellent JSONB support for flexible data
- Strong performance and indexing capabilities
- Mature ecosystem and tooling
- Good backup and replication features

**Redis:**
- In-memory performance for caching
- Good for session storage
- Simple data structures for queues

**Alternatives Considered:**
- MongoDB: Less suitable for complex transactions
- MySQL: Limited JSON support compared to PostgreSQL
- DynamoDB: Higher cost and limited query capabilities

## Consequences
- Positive: Strong data integrity guarantees
- Positive: Flexible schema design with JSONB
- Positive: Good performance for our use case
- Neutral: Requires database administration expertise
- Positive: Good ecosystem and tooling support
```

### Product Decisions

#### Decision-001: Video Carousel Approach
```markdown
# Decision-001: Video Carousel Implementation

## Status
Implemented

## Context
We need to decide how to present multiple video contexts for each story. Options include:
- Multiple separate video players
- Tabbed interface
- Single carousel interface
- Picture-in-picture approach

## Decision
We implemented a single timeline carousel interface with 3-7 video contexts.

## Rationale
- **User Experience**: Intuitive touch interaction for mobile
- **Performance**: Single video player instance reduces memory usage
- **Consistency**: Uniform interaction patterns across all videos
- **Scalability**: Fixed limit (3-7 videos) balances richness with performance

## User Benefits
- Seamless exploration of different product perspectives
- Reduced cognitive load with unified interface
- Better mobile performance through optimization
- Consistent accessibility features

## Technical Benefits
- Simplified state management
- Reduced memory footprint
- Consistent DRM protection
- Easier maintenance and testing
```

## 7. Code Standards and Guidelines

### Coding Standards

#### Dart/Flutter Standards
```dart
// File naming: snake_case.dart
// Class naming: PascalCase
// Variable naming: camelCase
// Constant naming: SCREAMING_SNAKE_CASE

// Example class structure
class StoryDetailController {
  final StoryRepository _repository;
  final StreamController<StoryDetailState> _stateController;

  // Private variables with underscore prefix
  Story? _currentStory;
  bool _isLoading = false;

  // Public constructor
  StoryDetailController({
    required StoryRepository repository,
  }) : _repository = repository,
       _stateController = StreamController.broadcast();

  // Public getters
  Stream<StoryDetailState> get stateStream => _stateController.stream;
  bool get isLoading => _isLoading;

  // Public methods
  Future<void> loadStory(String storyId) async {
    _setLoading(true);

    try {
      final story = await _repository.getStory(storyId);
      _currentStory = story;
      _stateController.add(StoryDetailLoaded(story));
    } catch (e) {
      _stateController.add(StoryDetailError(e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    _stateController.add(StoryDetailLoading());
  }

  // Resource cleanup
  void dispose() {
    _stateController.close();
  }
}
```

#### Error Handling Standards
```dart
// Use Result/Either pattern for error handling
abstract class Result<T> {
  const Result();

  bool get isSuccess;
  bool get isFailure;

  T get data;
  String get error;

  factory Result.success(T data) = Success<T>;
  factory Result.failure(String error) = Failure<T>;
}

class Success<T> extends Result<T> {
  final T _data;

  const Success(this._data);

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  T get data => _data;

  @override
  String get error => throw UnimplementedError();
}

class Failure<T> extends Result<T> {
  final String _error;

  const Failure(this._error);

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  T get data => throw UnimplementedError();

  @override
  String get error => _error;
}

// Usage example
Future<Result<Story>> getStory(String storyId) async {
  try {
    final story = await _repository.getStory(storyId);
    return Result.success(story);
  } catch (e) {
    return Result.failure('Failed to load story: ${e.toString()}');
  }
}
```

### Testing Standards

#### Unit Testing Structure
```dart
// test/features/story/controllers/story_detail_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:video_window/features/story/controllers/story_detail_controller.dart';

class MockStoryRepository extends Mock implements StoryRepository {}

void main() {
  group('StoryDetailController', () {
    late MockStoryRepository mockRepository;
    late StoryDetailController controller;

    setUp(() {
      mockRepository = MockStoryRepository();
      controller = StoryDetailController(repository: mockRepository);
    });

    tearDown(() {
      controller.dispose();
    });

    test('should load story successfully', () async {
      // Arrange
      final testStory = Story.test();
      when(mockRepository.getStory(any))
          .thenAnswer((_) async => testStory);

      // Act
      await controller.loadStory('test-id');

      // Assert
      expect(controller.isLoading, false);
      expect(controller.stateStream, emitsInOrder([
        isA<StoryDetailLoading>(),
        isA<StoryDetailLoaded>()
      ]));
      verify(mockRepository.getStory('test-id')).called(1);
    });

    test('should handle error when loading story fails', () async {
      // Arrange
      when(mockRepository.getStory(any))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      await controller.loadStory('test-id');

      expect(controller.stateStream, emitsInOrder([
        isA<StoryDetailLoading>(),
        isA<StoryDetailError>()
      ]));
      verify(mockRepository.getStory('test-id')).called(1);
    });
  });
}
```

## 8. Testing and Quality Assurance

### Testing Strategy

#### Test Pyramid
```
        /\
       /  \
      / E2E \     <- 10% (Critical user flows)
     /______\
    /        \
   /Integration\ <- 20% (API and component integration)
  /__________\
 /            \
/  Unit Tests  \   <- 70% (Business logic and utilities)
/______________\
```

#### Test Coverage Requirements
```yaml
coverage_targets:
  unit_tests:
    minimum_coverage: 80
    business_logic: 95
    utilities: 90

  integration_tests:
    api_endpoints: 100
    critical_workflows: 100

  e2e_tests:
    critical_user_flows: 100
    main_scenarios: 100

exclusions:
  - generated_files
  - test_files
  - configuration_files
  - platform_specific_code
```

### Quality Gates

#### Pre-commit Quality Checks
```yaml
checks:
  - name: "code_formatting"
    command: "dart format --set-exit-if-changed ."
    description: "Check code formatting"

  - name: "static_analysis"
    command: "flutter analyze --fatal-infos --fatal-warnings"
    description: "Run static analysis"

  - name: "unit_tests"
    command: "flutter test --no-pub --coverage"
    description: "Run unit tests"
    min_coverage: 80

  - name: "security_scan"
    command: "dart analyze --fatal-warnings"
    description: "Security vulnerability scan"
```

#### Pull Request Quality Gates
```yaml
requirements:
  approvals:
    minimum: 1
    required_reviewers: ["tech-lead"]

  checks:
    required:
      - "format"
      - "analyze"
      - "test"
      - "security_scan"

  restrictions:
    file_size_limit: "1MB"
    line_changes_limit: 500

  automerge:
    enabled: false
    require_branch_up_to_date: true
```

### Performance Testing

#### Load Testing Scenarios
```yaml
scenarios:
  api_load_test:
    users: 100
    duration: "10m"
    ramp_up: "2m"
    endpoints:
      - path: "/api/v1/feed"
        method: "GET"
        weight: 40
      - path: "/api/v1/stories/{id}"
        method: "GET"
        weight: 30
      - path: "/api/v1/offers"
        method: "POST"
        weight: 20
      - path: "/api/v1/auth/login"
        method: "POST"
        weight: 10

  stress_test:
    users: 500
    duration: "5m"
    ramp_up: "1m"
    endpoints:
      - path: "/api/v1/feed"
        method: "GET"
        weight: 100

performance_targets:
  api_response_time:
    p50: "<200ms"
    p95: "<500ms"
    p99: "<1000ms"

  error_rate:
    target: "<0.1%"

  throughput:
    target: ">1000 requests/second"
```

---

This comprehensive Knowledge Transfer package ensures that all critical project knowledge is documented and accessible to the team. It serves as the definitive reference for understanding system architecture, implementation details, and operational procedures.