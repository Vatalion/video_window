# Epic 9: Offer Submission Flow - Technical Specification

**Epic Goal:** Implement secure, validated offer submission with real-time business rule enforcement, comprehensive qualification checks, and seamless auction system integration.

**Stories:**
- 9.1: Offer Entry UI & Real-time Validation
- 9.2: Server Validation & Auction Trigger
- 9.3: Offer Withdrawal & Cancellation
- 9.4: Offer State Management & Audit Trail

## Architecture Overview

### Component Mapping
- **Flutter App:** Commerce Module (offer submission UI, validation feedback, confirmation flows)
- **Serverpod:** Offers Service (validation, persistence, auction integration), Identity Service (user qualification)
- **Database:** Offers table, maker_profiles table, artifact_stories table, audit_log table
- **External:** Payment provider for eligibility checks, notification service for maker alerts

### Technology Stack
- **Observability & Compliance:** Datadog Agent 7.53.0 (`offers.validation.duration_ms`, `offers.submission.success_rate`), Kibana 8.14 dashboards for audit log review, HashiCorp Vault 1.15.3/1Password Connect 1.7.3 for secret distribution, CloudWatch Logs Insights queries automated via `cwlogs` 3.1.2.

### Source Tree & File Directives
```text
video_window_flutter/
  packages/
    features/
      commerce/
        lib/
          presentation/
            pages/
              offer_submission_page.dart         # Modify: integrate validation + submission flows (Story 9.1)
              offer_cancellation_page.dart       # Create: cancellation flow UI (Story 9.3)
            widgets/
              offer_validation_banner.dart       # Create: real-time rule feedback (Story 9.1)
              offer_summary_sheet.dart           # Create: confirmation & terms (Story 9.1)
              offer_cancellation_dialog.dart     # Create: reason capture + SLA display (Story 9.3)
            bloc/
              offer_bloc.dart                    # Modify: validation/submission state machine (Story 9.1)
              offer_cancellation_bloc.dart       # Create: cancellation workflows (Story 9.3)
              offer_history_bloc.dart            # Create: audit/history stream (Story 9.4)
          use_cases/
            submit_offer_use_case.dart           # Create: orchestrate client submission (Story 9.1)
            cancel_offer_use_case.dart           # Create: cancellation + analytics (Story 9.3)
            fetch_offer_history_use_case.dart    # Create: timelines + audit retrieval (Story 9.4)
    core/
      lib/
        data/
          repositories/
            offers_repository.dart               # Modify: Serverpod client integration & caching (Story 9.1)
          services/
            offers_validation_service.dart       # Create: debounce, currency normalization (Story 9.1)
            offers_audit_service.dart            # Create: local audit context logging (Story 9.4)
        security/
          rate_limit_guard.dart                  # Create: client-side submission throttling (Story 9.1)

video_window_server/
  lib/
    src/
      endpoints/
        offers/
          offer_validation_endpoint.dart         # Create: eligibility + rule evaluation (Story 9.2)
          offer_submit_endpoint.dart             # Modify: idempotent submission + auction trigger (Story 9.2)
          offer_cancel_endpoint.dart             # Create: cancellation SLA enforcement (Story 9.3)
          offer_history_endpoint.dart            # Create: audit trail retrieval (Story 9.4)
      services/
        offers/
          offer_validation_service.dart          # Modify: incorporate OPA rule engine (Story 9.2)
          offer_submission_service.dart          # Modify: Stripe/Sift integration + event emission (Story 9.2)
          offer_cancellation_service.dart        # Create: cancellation business rules (Story 9.3)
          offer_audit_service.dart               # Create: audit log persistence + exports (Story 9.4)
        auctions/
          auction_trigger_service.dart           # Modify: triggered by offer events (Story 9.2)
      integrations/
        stripe_connect_client.dart               # Modify: payment method eligibility check (Story 9.2)
        sns_notification_client.dart             # Create: maker alert publishing (Story 9.2)
        sift_risk_client.dart                    # Create: risk scoring integration (Story 9.2)
    test/
      endpoints/offers/
        offer_validation_endpoint_test.dart      # Create: eligibility scenarios
        offer_submit_endpoint_test.dart          # Create: idempotency + auction trigger
        offer_cancel_endpoint_test.dart          # Create: SLA + auth scenarios
        offer_history_endpoint_test.dart         # Create: pagination + audit filtering
      services/offers/
        offer_validation_service_test.dart       # Expand coverage for rule engine
        offer_submission_service_test.dart       # Add payment/risk checks
        offer_cancellation_service_test.dart     # Verify modification windows
        offer_audit_service_test.dart            # Ensure logging completeness

infrastructure/
  terraform/
    offers.tf                                   # Modify: SNS topics, EventBridge rules, Redis cluster, audit log storage
    offers_audit_glacier.tf                     # Create: Glacier vault for audit retention (Story 9.4)
  ci/
    offers_checks.yaml                          # Create: lint + integration suite + contract tests
```
- **Flutter SDK & Packages:** Flutter 3.19.6, Dart 3.5.6, `flutter_bloc` 9.1.0, `formz` 0.6.2, `intl` 0.19.0, `currency_text_input_formatter` 2.1.1, `dio` 5.5.0, `retry` 3.1.2 for resilient inbound/outbound API calls.
- **Client Security & Storage:** `flutter_secure_storage` 9.2.1 for credential escrow, `package_info_plus` 8.0.2 for device metadata, `sentry_flutter` 8.4.0 for runtime error capture with privacy scrubbing enabled.
- **Server Platform:** Serverpod 2.9.2, `serverpod_auth_server` 2.9.2, `postgres` 2.6.3 driver (PostgreSQL 15.6 cluster), Redis 7.2.4 (ElastiCache) for idempotency tokens and hot caches, `dart_jsonwebtoken` 2.5.1 for signed offer tickets.
- **Business Rule Engine:** Internal `offer_rule_engine` 1.0.0 (ReGo-backed) deployed via OPA sidecar v0.64.0, referencing policy bundle `opa-offers-bundle@2025-10-15` for eligibility thresholds.
- **Payment & Risk Integrations:** Stripe Connect API version `2024-10-15`, `stripe_dart` 8.1.0 for payment method verification, Sift Decision API v206 with SDK `sift` 0.10.0 for fraud scoring, Plaid Identity API `2024-08-01` (plaid client 5.6.0) for bank-backed qualification.
- **Notification & Messaging:** AWS SNS SDK (`aws_sns` 1.4.0) for maker alerts, EventBridge bus `commerce-offers-events@2025-09`, Segment ingestion backend 4.5.1 for analytics fan-out, Slack webhook orchestrated via `slack_notifier` 2.1.0 for operations alerts.
- **Observability & Compliance:** Datadog Agent 7.53.0 (`offers.validation.duration_ms`, `offers.submission.success_rate`), Kibana 8.14 dashboards for audit log review, HashiCorp Vault 1.15.3/1Password Connect 1.7.3 for secret distribution, CloudWatch Logs Insights queries automated via `cwlogs` 3.1.2.

### Implementation Guide
1. **Real-time Offer Entry (Story 9.1)**
  - Extend `offer_bloc.dart` to validate every field change through `offers_validation_service.dart`, emitting `OfferValidationInProgress` → `OfferValidationSuccess|Failure` states with localized error payloads for `offer_validation_banner.dart`.
  - Update `offer_submission_page.dart` to hydrate `OfferDraft` from `maker_profiles` policy data, gating submission until currency normalization, maker consent, and market eligibility flags pass `formz` constraints.
  - Implement `submit_offer_use_case.dart` with debounce + exponential backoff via `retry` 3.1.2 and client-side rate limiting using `rate_limit_guard.dart` to enforce `MAX_OFFERS_PER_STORY` before touching the backend.
2. **Server Validation Pipeline (Story 9.2)**
  - Create `offer_validation_endpoint.dart` orchestrating synchronous policy evaluation (`offer_validation_service.dart` → `offer_rule_engine` OPA bundle) with maker policy cache hydrated from `offer_policy_repository`.
  - Refactor `offer_submit_endpoint.dart` to require a valid `idempotency_key`, stamp `submission_trace_id`, and call `auction_trigger_service.dart` when `isOpening` flag transitions from false → true.
  - Introduce `OfferSubmissionSaga` within `offer_submission_service.dart` to run validation → payment pre-authorization → persistence → audit logging in a single transaction, posting domain events to EventBridge.
3. **Payment & Risk Clearance (Story 9.2)**
  - Enforce two-step verification inside `offer_submission_service.dart`: first leverage `stripe_connect_client.dart` for payment method verification, then send buyer, device, and offer context to `sift_risk_client.dart` for a fraud score before persisting.
  - Implement compensating actions for negative outcomes (reverse payment hold, emit `OfferSubmissionRejected` event) and ensure `offers_repository.dart` consumes new failure enums for consistent client messaging.
  - Cache qualification results in Redis with 10-minute TTL keyed by `(storyId, buyerId)` to minimize redundant third-party calls while respecting compliance logging.
4. **Cancellation & Audit Trail (Stories 9.3 & 9.4)**
  - Build `offer_cancellation_bloc.dart` and `offer_cancellation_page.dart` to fetch SLA metadata and reason catalogs from `offer_policy` payloads, writing analytics via `OfferAnalytics.cancelled` helper.
  - Add `offer_cancel_endpoint.dart` enforcing maker/buyer authority, modification window (`OFFER_MODIFICATION_WINDOW_MINUTES`), and audit log append through `offer_audit_service.dart` with immutable records stored to Glacier via `offers_audit_glacier.tf`.
  - Implement `fetch_offer_history_use_case.dart` to page `offer_history_endpoint.dart`, merging local audit context from `offers_audit_service.dart` for offline display consistency.
5. **Infrastructure & QA Hardening**
  - Update `offers.tf` to provision SNS topics (`offers.submitted`, `offers.cancelled`), EventBridge rules routing to Auctions, Datadog monitors, and Redis replication group sized for 99p < 5ms latency.
  - Expand CI workflow `offers_checks.yaml` to run unit tests, contract tests against ephemeral Serverpod, and Pact verification for external partners.
  - Add load test profile `offers_locustfile.py` (CI artifact) to simulate 200 RPS offer submissions ensuring idempotency and latency budgets.
6. **Observability & Runbooks**
  - Emit structured logs with `submission_trace_id`, buyer risk metadata, and rule evaluation summaries; aggregate in Kibana index `offers-submission-*` with retention policy aligned to compliance.
  - Document escalation procedures in `docs/runbooks/offers-submission.md`, linking Datadog monitors and Slack channels for on-call rotations.
  - Update `docs/analytics/offers-dashboard.md` with new widgets tied to metrics defined below.

### Monitoring & Analytics
- **Datadog Metrics:** `offers.validation.duration_ms` (p95 ≤ 400ms), `offers.submission.success_rate` (target ≥ 98%), `offers.cancellation.success_rate` (target ≥ 95%), `offers.auction_trigger.lag_ms` (target ≤ 1000ms), `offers.risk_check.duration_ms` (p95 ≤ 600ms).
- **Segment Events:** `offer_draft_started`, `offer_validation_failed`, `offer_submitted`, `offer_auto_rejected`, `offer_cancelled`, `auction_triggered_from_offer`, all enriched with `submission_trace_id` and rule outcome metadata.
- **Kibana Dashboards:** `offers-submission-overview` for structured logs, `offers-risk-review` for Sift score distributions, with anomaly detection thresholds mirroring Datadog alerts.
- **Alerting:** EventBridge rule `offers-validation-alerts` posts to Slack `#eng-offers` on validation duration p95 > 500ms (5-minute window); PagerDuty service `Offers Submission` pages when success rate < 95% for 10 minutes; Opsgenie email alerts when auction trigger lag > 2s.
- **Health & QA Checks:** Synthetic flow hitting validation → submission → cancellation nightly; CI smoke test verifying Stripe, Sift, Plaid sandbox availability with SLA dashboards in Datadog.

### Environment Configuration
```yaml
offers_service:
  IDEMPOTENCY_WINDOW_SECONDS: 300
  OFFER_MODIFICATION_WINDOW_MINUTES: 5
  MAX_OFFERS_PER_STORY: 3
  DEFAULT_MINIMUM_OFFER_MINOR_UNITS: 500000   # $5,000 default floor expressed in cents
  OFFER_SUBMISSION_QUEUE: "commerce-offers-events@2025-09"
  SUBMISSION_TRACE_HEADER: "x-offer-trace-id"
  RISK_SCORE_REJECTION_THRESHOLD: 72

integrations:
  STRIPE_CONNECT_API_VERSION: "2024-10-15"
  SIFT_DECISION_API_VERSION: "v206"
  PLAID_IDENTITY_API_VERSION: "2024-08-01"
  STRIPE_WEBHOOK_SECRET: "op://commerce/stripe/WEBHOOK_SECRET"
  SIFT_API_KEY: "op://commerce/sift/API_KEY"
  PLAID_CLIENT_ID: "op://commerce/plaid/CLIENT_ID"

infrastructure:
  POSTGRES_URL: "postgresql://offers_writer:${OFFERS_DB_PASSWORD}@${OFFERS_DB_HOST}:5432/offers"
  REDIS_URL: "rediss://offers-cache.${REGION}.amazonaws.com:6379"
  SNS_TOPIC_OFFERS_SUBMITTED: "arn:aws:sns:${REGION}:${ACCOUNT}:offers-submitted"
  SNS_TOPIC_OFFERS_CANCELLED: "arn:aws:sns:${REGION}:${ACCOUNT}:offers-cancelled"
  GLACIER_VAULT: "offers-audit-${ENV}"

observability:
  DATADOG_DASHBOARD: "offers-submission-overview"
  DATADOG_MONITOR_SLO_ID: "slo:offers-submission"
  SEGMENT_WRITE_KEY: "op://video-window-commerce/segment/WRITE_KEY"
  SLACK_ALERT_CHANNEL: "#eng-offers"
  RUNBOOK_URL: "https://docs.craft.video/runbooks/offers-submission"
```

### Test Traceability
| Story | Acceptance Criteria | Automated Coverage |
| ----- | ------------------- | ------------------ |
| 9.1 Offer Entry UI & Validation | AC1 real-time rule feedback, AC2 currency/limit enforcement, AC3 rate limiting | Flutter widget tests in `offer_submission_page_test.dart`, bloc unit tests `offer_bloc_test.dart`, repository tests `offers_validation_service_test.dart` |
| 9.2 Server Validation & Auction Trigger | AC1 OPA policy compliance, AC2 idempotent submission, AC3 auction trigger fire | Server unit tests `offer_validation_service_test.dart`, endpoint tests `offer_validation_endpoint_test.dart` & `offer_submit_endpoint_test.dart`, contract tests `offers_contract_test.dart` |
| 9.3 Offer Withdrawal & Cancellation | AC1 modification window enforcement, AC2 audit append, AC3 maker notification | Bloc tests `offer_cancellation_bloc_test.dart`, endpoint tests `offer_cancel_endpoint_test.dart`, SNS integration test `offers_notification_contract_test.dart` |
| 9.4 Offer State Management & Audit Trail | AC1 history pagination, AC2 immutable audit storage, AC3 export pipeline | Endpoint tests `offer_history_endpoint_test.dart`, service tests `offer_audit_service_test.dart`, Terraform integration test `offers_terraform_test.dart` |

## Data Models

### Offer Entity
```dart
class Offer {
  final String id;
  final String storyId;
  final String buyerId;
  final Money amount;
  final String currency;
  final String? note;
  final DateTime createdAt;
  final OfferStatus status;
  final bool isOpening;
  final OfferSource source;
  final DateTime? updatedAt;
  final String? rejectionReason;
}

enum OfferStatus {
  pending,        // Initial state, awaiting maker review
  autoRejected,   // Below minimum threshold
  rejected,       // Rejected by maker
  accepted,       // Accepted by maker (becomes opening bid)
  superseded      // Superseded by higher offer
}

enum OfferSource {
  offer,          // Direct offer submission
  bid             // Bid during active auction
}
```

### Maker Profile Entity
```dart
class MakerProfile {
  final String id;
  final String userId;
  final OfferPolicy offerPolicy;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class OfferPolicy {
  final Money autoRejectBelowAmount;
  final String currency;
  final bool enabled;
  final int maxOffersPerStory;
  final Duration offerReviewWindow;
}
```

### Offer Validation Request/Response
```dart
class OfferValidationRequest {
  final String storyId;
  final Money amount;
  final String currency;
  final String? note;
}

class OfferValidationResponse {
  final bool isValid;
  final List<ValidationError> errors;
  final Money? minimumAmount;
  final String? currency;
  final OfferEligibility eligibility;
  final BusinessRuleConstraints constraints;
}

class ValidationError {
  final String code;
  final String message;
  final ValidationSeverity severity;
}

class OfferEligibility {
  final bool isAuthenticated;
  final bool hasPaymentMethod;
  final bool storyEligible;
  final bool geographicAllowed;
  final bool makerAcceptingOffers;
  final String? ineligibilityReason;
}

class BusinessRuleConstraints {
  final Money minimumAmount;
  final Money maximumAmount;
  final int maxOffersPerUser;
  final Duration modificationWindow;
  final bool cancellable;
}
```

## API Endpoints

### Offer Management Endpoints
```
POST /offers/validation/{storyId}
POST /offers/submit
PUT /offers/{offerId}/cancel
POST /offers/{offerId}/modify
GET /offers/{offerId}/history
GET /stories/{storyId}/offers
```

### Endpoint Specifications

#### Validate Offer Eligibility
```dart
// Request: GET /offers/validation/{storyId}?amount=10000&currency=USD

// Response
{
  "isValid": true,
  "errors": [],
  "minimumAmount": 5000,
  "currency": "USD",
  "eligibility": {
    "isAuthenticated": true,
    "hasPaymentMethod": true,
    "storyEligible": true,
    "geographicAllowed": true,
    "makerAcceptingOffers": true
  },
  "constraints": {
    "minimumAmount": 5000,
    "maximumAmount": 500000,
    "maxOffersPerUser": 3,
    "modificationWindow": "PT5M",
    "cancellable": true
  }
}
```

#### Submit Offer
```dart
// Request: POST /offers/submit
{
  "storyId": "story_123",
  "amount": 7500,
  "currency": "USD",
  "note": "I love this piece! Would you consider...",
  "deviceInfo": "iPhone 15 Pro",
  "idempotencyKey": "offer_sub_123456"
}

// Response: 201 Created
{
  "id": "offer_789",
  "storyId": "story_123",
  "buyerId": "user_456",
  "amount": 7500,
  "currency": "USD",
  "status": "pending",
  "isOpening": true,
  "source": "offer",
  "createdAt": "2025-10-09T14:30:00Z",
  "auctionId": "auction_101"
}
```

#### Cancel Offer
```dart
// Request: PUT /offers/{offerId}/cancel
{
  "reason": "buyer_withdrew",
  "deviceInfo": "iPhone 15 Pro"
}

// Response: 200 OK
{
  "id": "offer_789",
  "status": "cancelled",
  "cancelledAt": "2025-10-09T14:35:00Z",
  "cancellationReason": "buyer_withdrew"
}
```

## Implementation Details

### Flutter Commerce Module Structure

#### Offer Submission Flow
1. **Pre-validation:** Check user authentication, payment method, story eligibility
2. **Real-time Validation:** Input validation against business rules with instant feedback
3. **Confirmation:** Clear terms, fee disclosure, maker notification setup
4. **Submission:** Atomic offer creation with audit trail
5. **Post-submission:** Real-time updates, maker alerts, auction trigger

#### State Management (BLoC)
```dart
// Offer Events
abstract class OfferEvent {}
class OfferValidationRequested extends OfferEvent {
  final String storyId;
  final Money amount;
  final String currency;
}
class OfferSubmitted extends OfferEvent {
  final String storyId;
  final Money amount;
  final String currency;
  final String? note;
}
class OfferCancelled extends OfferEvent {
  final String offerId;
  final String reason;
}
class OfferModified extends OfferEvent {
  final String offerId;
  final Money newAmount;
}

// Offer States
abstract class OfferState {}
class OfferInitial extends OfferState {}
class OfferValidationInProgress extends OfferState {}
class OfferValidationSuccess extends OfferState {
  final OfferValidationResponse validation;
}
class OfferValidationFailure extends OfferState {
  final List<ValidationError> errors;
}
class OfferSubmissionInProgress extends OfferState {}
class OfferSubmissionSuccess extends OfferState {
  final Offer offer;
}
class OfferSubmissionFailure extends OfferState {
  final String error;
  final bool retryable;
}
```

#### Offer Submission UI
```dart
class OfferSubmissionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OfferBloc(
        offersRepository: context.read<OffersRepository>(),
        validationRepository: context.read<ValidationRepository>(),
      ),
      child: OfferSubmissionForm(),
    );
  }
}

class OfferSubmissionForm extends StatefulWidget {
  @override
  _OfferSubmissionFormState createState() => _OfferSubmissionFormState();
}

class _OfferSubmissionFormState extends State<OfferSubmissionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfferBloc, OfferState>(
      listener: (context, state) {
        if (state is OfferSubmissionSuccess) {
          _showOfferSubmittedDialog(context, state.offer);
        } else if (state is OfferSubmissionFailure) {
          _showErrorSnackbar(context, state.error);
        }
      },
      child: BlocBuilder<OfferBloc, OfferState>(
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Offer Amount',
                    prefixText: '\$',
                    errorText: state is OfferValidationFailure
                        ? state.errors.first.message
                        : null,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an offer amount';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final amount = Money.fromDouble(double.tryParse(value) ?? 0);
                    context.read<OfferBloc>().add(
                      OfferValidationRequested(
                        storyId: widget.storyId,
                        amount: amount,
                        currency: 'USD',
                      ),
                    );
                  },
                ),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional)',
                    hintText: 'Add a personal message...',
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
                if (state is OfferValidationSuccess) ...[
                  OfferSummaryWidget(validation: state.validation),
                ],
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: state is OfferValidationSuccess && state.validation.isValid
                      ? () => _submitOffer()
                      : null,
                  child: state is OfferSubmissionInProgress
                      ? CircularProgressIndicator()
                      : Text('Submit Offer'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submitOffer() {
    if (_formKey.currentState!.validate()) {
      final amount = Money.fromDouble(double.parse(_amountController.text));
      context.read<OfferBloc>().add(
        OfferSubmitted(
          storyId: widget.storyId,
          amount: amount,
          currency: 'USD',
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        ),
      );
    }
  }
}
```

### Serverpod Offers Service

#### Offer Validation Service
```dart
class OfferValidationService {
  final UserRepository _userRepository;
  final MakerProfileRepository _makerProfileRepository;
  final StoryRepository _storyRepository;
  final PaymentService _paymentService;
  final GeographicService _geographicService;

  Future<OfferValidationResponse> validateOffer(
    String userId,
    String storyId,
    Money amount,
    String currency,
  ) async {
    final errors = <ValidationError>[];

    // 1. User Authentication Check
    final user = await _userRepository.findById(userId);
    if (user == null || !user.isActive) {
      errors.add(ValidationError(
        code: 'USER_NOT_AUTHENTICATED',
        message: 'User must be authenticated to submit offers',
        severity: ValidationSeverity.error,
      ));
      return OfferValidationResponse(
        isValid: false,
        errors: errors,
        eligibility: OfferEligibility(
          isAuthenticated: false,
          hasPaymentMethod: false,
          storyEligible: false,
          geographicAllowed: false,
          makerAcceptingOffers: false,
          ineligibilityReason: 'User not authenticated',
        ),
        constraints: BusinessRuleConstraints(),
      );
    }

    // 2. Payment Method Verification
    final hasPaymentMethod = await _paymentService.hasValidPaymentMethod(userId);
    if (!hasPaymentMethod) {
      errors.add(ValidationError(
        code: 'NO_PAYMENT_METHOD',
        message: 'A valid payment method is required to submit offers',
        severity: ValidationSeverity.error,
      ));
    }

    // 3. Story Eligibility Validation
    final story = await _storyRepository.findById(storyId);
    if (story == null || story.status != StoryStatus.listed) {
      errors.add(ValidationError(
        code: 'STORY_NOT_ELIGIBLE',
        message: 'This story is not currently accepting offers',
        severity: ValidationSeverity.error,
      ));
    }

    // 4. Maker Policy Validation
    final makerProfile = await _makerProfileRepository.findByUserId(story.makerId);
    if (makerProfile == null || !makerProfile.offerPolicy.enabled) {
      errors.add(ValidationError(
        code: 'MAKER_NOT_ACCEPTING_OFFERS',
        message: 'This maker is not currently accepting offers',
        severity: ValidationSeverity.error,
      ));
    }

    // 5. Geographic Restriction Check
    final geographicAllowed = await _geographicService.isBuyerEligible(
      userId,
      storyId,
    );
    if (!geographicAllowed) {
      errors.add(ValidationError(
        code: 'GEOGRAPHIC_RESTRICTION',
        message: 'Offers are not available in your location',
        severity: ValidationSeverity.error,
      ));
    }

    // 6. Minimum Threshold Validation
    final minimumAmount = makerProfile?.offerPolicy.autoRejectBelowAmount ?? Money(0);
    if (amount < minimumAmount) {
      errors.add(ValidationError(
        code: 'BELOW_MINIMUM_THRESHOLD',
        message: 'Offer must be at least ${minimumAmount.toString()}',
        severity: ValidationSeverity.error,
      ));
    }

    // 7. Offer Limit Validation
    final existingOffers = await _offerRepository.countByUserAndStory(userId, storyId);
    final maxOffers = makerProfile?.offerPolicy.maxOffersPerStory ?? 3;
    if (existingOffers >= maxOffers) {
      errors.add(ValidationError(
        code: 'OFFER_LIMIT_EXCEEDED',
        message: 'You have reached the maximum number of offers for this story',
        severity: ValidationSeverity.error,
      ));
    }

    final isValid = errors.isEmpty;

    return OfferValidationResponse(
      isValid: isValid,
      errors: errors,
      minimumAmount: minimumAmount,
      currency: currency,
      eligibility: OfferEligibility(
        isAuthenticated: true,
        hasPaymentMethod: hasPaymentMethod,
        storyEligible: story?.status == StoryStatus.listed,
        geographicAllowed: geographicAllowed,
        makerAcceptingOffers: makerProfile?.offerPolicy.enabled ?? false,
      ),
      constraints: BusinessRuleConstraints(
        minimumAmount: minimumAmount,
        maximumAmount: Money(500000), // Business rule
        maxOffersPerUser: maxOffers,
        modificationWindow: Duration(minutes: 5),
        cancellable: true,
      ),
    );
  }
}
```

#### Offer Submission Service
```dart
class OfferSubmissionService {
  final OfferRepository _offerRepository;
  final AuctionService _auctionService;
  final NotificationService _notificationService;
  final AuditService _auditService;
  final ValidationService _validationService;

  @Transactional
  Future<Offer> submitOffer(
    String userId,
    String storyId,
    Money amount,
    String currency,
    String? note,
    String deviceInfo,
    String idempotencyKey,
  ) async {
    // 1. Check for duplicate submission using idempotency key
    final existingOffer = await _offerRepository.findByIdempotencyKey(idempotencyKey);
    if (existingOffer != null) {
      return existingOffer;
    }

    // 2. Validate offer
    final validation = await _validationService.validateOffer(
      userId,
      storyId,
      amount,
      currency,
    );

    if (!validation.isValid) {
      throw OfferValidationException(validation.errors);
    }

    // 3. Create offer
    final offer = await _offerRepository.create(
      Offer(
        id: generateId(),
        storyId: storyId,
        buyerId: userId,
        amount: amount,
        currency: currency,
        note: note,
        status: OfferStatus.pending,
        isOpening: false,
        source: OfferSource.offer,
        createdAt: DateTime.now().toUtc(),
        idempotencyKey: idempotencyKey,
      ),
    );

    // 4. Check if this is the first offer and should open auction
    final existingOffers = await _offerRepository.findByStoryId(storyId);
    final isFirstOffer = existingOffers.length == 1;

    if (isFirstOffer) {
      // 5. Create auction
      final auction = await _auctionService.createAuctionFromOffer(offer);

      // 6. Update offer as opening bid
      await _offerRepository.updateStatus(offer.id, OfferStatus.accepted);
      await _offerRepository.markAsOpening(offer.id);

      // 7. Emit auction opened event
      await _emitAuctionOpenedEvent(auction, offer);
    } else {
      // 8. Check for auto-rejection
      final makerProfile = await _makerProfileRepository.findByStoryId(storyId);
      if (makerProfile != null && amount < makerProfile.offerPolicy.autoRejectBelowAmount) {
        await _offerRepository.updateStatus(offer.id, OfferStatus.autoRejected);
        await _emitOfferAutoRejectedEvent(offer, makerProfile.offerPolicy.autoRejectBelowAmount);
      } else {
        // 9. Send notification to maker
        await _notificationService.sendNewOfferNotification(offer);
      }
    }

    // 10. Create audit trail
    await _auditService.logOfferSubmission(offer, deviceInfo);

    // 11. Emit offer submitted event
    await _emitOfferSubmittedEvent(offer);

    return offer;
  }

  Future<void> cancelOffer(
    String offerId,
    String userId,
    String reason,
    String deviceInfo,
  ) async {
    final offer = await _offerRepository.findById(offerId);
    if (offer == null) {
      throw OfferNotFoundException(offerId);
    }

    if (offer.buyerId != userId) {
      throw UnauthorizedException('Only the offer creator can cancel their offer');
    }

    // Business rule: Can only cancel pending offers within 5 minutes
    if (offer.status != OfferStatus.pending) {
      throw OfferNotCancellableException(offer.status);
    }

    final timeSinceCreation = DateTime.now().toUtc().difference(offer.createdAt);
    if (timeSinceCreation > Duration(minutes: 5)) {
      throw OfferModificationWindowExpiredException();
    }

    // Cancel the offer
    await _offerRepository.updateStatus(offerId, OfferStatus.cancelled);

    // Create audit trail
    await _auditService.logOfferCancellation(offer, reason, deviceInfo);

    // Emit offer cancelled event
    await _emitOfferCancelledEvent(offer, reason);
  }
}
```

## Business Logic Validation

### Offer Qualification Engine
```dart
class OfferQualificationEngine {
  Future<QualificationResult> checkQualification(
    String userId,
    String storyId,
    Money amount,
  ) async {
    final checks = [
      _checkAuthentication(userId),
      _checkPaymentMethod(userId),
      _checkStoryEligibility(storyId),
      _checkGeographicRestrictions(userId, storyId),
      _checkMakerPolicy(storyId),
      _checkOfferLimits(userId, storyId),
      _checkMinimumThreshold(storyId, amount),
      _checkTimeRestrictions(storyId),
      _checkDuplicateOffers(userId, storyId, amount),
    ];

    final results = await Future.wait(checks);
    final failures = results.whereType<QualificationFailure>().toList();

    return QualificationResult(
      isQualified: failures.isEmpty,
      failures: failures,
    );
  }

  Future<QualificationResult> _checkAuthentication(String userId) async {
    final user = await _userRepository.findById(userId);
    if (user == null || !user.isActive) {
      return QualificationFailure(
        code: 'USER_NOT_AUTHENTICATED',
        message: 'User must be authenticated and active',
        isBlocking: true,
      );
    }
    return QualificationSuccess();
  }

  Future<QualificationResult> _checkPaymentMethod(String userId) async {
    final hasValidPayment = await _paymentService.hasValidPaymentMethod(userId);
    if (!hasValidPayment) {
      return QualificationFailure(
        code: 'NO_PAYMENT_METHOD',
        message: 'Valid payment method required',
        isBlocking: true,
      );
    }
    return QualificationSuccess();
  }

  Future<QualificationResult> _checkStoryEligibility(String storyId) async {
    final story = await _storyRepository.findById(storyId);
    if (story == null || story.status != StoryStatus.listed) {
      return QualificationFailure(
        code: 'STORY_NOT_ELIGIBLE',
        message: 'Story not accepting offers',
        isBlocking: true,
      );
    }
    return QualificationSuccess();
  }

  Future<QualificationResult> _checkMinimumThreshold(
    String storyId,
    Money amount,
  ) async {
    final makerProfile = await _makerProfileRepository.findByStoryId(storyId);
    final minimum = makerProfile?.offerPolicy.autoRejectBelowAmount ?? Money(0);

    if (amount < minimum) {
      return QualificationFailure(
        code: 'BELOW_MINIMUM_THRESHOLD',
        message: 'Offer below minimum threshold',
        isBlocking: true,
        details: {'minimum': minimum.toString()},
      );
    }
    return QualificationSuccess();
  }
}
```

### State Machine Implementation
```dart
class OfferStateMachine {
  final Map<OfferStatus, Set<OfferStatus>> _validTransitions = {
    OfferStatus.pending: {
      OfferStatus.accepted,
      OfferStatus.rejected,
      OfferStatus.autoRejected,
      OfferStatus.cancelled,
      OfferStatus.superseded,
    },
    OfferStatus.accepted: {
      OfferStatus.superseded,
    },
    OfferStatus.rejected: {}, // Terminal state
    OfferStatus.autoRejected: {}, // Terminal state
    OfferStatus.cancelled: {}, // Terminal state
    OfferStatus.superseded: {}, // Terminal state
  };

  Future<void> transition(
    String offerId,
    OfferStatus newStatus,
    String? reason,
    String? userId,
  ) async {
    final offer = await _offerRepository.findById(offerId);
    if (offer == null) {
      throw OfferNotFoundException(offerId);
    }

    final validStatuses = _validTransitions[offer.status] ?? <OfferStatus>{};
    if (!validStatuses.contains(newStatus)) {
      throw InvalidTransitionException(
        offer.status,
        newStatus,
      );
    }

    // Perform state transition
    await _offerRepository.updateStatus(offerId, newStatus);

    // Create audit trail
    await _auditService.logStateTransition(
      offerId,
      offer.status,
      newStatus,
      reason,
      userId,
    );

    // Emit state change event
    await _emitOfferStateChangeEvent(offer, newStatus, reason);

    // Handle side effects
    await _handleTransitionSideEffects(offer, newStatus);
  }

  Future<void> _handleTransitionSideEffects(
    Offer offer,
    OfferStatus newStatus,
  ) async {
    switch (newStatus) {
      case OfferStatus.accepted:
        if (offer.isOpening) {
          await _auctionService.createAuctionFromOffer(offer);
          await _notificationService.sendAuctionOpenedNotification(offer);
        }
        break;
      case OfferStatus.autoRejected:
        await _notificationService.sendOfferRejectedNotification(offer);
        break;
      case OfferStatus.rejected:
        await _notificationService.sendOfferRejectedNotification(offer);
        break;
      case OfferStatus.superseded:
        await _notificationService.sendOfferSupersededNotification(offer);
        break;
    }
  }
}
```

## Analytics and Tracking

### Offer Funnel Events
```dart
class OfferAnalyticsService {
  void trackOfferOpened(String storyId) {
    Analytics.track('offer_opened', {
      'story_id': storyId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void trackOfferSubmitted(
    String storyId,
    Money amount,
    String currency,
    String? note,
    bool hasNote,
  ) {
    Analytics.track('offer_submitted', {
      'story_id': storyId,
      'amount': amount.minorUnits,
      'currency': currency,
      'note_present': hasNote,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void trackOfferAutoRejected(
    String storyId,
    Money amount,
    Money threshold,
  ) {
    Analytics.track('offer_auto_rejected', {
      'story_id': storyId,
      'amount': amount.minorUnits,
      'threshold': threshold.minorUnits,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void trackOfferValidationFailed(
    String storyId,
    List<ValidationError> errors,
  ) {
    Analytics.track('offer_validation_failed', {
      'story_id': storyId,
      'error_codes': errors.map((e) => e.code).toList(),
      'error_count': errors.length,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void trackOfferCancelled(String offerId, String reason) {
    Analytics.track('offer_cancelled', {
      'offer_id': offerId,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void trackOfferModified(String offerId, Money oldAmount, Money newAmount) {
    Analytics.track('offer_modified', {
      'offer_id': offerId,
      'old_amount': oldAmount.minorUnits,
      'new_amount': newAmount.minorUnits,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

## Testing Strategy

### Unit Tests
- **OfferValidationService:** Test all qualification checks and business rules
- **OfferSubmissionService:** Test offer creation, auction triggering, and idempotency
- **OfferStateMachine:** Test all valid/invalid state transitions
- **BLoC Tests:** Test all state transitions and error scenarios
- **Business Logic:** Test edge cases, boundary conditions, and error paths

### Integration Tests
- **Offer Flow:** End-to-end offer submission with database
- **Auction Integration:** Test auction creation from first valid offer
- **Notification System:** Test maker notifications on new offers
- **Event Emission:** Test analytics events for all offer scenarios
- **Validation Chain:** Test complete validation pipeline

### Business Logic Tests
```dart
// Example business logic test
test('should reject offer below minimum threshold', () async {
  // Arrange
  final makerProfile = MakerProfile(
    id: 'maker_1',
    userId: 'user_1',
    offerPolicy: OfferPolicy(
      autoRejectBelowAmount: Money.fromDouble(100),
      currency: 'USD',
      enabled: true,
      maxOffersPerStory: 3,
      offerReviewWindow: Duration(hours: 24),
    ),
  );

  // Act
  final result = await qualificationEngine.checkQualification(
    'buyer_1',
    'story_1',
    Money.fromDouble(50), // Below minimum
  );

  // Assert
  expect(result.isQualified, false);
  expect(result.failures.first.code, 'BELOW_MINIMUM_THRESHOLD');
});

test('should create auction on first valid offer', () async {
  // Arrange
  final offer = Offer(
    id: 'offer_1',
    storyId: 'story_1',
    buyerId: 'buyer_1',
    amount: Money.fromDouble(200),
    currency: 'USD',
    status: OfferStatus.pending,
    isOpening: false,
    source: OfferSource.offer,
    createdAt: DateTime.now().toUtc(),
  );

  // Act
  final result = await offerSubmissionService.submitOffer(
    offer.buyerId,
    offer.storyId,
    offer.amount,
    offer.currency,
    null,
    'iPhone 15 Pro',
    'idemp_123',
  );

  // Assert
  expect(result.status, OfferStatus.accepted);
  expect(result.isOpening, true);

  final auction = await auctionRepository.findByStoryId('story_1');
  expect(auction, isNotNull);
  expect(auction!.status, AuctionStatus.open);
});
```

## Error Handling

### Error Types
```dart
abstract class OfferException implements Exception {
  final String message;
  final String code;
  final Map<String, dynamic>? details;
}

class OfferValidationException extends OfferException {
  final List<ValidationError> errors;

  OfferValidationException(this.errors)
      : super(
          message: 'Offer validation failed',
          code: 'VALIDATION_FAILED',
          details: {'errors': errors.map((e) => e.toJson()).toList()},
        );
}

class OfferNotCancellableException extends OfferException {
  OfferNotCancellableException(OfferStatus status)
      : super(
          message: 'Offer cannot be cancelled in current state: $status',
          code: 'OFFER_NOT_CANCELLABLE',
          details: {'status': status.toString()},
        );
}

class DuplicateOfferException extends OfferException {
  DuplicateOfferException(String offerId)
      : super(
          message: 'Duplicate offer detected',
          code: 'DUPLICATE_OFFER',
          details: {'existing_offer_id': offerId},
        );
}
```

### Error Recovery
- **Validation Errors:** Show detailed error messages with guidance
- **Network Failures:** Automatic retry with exponential backoff
- **State Conflicts:** Refresh data and provide retry option
- **Business Rule Violations:** Clear explanation and alternative actions

## Performance Considerations

### Client Optimizations
- **Debounced Validation:** Validate input with 300ms debounce
- **Cached Policies:** Cache maker policies for 5 minutes
- **Optimistic Updates:** Update UI immediately, rollback on failure
- **Background Sync:** Sync pending offers in background

### Server Optimizations
- **Database Indexes:** Strategic indexes on storyId, buyerId, status
- **Connection Pooling:** Efficient database connection management
- **Caching Layer:** Redis cache for frequently accessed data
- **Async Processing:** Non-blocking notification and analytics

### Database Schema
```sql
-- Offers table
CREATE TABLE offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES artifact_stories(id),
  buyer_id UUID NOT NULL REFERENCES users(id),
  amount_minor_units INTEGER NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  note TEXT,
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  is_opening BOOLEAN DEFAULT false,
  source VARCHAR(20) NOT NULL DEFAULT 'offer',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  cancelled_at TIMESTAMP WITH TIME ZONE,
  cancellation_reason TEXT,
  idempotency_key VARCHAR(255) UNIQUE,

  CONSTRAINT offers_amount_check CHECK (amount_minor_units > 0),
  CONSTRAINT offers_status_check CHECK (status IN (
    'pending', 'auto_rejected', 'rejected', 'accepted', 'superseded', 'cancelled'
  )),
  CONSTRAINT offers_source_check CHECK (source IN ('offer', 'bid'))
);

-- Indexes for performance
CREATE INDEX idx_offers_story_id ON offers(story_id);
CREATE INDEX idx_offers_buyer_id ON offers(buyer_id);
CREATE INDEX idx_offers_status ON offers(status);
CREATE INDEX idx_offers_created_at ON offers(created_at);
CREATE INDEX idx_offers_story_buyer ON offers(story_id, buyer_id);
CREATE UNIQUE INDEX idx_offers_idempotency ON offers(idempotency_key)
  WHERE idempotency_key IS NOT NULL;

-- Offer audit trail
CREATE TABLE offer_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  offer_id UUID NOT NULL REFERENCES offers(id),
  old_status VARCHAR(50),
  new_status VARCHAR(50) NOT NULL,
  reason TEXT,
  user_id UUID REFERENCES users(id),
  device_info JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_offer_audit_offer_id ON offer_audit_log(offer_id);
CREATE INDEX idx_offer_audit_created_at ON offer_audit_log(created_at);
```

## Security Implementation

### Validation Security
- **Server-side Validation:** All business rules enforced on server
- **Authentication Required:** All endpoints require valid session
- **Rate Limiting:** 3 offers per story per user, 10 offers per hour
- **Input Sanitization:** All inputs sanitized and validated

### Audit Trail
- **Comprehensive Logging:** All state changes logged with user context
- **Immutable Records:** Audit records cannot be modified
- **Chain of Custody:** Complete history of offer lifecycle
- **Compliance Reporting:** Export capabilities for regulatory requirements

## Deployment Considerations
### Feature Flags
- `OFFER_SUBMISSION_ENABLED`: Enable/disable offer submission
- `REAL_TIME_VALIDATION`: Enable client-side validation
- `ADVANCED_ANALYTICS`: Enable detailed analytics tracking
- `SOFT_LAUNCH_MODE`: Enable soft launch with limited functionality

### Database Migrations
```sql
-- Migration: Create offers table
CREATE TABLE offers (...);

-- Migration: Add offer policies to maker profiles
ALTER TABLE maker_profiles ADD COLUMN offer_policy JSONB;

-- Migration: Create audit log table
CREATE TABLE offer_audit_log (...);

-- Migration: Add indexes for performance
CREATE INDEX CONCURRENTLY idx_offers_composite ON offers(story_id, status, created_at);
```

## Success Criteria

### Functional Requirements
- ✅ Users can submit offers with real-time validation
- ✅ Business rules enforced consistently across all entry points
- ✅ Automatic auction creation on first valid offer
- ✅ Comprehensive audit trail for all offer activities
- ✅ Maker notifications for new offers
- ✅ Offer cancellation and modification within business rules

### Non-Functional Requirements
- ✅ Offer validation completes within 500ms
- ✅ Offer submission completes within 2 seconds
- ✅ 99.9% uptime for offer submission service
- ✅ Complete audit trail with immutable records
- ✅ Comprehensive analytics tracking
- ✅ Rate limiting and abuse prevention

### Success Metrics
- Offer submission success rate > 98%
- Average validation time < 500ms
- Audit trail completeness = 100%
- Zero data loss in offer processing
- User satisfaction score > 4.5/5

## Next Steps

1. **Implement Offer Validation Service** - All qualification checks and business rules
2. **Develop Offer Submission Service** - Atomic operations with audit trail
3. **Create Flutter Commerce Module** - UI components and state management
4. **Integrate with Auction System** - Event-driven architecture
5. **Implement Analytics Tracking** - Comprehensive event emission
6. **Comprehensive Testing** - Unit, integration, and business logic tests

**Dependencies:** Epic 1 (Viewer Authentication), Epic F2 (Core Platform Services)
**Blocks:** Epic 10 (Auction Timer) requires offer submission foundation for auction triggering

## Change Log
| Date       | Version | Description                                                                                     | Author            |
| ---------- | ------- | ------------------------------------------------------------------------------------------------- | ----------------- |
| 2025-10-29 | v0.5    | Promoted to definitive: pinned stack, source directives, implementation guide, monitoring, env config, traceability | GitHub Copilot AI |

---
*This technical specification defines the definitive implementation plan for the Offer Submission flow and must be updated alongside corresponding stories, runbooks, and validation artifacts.*