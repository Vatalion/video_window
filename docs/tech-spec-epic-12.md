# Epic 12: Checkout & Payment Processing - Technical Specification

**Epic Goal:** Integrate Stripe Checkout for secure payment processing with 24-hour payment window enforcement, retry mechanisms, and comprehensive receipt generation.

**Stories:**
- 12.1: Stripe Checkout Integration
- 12.2: Payment Window Enforcement
- 12.3: Payment Retry Mechanisms
- 12.4: Receipt Generation and Storage

## Architecture Overview

### Component Mapping
- **Flutter App:** Payment Module (checkout launcher, payment status, countdown timer)
- **Serverpod:** Payment Service (Stripe integration, webhook handling, session management)
- **Database:** PaymentSessions, Orders, Transactions tables
- **External:** Stripe Connect Express (hosted checkout, payouts, compliance)

### Technology Stack
- **Flutter SDK & Packages:** Flutter 3.19.6, Dart 3.5.6, `flutter_bloc` 9.1.0, `flutter_stripe` 10.1.0, `webview_flutter` 4.7.0, `equatable` 2.0.5, `intl` 0.19.0, `uni_links` 0.5.1 for return URL handling, `flutter_secure_storage` 9.2.1 for token persistence, `sentry_flutter` 8.4.0 for crash breadcrumbs.
- **Client Networking & Timing:** `dio` 5.4.2 for REST fallbacks, `retry` 3.1.2 for status polling backoff, `clock` 1.1.1 for deterministic countdown timers, `rxdart` 0.27.7 for countdown stream throttling.
- **Server Platform:** Serverpod 2.9.2, `stripe` 8.0.0 (server-side Stripe SDK), `postgres` 3.2.0 for transactional storage, `redis_client` 3.3.0 (Redis 7.2.4 cluster) for window tracking, `aws_sqs_api` 2.0.0 for retry queue integration, `serverpod_cloud` 2.9.2 for scheduled tasks.
- **Documents & Storage:** AWS S3 (bucket `craft-video-receipts-${ENV}` with Object Lock), `pdfx` 2.6.0 for receipt rendering, AWS KMS CMK `payments-receipts` for envelope encryption, CloudFront signed URLs for receipt delivery.
- **Infrastructure & Scheduling:** AWS EventBridge Scheduler 2025.09 to trigger payment window expirations, AWS Step Functions 2025.10 orchestrating retry workflows, AWS SNS 2025.08 for buyer/maker payment notifications, Terraform 1.8.5 modules under `infrastructure/terraform/payments`.
- **Observability:** Datadog Agent 7.53.0 with metrics namespace `payments.checkout.*`, Datadog Logs pipeline `payments-stripe`, Kibana 8.14 index `payments-*`, PagerDuty service `Payments Checkout`, Segment workspace `commerce.payments` capturing analytics events, Opsgenie escalation for webhook failures.
- **Secrets & Compliance:** HashiCorp Vault 1.15.3 (Stripe webhook secret, receipt signing keys), 1Password Connect 1.7.3 (Stripe API keys, Segment keys), Stripe Radar policy pack 2025-09, Vanta SOC2 evidence hooks for payment events.

### Source Tree & File Directives
```text
video_window_flutter/
  packages/
    features/
      commerce/
        lib/
          presentation/
            pages/
              payment_checkout_page.dart           # Modify: embed Stripe launcher + countdown (Stories 12.1, 12.2)
              payment_status_page.dart             # Create: post-checkout status & retry CTA (Story 12.3)
            widgets/
              payment_window_timer.dart            # Create: accessible countdown widget (Story 12.2)
              payment_receipt_card.dart            # Create: show receipt summary + download (Story 12.4)
            bloc/
              payment_bloc.dart                    # Modify: orchestrate checkout + webhook status (Story 12.1)
              payment_window_bloc.dart             # Create: 24h window state machine (Story 12.2)
              payment_retry_bloc.dart              # Create: limited retry flow coordination (Story 12.3)
          use_cases/
            create_checkout_session_use_case.dart  # Create: idempotent checkout creation (Story 12.1)
            observe_payment_status_use_case.dart   # Modify: poll + subscribe for completion (Stories 12.1, 12.2)
            schedule_payment_retry_use_case.dart   # Create: queue retry attempt (Story 12.3)
            fetch_receipt_use_case.dart            # Create: retrieve signed receipt URL (Story 12.4)
    core/
      lib/
        data/
          repositories/
            payments_repository.dart               # Modify: checkout, window, retry, receipt APIs (Stories 12.1-12.4)
          services/
            stripe_checkout_service.dart           # Create: wraps client secret + ephemeral keys (Story 12.1)
            payment_window_service.dart            # Create: local countdown cache + drift correction (Story 12.2)
            receipt_storage_service.dart           # Create: manage signed download URLs (Story 12.4)
        telemetry/
          payments_metrics.dart                    # Create: Datadog + Segment emitters (Stories 12.3-12.4)

video_window_server/
  lib/
    src/
      endpoints/
        payments/
          payment_checkout_endpoint.dart          # Modify: Stripe session creation + metadata (Story 12.1)
          payment_window_endpoint.dart            # Create: expose window status + admin overrides (Story 12.2)
          payment_retry_endpoint.dart             # Create: restart payment attempt with limits (Story 12.3)
          payment_receipt_endpoint.dart           # Create: signed receipt delivery (Story 12.4)
      services/
        payments/
          stripe_service.dart                     # Modify: checkout + intent orchestration (Story 12.1)
          payment_window_service.dart             # Create: enforce 24h expiry via Redis + EventBridge (Story 12.2)
          payment_retry_service.dart              # Create: SQS retry queue + exponential backoff (Story 12.3)
          receipt_generation_service.dart         # Create: PDF render + S3 upload (Story 12.4)
      tasks/
        payment_window_task.dart                  # Create: EventBridge-triggered expiration worker (Story 12.2)
        payment_retry_worker.dart                 # Create: processes retry queue (Story 12.3)
      webhooks/
        stripe_checkout_webhook.dart              # Modify: handle completed/expired intents (Stories 12.1-12.3)
      repositories/
        payment_session_repository.dart           # Modify: window metadata + retries (Stories 12.2-12.3)
        receipt_repository.dart                   # Create: persist receipt ledger (Story 12.4)
      utils/
        webhook_signature_validator.dart          # Create: shared Stripe signature verification (Story 12.1)
        receipt_number_generator.dart             # Create: sequential numbering w/ prefix (Story 12.4)
    test/
      endpoints/payments/
        payment_checkout_endpoint_test.dart       # Create
        payment_window_endpoint_test.dart         # Create
        payment_retry_endpoint_test.dart          # Create
        payment_receipt_endpoint_test.dart        # Create
      services/payments/
        stripe_service_test.dart                  # Expand coverage for new flows
        payment_window_service_test.dart          # Create
        payment_retry_service_test.dart           # Create
        receipt_generation_service_test.dart      # Create
      webhooks/
        stripe_checkout_webhook_test.dart         # Create
      tasks/
        payment_window_task_test.dart             # Create
        payment_retry_worker_test.dart            # Create

infrastructure/
  terraform/
    payments.tf                                  # Modify: Stripe webhook endpoint, EventBridge rule, SQS queue
    payments_observability.tf                    # Create: Datadog monitors, CloudWatch alarms, SNS topics
  ci/
    payments_checks.yaml                         # Create: workflow for Stripe integration & drift tests

docs/
  analytics/
    stripe-payments-dashboard.md                 # Create: operational metrics specification (Monitoring §)
  runbooks/
    stripe-payments.md                           # Create: on-call response playbook (Implementation Guide §4)
```

### Implementation Guide
1. **Stripe Checkout Integration (Story 12.1)**
   - Implement `payment_checkout_endpoint.dart` to create Stripe Checkout Sessions with idempotency keys, metadata (`payment_session_id`, `auction_id`, `buyer_id`), and 24h expiry; persist via `payment_session_repository.dart` and update Stripe metadata.
   - Build `create_checkout_session_use_case.dart` and extend `payment_bloc.dart` to launch `payment_checkout_page.dart` and emit analytics (`payments.checkout.started`) through `payments_metrics.dart`.
   - Harden webhook handling in `stripe_checkout_webhook.dart` using `webhook_signature_validator.dart`, updating sessions and transactions, and logging to Datadog (`payments.checkout.session_completed`).
2. **Payment Window Enforcement (Story 12.2)**
   - Create `payment_window_task.dart` invoked by EventBridge `payments-window-expire-${ENV}` every 5 minutes to mark expired sessions, expire Stripe checkout objects, and publish SNS notifications.
   - Add `payment_window_service.dart` on server/client to compute remaining duration, backfill drift via Redis TTL (`payment:window:{sessionId}`), and expose status through `payment_window_endpoint.dart` for admin overrides.
   - Update `payment_window_bloc.dart` and `payment_window_timer.dart` to surface countdown with accessibility cues (WCAG 2.1 AA), pausing when user is offline and resyncing on reconnect.
3. **Payment Retry Mechanisms (Story 12.3)**
   - Provision SQS queue `payments-retry-${ENV}`; `payment_retry_service.dart` enqueues retry jobs with exponential backoff (1, 5, 15 minutes) and maximum 3 attempts, storing counters on `payment_session_repository.dart`.
   - Implement `payment_retry_worker.dart` to create new checkout sessions via `payment_retry_endpoint.dart` while preserving original metadata and raising Datadog event `payments.retry.initiated`.
   - Extend `payment_retry_bloc.dart` and `schedule_payment_retry_use_case.dart` to let users trigger retry within allowed window, gating by server-provided limits and showing audit in `payment_status_page.dart`.
4. **Receipt Generation & Storage (Story 12.4)**
   - Implement `receipt_generation_service.dart` using `pdfx` templates to render receipts, store them in S3 with KMS encryption, and persist metadata in `receipt_repository.dart` with sequential IDs via `receipt_number_generator.dart`.
   - Create `payment_receipt_endpoint.dart` returning signed CloudFront URLs and ensure `fetch_receipt_use_case.dart` caches metadata and invalidates after download.
   - Update `payments_metrics.dart` and Segment tracking to log `payments.receipt.generated` with receipt language/currency; document incident handling in `docs/runbooks/stripe-payments.md` and dashboards in `docs/analytics/stripe-payments-dashboard.md`.

### Monitoring & Analytics
- **Datadog Metrics:** `payments.checkout.sessions_active`, `payments.checkout.success_rate`, `payments.window.expired_count`, `payments.retry.attempt_count`, `payments.retry.failures`, `payments.receipt.render_time_ms`. Each monitor alerts Slack `#eng-commerce` when breaching defined thresholds (Monitoring Dashboard §3).
- **Logs & Dashboards:** Kibana index `payments-*` focuses on webhook processing latency, SQS retry backlog, and receipt generation errors. Dashboard definition lives in `docs/analytics/stripe-payments-dashboard.md` with widget-level guidance.
- **Alerts:** PagerDuty service `Payments Checkout` triggered when success rate < 97% over 15 minutes or webhook lag > 2 minutes; Opsgenie escalation handles receipt rendering failures > 5/min.
- **Analytics Events:** Segment events `payments.checkout.started`, `payments.checkout.completed`, `payments.checkout.expired`, `payments.retry.initiated`, `payments.receipt.generated` with properties (`payment_session_id`, `auction_id`, `amount_usd`, `retry_count`, `receipt_number`).
- **Synthetic Tests:** Nightly synthetic checkout from staging hitting Stripe test mode, verifying webhook handling and receipt generation; results exported to Datadog service checks `payments.synthetic.checkout`.

### Environment Configuration
```yaml
payment_service:
  STRIPE_SECRET_KEY: "op://video-window-commerce/stripe/SECRET_KEY"
  STRIPE_PUBLISHABLE_KEY: "op://video-window-commerce/stripe/PUBLISHABLE_KEY"
  STRIPE_WEBHOOK_SECRET: "vault://payments/stripe/webhook_secret"
  PAYMENT_WINDOW_MINUTES: 1440
  PAYMENT_RETRY_LIMIT: 3
  PAYMENT_RETRY_BACKOFF_MINUTES: [1, 5, 15]
  PAYMENT_RECEIPT_BUCKET: "craft-video-receipts-${ENV}"
  PAYMENT_RECEIPT_CLOUDFRONT_DISTRIBUTION: "d1234payments${ENV}.cloudfront.net"
  RECEIPT_TEMPLATE_VERSION: "2025-09-15"
  EVENTBRIDGE_SCHEDULE_ARN: "arn:aws:scheduler:${REGION}:${ACCOUNT}:schedule/payments-window-expire-${ENV}"
  SQS_RETRY_QUEUE_URL: "https://sqs.${REGION}.amazonaws.com/${ACCOUNT}/payments-retry-${ENV}"

integrations:
  DATADOG_API_KEY: "op://video-window-observability/datadog/API_KEY"
  SEGMENT_WRITE_KEY: "op://video-window-commerce/segment/PAYMENTS_WRITE_KEY"
  PAGERDUTY_SERVICE_ID: "PD_PAYMENTS_CHECKOUT"
  SLACK_ALERT_WEBHOOK: "op://video-window-ops/slack/PAYMENTS_ALERT_WEBHOOK"
  OPSGENIE_INTEGRATION_KEY: "vault://payments/opsgenie/integration_key"

security:
  STRIPE_SIGNING_PUBLIC_KEY: "vault://payments/stripe/rsa_public_key"
  RECEIPT_KMS_KEY_ARN: "arn:aws:kms:${REGION}:${ACCOUNT}:key/payments-receipts"
  REDIS_TLS_CERT: "vault://payments/redis/ca_cert"

client:
  PAYMENT_STATUS_POLL_SECONDS: 20
  PAYMENT_TIMER_SKEW_THRESHOLD_MS: 400
  CHECKOUT_RETURN_URL: "https://app.craftvideo.market/payments/return"
  CHECKOUT_CANCEL_URL: "https://app.craftvideo.market/payments/cancel"
  RECEIPT_CACHE_TTL_MINUTES: 60
```

### Test Traceability
| Story | Acceptance Criteria | Automated Coverage |
| ----- | ------------------- | ------------------ |
| 12.1 Stripe Checkout Integration | AC1 checkout session creation + metadata, AC2 webhook processing, AC3 client launch + analytics | Unit tests `stripe_service_test.dart`, endpoint tests `payment_checkout_endpoint_test.dart`, widget tests `payment_checkout_page_test.dart`, integration `stripe_checkout_webhook_test.dart` |
| 12.2 Payment Window Enforcement | AC1 expiration enforcement, AC2 countdown accuracy, AC3 admin override + notifications | Task tests `payment_window_task_test.dart`, service tests `payment_window_service_test.dart`, bloc/widget tests `payment_window_bloc_test.dart`, integration `payment_window_endpoint_test.dart` |
| 12.3 Payment Retry Mechanisms | AC1 retry eligibility gating, AC2 SQS enqueue + worker processing, AC3 analytics + alerts | Service tests `payment_retry_service_test.dart`, worker test `payment_retry_worker_test.dart`, bloc tests `payment_retry_bloc_test.dart`, infrastructure test `payments_retry_queue_integration_test.dart` |
| 12.4 Receipt Generation & Storage | AC1 PDF render + S3 upload, AC2 signed URL delivery, AC3 audit trail + metrics | Service tests `receipt_generation_service_test.dart`, endpoint tests `payment_receipt_endpoint_test.dart`, use case tests `fetch_receipt_use_case_test.dart`, synthetic `payments_receipt_smoke_test.dart` |

## Data Models

### Payment Session Entity
```dart
class PaymentSession {
  final String id;
  final String auctionId;
  final String buyerId;
  final String stripeCheckoutId;
  final Money amount;
  final DateTime expiresAt;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? stripePaymentIntentId;
  final Map<String, dynamic> metadata;
}

enum PaymentStatus {
  pending,        // Session created, waiting for payment
  processing,    // Payment submitted, processing
  completed,     // Payment successful
  failed,        // Payment failed
  expired,       // Payment window expired
  canceled       // Payment canceled
}
```

### Transaction Entity
```dart
class Transaction {
  final String id;
  final String paymentSessionId;
  final String stripePaymentIntentId;
  final Money amount;
  final Money? fees;
  final TransactionStatus status;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? processedAt;
}

enum TransactionStatus {
  pending,
  succeeded,
  failed,
  refunded,
  partially_refunded
}
```

### Payment Method Entity
```dart
class PaymentMethod {
  final String id;
  final String buyerId;
  final PaymentMethodType type;
  final String stripePaymentMethodId;
  final bool isDefault;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
}

enum PaymentMethodType {
  card,
  applePay,
  googlePay,
  bankTransfer
}
```

## API Endpoints

### Payment Management Endpoints
```
POST /payments/checkout/create
GET /payments/checkout/{sessionId}/status
POST /payments/checkout/{sessionId}/expire
POST /payments/webhooks/stripe
GET /payments/methods
POST /payments/retry/{sessionId}
```

### Endpoint Specifications

#### Create Checkout Session
```dart
// Request: POST /payments/checkout/create
{
  "auctionId": "uuid",
  "buyerId": "uuid",
  "amount": 275.50,
  "currency": "USD",
  "returnUrl": "https://app.craftmarketplace.com/payment/return",
  "cancelUrl": "https://app.craftmarketplace.com/payment/cancel"
}

// Response
{
  "paymentSession": {
    "id": "payment_session_uuid",
    "stripeCheckoutUrl": "https://checkout.stripe.com/pay/cs_test_...",
    "expiresAt": "2025-10-09T10:30:00Z",
    "status": "pending"
  },
  "paymentWindow": {
    "duration": "24:00:00",
    "expiresAt": "2025-10-09T10:30:00Z"
  }
}
```

#### Get Payment Status
```dart
// Request: GET /payments/checkout/{sessionId}/status

// Response
{
  "paymentSession": {
    "id": "payment_session_uuid",
    "status": "completed",
    "amount": 275.50,
    "currency": "USD",
    "completedAt": "2025-10-08T15:30:00Z",
    "stripePaymentIntentId": "pi_..."
  },
  "transaction": {
    "id": "transaction_uuid",
    "status": "succeeded",
    "fees": {
      "stripeFee": 8.27,
      "platformFee": 13.78
    }
  },
  "receipt": {
    "id": "receipt_uuid",
    "downloadUrl": "https://app.craftmarketplace.com/receipts/receipt_uuid"
  }
}
```

#### Stripe Webhook Handler
```dart
// Request: POST /payments/webhooks/stripe
// Headers: Stripe-Signature: stripe_signature_value

// Event Examples:
{
  "type": "checkout.session.completed",
  "data": {
    "object": {
      "id": "cs_test_...",
      "payment_intent": "pi_...",
      "metadata": {
        "payment_session_id": "payment_session_uuid"
      }
    }
  }
}
```

## Implementation Details

### Flutter Payment Module

#### Payment BLoC
```dart
// Payment Events
abstract class PaymentEvent {}
class PaymentSessionCreated extends PaymentEvent {
  final PaymentSession session;
}
class PaymentStatusChecked extends PaymentEvent {}
class PaymentExpired extends PaymentEvent {}
class PaymentCompleted extends PaymentEvent {
  final Transaction transaction;
}
class PaymentFailed extends PaymentEvent {
  final String reason;
}
class PaymentRetryRequested extends PaymentEvent {}

// Payment States
abstract class PaymentState {}
class PaymentInitial extends PaymentState {}
class PaymentLoading extends PaymentState {}
class PaymentPending extends PaymentState {
  final PaymentSession session;
  final Duration remainingTime;
}
class PaymentProcessing extends PaymentState {
  final PaymentSession session;
}
class PaymentCompleted extends PaymentState {
  final Transaction transaction;
  final Receipt receipt;
}
class PaymentFailed extends PaymentState {
  final String reason;
  final bool canRetry;
}
class PaymentExpired extends PaymentState {}
```

#### Payment Checkout Widget
```dart
class PaymentCheckoutWidget extends StatelessWidget {
  final String auctionId;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentBloc(),
      child: BlocBuilder<PaymentBloc, PaymentState>(
        builder: (context, state) {
          if (state is PaymentPending) {
            return _buildPaymentPending(context, state);
          } else if (state is PaymentProcessing) {
            return _buildPaymentProcessing(state);
          } else if (state is PaymentCompleted) {
            return _buildPaymentCompleted(state);
          } else if (state is PaymentFailed) {
            return _buildPaymentFailed(context, state);
          }
          return _buildInitialCheckout(context);
        },
      ),
    );
  }

  Widget _buildPaymentPending(BuildContext context, PaymentPending state) {
    return Column(
      children: [
        _buildCountdownTimer(state.remainingTime),
        _buildAmountDisplay(amount),
        _buildCheckoutButton(context, state.session),
        _buildSecurityInfo(),
      ],
    );
  }

  Widget _buildCheckoutButton(BuildContext context, PaymentSession session) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _launchStripeCheckout(session.stripeCheckoutUrl),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'Proceed to Secure Payment',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _launchStripeCheckout(String checkoutUrl) async {
    final uri = Uri.parse(checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw PaymentException('Could not launch payment URL');
    }
  }
}
```

#### WebView Integration for Stripe Checkout
```dart
class StripeCheckoutWebView extends StatefulWidget {
  final String checkoutUrl;
  final Function(bool success) onPaymentComplete;

  @override
  _StripeCheckoutWebViewState createState() => _StripeCheckoutWebViewState();
}

class _StripeCheckoutWebViewState extends State<StripeCheckoutWebView> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading indicator
          },
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);

            // Monitor for success/return URLs
            if (url.contains('payment/success')) {
              widget.onPaymentComplete(true);
              Navigator.of(context).pop();
            } else if (url.contains('payment/cancel')) {
              widget.onPaymentComplete(false);
              Navigator.of(context).pop();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Secure Checkout'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => widget.onPaymentComplete(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
```

### Serverpod Payment Service

#### Stripe Integration Service
```dart
class StripeService {
  final StripeClient _stripeClient;
  final PaymentRepository _paymentRepository;
  final WebhookService _webhookService;

  // Create checkout session
  Future<PaymentSession> createCheckoutSession({
    required String auctionId,
    required String buyerId,
    required Money amount,
    required String returnUrl,
    required String cancelUrl,
  }) async {
    try {
      // Create Stripe Checkout Session
      final checkoutSession = await _stripeClient.checkout.sessions.create(
        CheckoutSessionCreateParams(
          paymentMethodTypes: ['card'],
          mode: CheckoutSessionCreateParams.mode.payment,
          lineItems: [
            CheckoutSessionCreateParams.lineItem(
              priceData: CheckoutSessionCreateParams.lineItemPriceData(
                currency: amount.currency.toLowerCase(),
                unitAmount: (amount.amount * 100).toInt(), // Convert to cents
                productData: CheckoutSessionCreateParams.lineItemPriceDataProductData(
                  name: 'Auction Winning Bid',
                  description: 'Payment for auction $auctionId',
                ),
              ),
              quantity: 1,
            ),
          ],
          successUrl: returnUrl,
          cancelUrl: cancelUrl,
          expiresAt: DateTime.now().add(Duration(hours: 24)),
          metadata: {
            'auction_id': auctionId,
            'buyer_id': buyerId,
            'payment_session_id': 'will_be_generated',
          },
          paymentIntentCreationData: CheckoutSessionCreateParams.paymentIntentCreation(
            captureMethod: CheckoutSessionCreateParams.paymentIntentCreationCaptureMethod.automatic,
          ),
        ),
      );

      // Create payment session record
      final paymentSession = await _paymentRepository.create(
        PaymentSession(
          id: generateUuid(),
          auctionId: auctionId,
          buyerId: buyerId,
          stripeCheckoutId: checkoutSession.id,
          amount: amount,
          expiresAt: checkoutSession.expiresAt ?? DateTime.now().add(Duration(hours: 24)),
          status: PaymentStatus.pending,
          createdAt: DateTime.now(),
          metadata: {
            'stripe_checkout_id': checkoutSession.id,
            'return_url': returnUrl,
            'cancel_url': cancelUrl,
          },
        ),
      );

      // Update Stripe metadata with payment session ID
      await _stripeClient.checkout.sessions.update(
        checkoutSession.id,
        CheckoutSessionUpdateParams(
          metadata: {
            ...checkoutSession.metadata,
            'payment_session_id': paymentSession.id,
          },
        ),
      );

      // Schedule payment window expiration
      await _schedulePaymentExpiration(paymentSession.id, paymentSession.expiresAt);

      // Log checkout session creation
      await _logPaymentEvent(paymentSession.id, 'checkout_created', {
        'auction_id': auctionId,
        'buyer_id': buyerId,
        'amount': amount.amount,
        'stripe_checkout_id': checkoutSession.id,
      });

      return paymentSession;
    } on StripeException catch (e) {
      throw PaymentException('Failed to create checkout session: ${e.message}');
    }
  }

  // Process successful payment webhook
  Future<void> handleCheckoutCompleted(Map<String, dynamic> event) async {
    final session = event['data']['object'] as Map<String, dynamic>;
    final paymentSessionId = session['metadata']['payment_session_id'] as String?;

    if (paymentSessionId == null) {
      throw PaymentException('Payment session ID not found in webhook');
    }

    final paymentSession = await _paymentRepository.findById(paymentSessionId);
    if (paymentSession == null) {
      throw PaymentException('Payment session not found');
    }

    final paymentIntentId = session['payment_intent'] as String?;
    if (paymentIntentId == null) {
      throw PaymentException('Payment intent ID not found in webhook');
    }

    // Retrieve payment intent for full details
    final paymentIntent = await _stripeClient.paymentIntents.retrieve(paymentIntentId);

    // Create transaction record
    final transaction = await _createTransaction(
      paymentSessionId: paymentSessionId,
      stripePaymentIntentId: paymentIntentId,
      amount: Money(
        amount: paymentIntent.amount / 100.0, // Convert from cents
        currency: paymentIntent.currency.toUpperCase(),
      ),
      status: _mapStripeStatus(paymentIntent.status),
      fees: await _calculateStripeFees(paymentIntent),
    );

    // Update payment session status
    await _paymentRepository.updateStatus(
      paymentSessionId,
      PaymentStatus.completed,
      completedAt: DateTime.now(),
      stripePaymentIntentId: paymentIntentId,
    );

    // Generate receipt
    final receipt = await _generateReceipt(paymentSession, transaction);

    // Update auction status to completed
    await _updateAuctionStatus(paymentSession.auctionId, transaction);

    // Send notifications
    await _sendPaymentNotifications(paymentSession, transaction, receipt);

    // Log payment completion
    await _logPaymentEvent(paymentSessionId, 'payment_completed', {
      'stripe_payment_intent_id': paymentIntentId,
      'transaction_id': transaction.id,
      'amount_paid': transaction.amount.amount,
      'receipt_id': receipt.id,
    });
  }

  // Handle payment expiration
  Future<void> handlePaymentExpiration(String paymentSessionId) async {
    final paymentSession = await _paymentRepository.findById(paymentSessionId);
    if (paymentSession == null || paymentSession.status != PaymentStatus.pending) {
      return;
    }

    // Update payment session status
    await _paymentRepository.updateStatus(
      paymentSessionId,
      PaymentStatus.expired,
    );

    // Cancel Stripe checkout session if still active
    try {
      await _stripeClient.checkout.sessions.expire(paymentSession.stripeCheckoutId);
    } catch (e) {
      // Session might already be expired, log and continue
      await _logPaymentEvent(paymentSessionId, 'stripe_expire_failed', {
        'error': e.toString(),
      });
    }

    // Handle auction consequences (relist, notify participants, etc.)
    await _handleExpiredPayment(paymentSession);

    // Log expiration event
    await _logPaymentEvent(paymentSessionId, 'payment_expired', {
      'expired_at': DateTime.now().toIso8601String(),
    });
  }

  // Retry failed payment
  Future<PaymentSession> retryPayment(String paymentSessionId) async {
    final originalSession = await _paymentRepository.findById(paymentSessionId);
    if (originalSession == null) {
      throw PaymentException('Original payment session not found');
    }

    if (originalSession.status != PaymentStatus.failed) {
      throw PaymentException('Payment session is not in failed state');
    }

    // Check if retry is still within allowed time window
    if (DateTime.now().isAfter(originalSession.expiresAt)) {
      throw PaymentException('Payment window has expired');
    }

    // Create new checkout session with same details
    return await createCheckoutSession(
      auctionId: originalSession.auctionId,
      buyerId: originalSession.buyerId,
      amount: originalSession.amount,
      returnUrl: originalSession.metadata['return_url'],
      cancelUrl: originalSession.metadata['cancel_url'],
    );
  }
}
```

#### Webhook Handler Service
```dart
class StripeWebhookService {
  final String _webhookSecret;
  final PaymentService _paymentService;

  StripeWebhookService(this._webhookSecret, this._paymentService);

  Future<void> handleWebhook(String signature, String payload) async {
    try {
      // Verify webhook signature
      final event = _stripeClient.Webhooks.constructEvent(
        payload,
        signature,
        _webhookSecret,
      );

      // Process event based on type
      switch (event.type) {
        case 'checkout.session.completed':
          await _paymentService.handleCheckoutCompleted(event.data.object);
          break;
        case 'payment_intent.succeeded':
          await _paymentService.handlePaymentSucceeded(event.data.object);
          break;
        case 'payment_intent.payment_failed':
          await _paymentService.handlePaymentFailed(event.data.object);
          break;
        case 'checkout.session.expired':
          await _paymentService.handleCheckoutExpired(event.data.object);
          break;
        default:
          await _logUnknownWebhook(event.type, event.data.object);
      }
    } on StripeSignatureVerificationException {
      throw WebhookException('Invalid webhook signature');
    } catch (e) {
      throw WebhookException('Webhook processing failed: ${e.toString()}');
    }
  }

  Future<void> _logUnknownWebhook(String eventType, dynamic eventData) async {
    // Log unknown webhook events for monitoring
    print('Unknown webhook event: $eventType');
    // Store in database for review
  }
}
```

## Security Implementation

### PCI Compliance (SAQ A)
```dart
// All payment processing handled by Stripe
// No card data ever touches our servers
// Only payment intent IDs and metadata stored

class PCIComplianceManager {
  // Ensure no sensitive data is logged
  static String sanitizeLogData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);

    // Remove sensitive fields
    sanitized.remove('card_number');
    sanitized.remove('cvc');
    sanitized.remove('expiry');

    // Mask partial identifiers
    if (sanitized.containsKey('payment_intent_id')) {
      final pi = sanitized['payment_intent_id'] as String;
      sanitized['payment_intent_id'] = '${pi.substring(0, 8)}...';
    }

    return sanitized.toString();
  }

  // Validate that no card data is being stored
  static Future<void> validatePCICompliance() async {
    // Scan database for any potential card data
    // This would be run periodically as a security check
  }
}
```

### Webhook Security
```dart
class WebhookSecurity {
  static Future<bool> verifySignature(String payload, String signature, String secret) async {
    try {
      return Stripe.Webhooks.constructEvent(payload, signature, secret) != null;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logWebhookAttempt(
    String signature,
    bool isValid,
    String? error
  ) async {
    // Log webhook verification attempts for security monitoring
  }
}
```

## Database Schema

### Payment Sessions Table
```sql
CREATE TABLE payment_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id UUID NOT NULL REFERENCES auctions(id),
  buyer_id UUID NOT NULL REFERENCES users(id),
  stripe_checkout_id VARCHAR(255) NOT NULL UNIQUE,
  amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  stripe_payment_intent_id VARCHAR(255) UNIQUE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_payment_sessions_status ON payment_sessions(status);
CREATE INDEX idx_payment_sessions_expires_at ON payment_sessions(expires_at);
CREATE INDEX idx_payment_sessions_auction_id ON payment_sessions(auction_id);
CREATE INDEX idx_payment_sessions_buyer_id ON payment_sessions(buyer_id);
```

### Transactions Table
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_session_id UUID NOT NULL REFERENCES payment_sessions(id),
  stripe_payment_intent_id VARCHAR(255) NOT NULL UNIQUE,
  amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  stripe_fee DECIMAL(10,2),
  platform_fee DECIMAL(10,2),
  net_amount DECIMAL(10,2),
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  failure_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  processed_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_payment_session_id ON transactions(payment_session_id);
CREATE INDEX idx_transactions_created_at ON transactions(created_at);
```

### Receipts Table
```sql
CREATE TABLE receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL REFERENCES transactions(id),
  receipt_number VARCHAR(50) UNIQUE NOT NULL,
  buyer_id UUID NOT NULL REFERENCES users(id),
  maker_id UUID NOT NULL REFERENCES users(id),
  auction_id UUID NOT NULL REFERENCES auctions(id),
  total_amount DECIMAL(10,2) NOT NULL,
  stripe_fee DECIMAL(10,2),
  platform_fee DECIMAL(10,2),
  seller_payout DECIMAL(10,2),
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  issued_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  download_url TEXT,
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_receipts_transaction_id ON receipts(transaction_id);
CREATE INDEX idx_receipts_buyer_id ON receipts(buyer_id);
CREATE INDEX idx_receipts_maker_id ON receipts(maker_id);
CREATE INDEX idx_receipts_issued_at ON receipts(issued_at);
```

## Testing Strategy

### Unit Tests
- **Payment Service:** Test checkout creation, webhook processing, retry logic
- **Stripe Integration:** Mock Stripe client for API interaction testing
- **Webhook Security:** Test signature verification and error handling
- **State Management:** Test BLoC state transitions and error scenarios

### Integration Tests
- **Payment Flow:** End-to-end payment from checkout to completion
- **Webhook Processing:** Test webhook handling with Stripe test environment
- **Retry Mechanisms:** Test payment retry scenarios and limits
- **Expiration Handling:** Test payment window expiration and cleanup

### Stripe Testing
- **Test Mode:** Use Stripe test keys and test card numbers
- **Webhook Testing:** Use Stripe CLI for webhook event testing
- **Error Scenarios:** Test declined cards, insufficient funds, etc.
- **Edge Cases:** Test partial payments, refunds, disputes

## Error Handling

### Payment Errors
```dart
abstract class PaymentException implements Exception {
  final String message;
  final PaymentErrorCode code;
}

class CheckoutCreationException extends PaymentException { }
class PaymentExpiredException extends PaymentException { }
class PaymentFailedException extends PaymentException { }
class StripeApiException extends PaymentException { }
class WebhookVerificationException extends PaymentException { }
```

### Retry Logic
```dart
class PaymentRetryService {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(minutes: 5);

  static Future<bool> canRetryPayment(PaymentSession session) async {
    if (session.retryCount >= maxRetries) {
      return false;
    }

    if (DateTime.now().isAfter(session.expiresAt)) {
      return false;
    }

    return true;
  }

  static Future<DateTime?> calculateNextRetryTime(PaymentSession session) async {
    if (!await canRetryPayment(session)) {
      return null;
    }

    return DateTime.now().add(retryDelay);
  }
}
```

## Performance Considerations

### Database Optimization
- Indexes on frequently queried columns
- Partitioning for large transaction tables
- Connection pooling for high volume
- Read replicas for reporting queries

### Caching Strategy
- Redis cache for active payment sessions
- Payment status caching to reduce database queries
- Stripe rate limit awareness and backoff

### Monitoring
- Payment success rates and failure patterns
- Stripe API latency and error rates
- Webhook processing delays
- Revenue tracking and financial metrics

## Success Criteria

### Functional Requirements
- ✅ Secure Stripe Checkout integration with PCI SAQ A compliance
- ✅ 24-hour payment window with automatic expiration
- ✅ Payment retry mechanisms for failed transactions
- ✅ Comprehensive receipt generation and delivery
- ✅ Real-time payment status updates

### Non-Functional Requirements
- ✅ Payment completion rate > 95%
- ✅ Checkout page load time < 3 seconds
- ✅ Payment status update latency < 30 seconds
- ✅ 99.9% uptime for payment processing
- ✅ Zero security vulnerabilities in PCI compliance

## Next Steps

1. **Implement Stripe Integration** - Checkout sessions, webhooks, payment handling
2. **Build Flutter Payment UI** - Checkout launcher, status tracking, receipt display
3. **Create Webhook Infrastructure** - Signature verification, event processing
4. **Implement Retry Logic** - Payment retry mechanisms and expiration handling
5. **Generate Receipt System** - PDF generation, delivery, storage
6. **Security Testing** - PCI compliance validation, webhook security testing

---

**Version:** v0.5 (Definitive)
**Date:** 2025-10-29
**Dependencies:** Epic 1 (Authentication), Epic 10 (Auction Timer) for auction completion trigger, Epic 11 (Notifications)
**Blocks:** Epic 13 (Shipping & Tracking), Epic 14 (Issue Resolution & Refunds)