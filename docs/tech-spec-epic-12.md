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
- **Stripe:** Stripe Connect Express, Checkout Sessions, Payment Intents, Webhooks
- **Flutter:** WebView integration for Stripe Checkout, payment status polling
- **Serverpod:** Stripe SDK, webhook signature verification, secure session storage
- **Security:** PCI SAQ A compliance, webhook signature validation, idempotency keys

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

**Dependencies:** Epic 10 (Auction Timer) for auction completion trigger, Epic 13 (Orders) for order creation
**Blocks:** Epic 14 (Issue Resolution) for payment disputes and refunds