# Stripe Connect Express Integration Guide - Video Window

**Version:** Stripe API Latest (2025)  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Payment Processing (Epic 12)

---

## Overview

Video Window uses **Stripe Connect Express** for marketplace payments:
- **Makers** (sellers) onboard via Connect Express
- **Platform** (Video Window) creates checkout sessions
- **Buyers** pay via hosted Stripe Checkout (SAQ A compliance)
- **Payouts** automatically distributed to makers

---

## Architecture Pattern

```
Buyer Payment Flow:
┌─────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────┐
│ Buyer   │───▶│ Video Window │───▶│   Stripe    │───▶│  Maker  │
│ (App)   │    │  (Platform)  │    │  (Checkout) │    │ (Payout)│
└─────────┘    └──────────────┘    └─────────────┘    └─────────┘
                      │                    │
                      ▼                    ▼
                 [Creates          [Webhooks Drive
                  Checkout           State Machine]
                  Session]
```

---

## Maker Onboarding (Connect Express)

### Step 1: Create Connected Account

```dart
// video_window_server/lib/src/endpoints/payments/stripe_endpoint.dart
@override
Future<StripeConnectAccountDto> createConnectAccount(
  Session session,
  String userId,
) async {
  // Verify user exists and is not already connected
  final user = await User.findById(session, userId);
  if (user == null) throw UserNotFoundException();
  
  // Create Express account
  final account = await stripe.accounts.create(
    type: 'express',
    country: 'US',  // Or user's country
    email: user.email,
    capabilities: {
      'card_payments': {'requested': true},
      'transfers': {'requested': true},
    },
    businessType: 'individual',  // Or 'company'
  );
  
  // Save to database
  final connectAccount = StripeConnectAccount(
    userId: userId,
    stripeAccountId: account.id,
    onboardingComplete: false,
  );
  await StripeConnectAccount.insert(session, connectAccount);
  
  return StripeConnectAccountDto.fromModel(connectAccount);
}
```

### Step 2: Create Account Link

```dart
@override
Future<String> createAccountLink(
  Session session,
  String userId,
) async {
  final account = await StripeConnectAccount.findByUserId(session, userId);
  if (account == null) throw ConnectAccountNotFoundException();
  
  final accountLink = await stripe.accountLinks.create(
    account: account.stripeAccountId,
    refreshUrl: 'videowindow://connect/refresh',
    returnUrl: 'videowindow://connect/return',
    type: 'account_onboarding',
  );
  
  return accountLink.url;  // Valid for ~5 minutes, single use
}
```

### Step 3: Flutter UI Launch

```dart
// packages/features/commerce/lib/presentation/pages/maker_onboarding_page.dart
class MakerOnboardingPage extends StatelessWidget {
  Future<void> _startOnboarding(BuildContext context) async {
    final bloc = context.read<MakerOnboardingBloc>();
    
    // Get onboarding URL from backend
    bloc.add(StartOnboarding());
    
    final state = await bloc.stream.firstWhere(
      (state) => state is OnboardingUrlReady || state is OnboardingError,
    );
    
    if (state is OnboardingUrlReady) {
      // Open in webview (in-app browser)
      await launchUrl(
        Uri.parse(state.url),
        mode: LaunchMode.inAppWebView,
      );
    }
  }
}
```

### Step 4: Handle Return/Refresh

```dart
// App-level deep link handler
@override
Widget build(BuildContext context) {
  return MaterialApp.router(
    routerConfig: GoRouter(
      routes: [
        GoRoute(
          path: '/connect/return',
          builder: (_, __) => ConnectReturnPage(),  // Check details_submitted
        ),
        GoRoute(
          path: '/connect/refresh',
          builder: (_, __) => ConnectRefreshPage(),  // Re-generate account link
        ),
      ],
    ),
  );
}
```

---

## Checkout Session (Buyer Payment)

### Backend: Create Session

```dart
// video_window_server/lib/src/endpoints/payments/checkout_endpoint.dart
@override
Future<CheckoutSessionDto> createCheckoutSession(
  Session session,
  String offerId,
) async {
  final offer = await Offer.findById(session, offerId);
  if (offer == null) throw OfferNotFoundException();
  
  final story = await Story.findById(session, offer.storyId);
  final maker = await User.findById(session, story.userId);
  final connectAccount = await StripeConnectAccount.findByUserId(
    session,
    maker.id,
  );
  
  // Create Stripe Checkout Session
  final checkoutSession = await stripe.checkout.sessions.create(
    mode: 'payment',
    lineItems: [
      {
        'price_data': {
          'currency': 'usd',
          'product_data': {
            'name': story.title,
            'images': [story.thumbnailUrl],
          },
          'unit_amount': (offer.amount * 100).toInt(),  // Cents
        },
        'quantity': 1,
      },
    ],
    paymentIntentData: {
      'applicationFeeAmount': _calculatePlatformFee(offer.amount),
      'transferData': {
        'destination': connectAccount.stripeAccountId,
      },
    },
    successUrl: 'videowindow://checkout/success?session_id={CHECKOUT_SESSION_ID}',
    cancelUrl: 'videowindow://checkout/cancel',
    expiresAt: DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000,
    metadata: {
      'offer_id': offerId,
      'buyer_id': session.auth?.userId ?? 'guest',
    },
  );
  
  return CheckoutSessionDto(
    id: checkoutSession.id,
    url: checkoutSession.url,
    expiresAt: DateTime.fromMillisecondsSinceEpoch(checkoutSession.expiresAt * 1000),
  );
}

int _calculatePlatformFee(double amount) {
  return (amount * 0.10 * 100).toInt();  // 10% platform fee in cents
}
```

### Flutter: Launch Checkout

```dart
// packages/features/commerce/lib/presentation/pages/checkout_page.dart
Future<void> _launchCheckout(BuildContext context, String offerId) async {
  final bloc = context.read<CheckoutBloc>();
  bloc.add(CreateCheckoutSession(offerId: offerId));
  
  final state = await bloc.stream.firstWhere(
    (state) => state is CheckoutSessionReady || state is CheckoutError,
  );
  
  if (state is CheckoutSessionReady) {
    // Open Stripe hosted checkout
    final result = await launchUrl(
      Uri.parse(state.checkoutUrl),
      mode: LaunchMode.inAppWebView,
    );
    
    // Poll for payment completion or handle deep link
  }
}
```

---

## Webhook Handling (State Machine Driver)

### Configure Webhook Endpoint

```dart
// video_window_server/lib/src/endpoints/webhooks/stripe_webhook_endpoint.dart
@override
Future<void> handleWebhook(
  Session session,
  String payload,
  String signature,
) async {
  // Verify webhook signature
  final event = stripe.webhooks.constructEvent(
    payload,
    signature,
    webhookSecret,
  );
  
  // Route to handlers
  switch (event.type) {
    case 'checkout.session.completed':
      await _handleCheckoutCompleted(session, event.data.object);
      break;
    case 'payment_intent.succeeded':
      await _handlePaymentSucceeded(session, event.data.object);
      break;
    case 'account.updated':
      await _handleAccountUpdated(session, event.data.object);
      break;
    default:
      print('Unhandled event type: ${event.type}');
  }
}

Future<void> _handleCheckoutCompleted(
  Session session,
  Map<String, dynamic> checkoutSession,
) async {
  final offerId = checkoutSession['metadata']['offer_id'];
  final offer = await Offer.findById(session, offerId);
  
  // Create order
  final order = Order(
    offerId: offerId,
    buyerId: checkoutSession['metadata']['buyer_id'],
    status: OrderStatus.paymentPending,
    amount: offer.amount,
    stripeSessionId: checkoutSession['id'],
  );
  await Order.insert(session, order);
}

Future<void> _handlePaymentSucceeded(
  Session session,
  Map<String, dynamic> paymentIntent,
) async {
  final order = await Order.findByStripeSessionId(
    session,
    paymentIntent['metadata']['checkout_session_id'],
  );
  
  // Transition to shipping
  order.status = OrderStatus.awaitingShipment;
  await Order.update(session, order);
  
  // Send notification to maker (Epic 14)
  // await _notifyMakerNewOrder(order);
}
```

---

## Security Patterns

### 1. Idempotency Keys

```dart
final checkoutSession = await stripe.checkout.sessions.create(
  // ... session params
  idempotencyKey: 'checkout_${offerId}_${DateTime.now().millisecondsSinceEpoch}',
);
```

### 2. 3D Secure Enforcement

```dart
paymentIntentData: {
  'paymentMethodOptions': {
    'card': {
      'requestThreeDSecure': 'automatic',  // Or 'any' for strict enforcement
    },
  },
},
```

### 3. SAQ A Compliance

```dart
// ✅ CORRECT - Hosted checkout (no PAN touches platform)
await launchUrl(Uri.parse(checkoutSession.url));

// ❌ WRONG - Custom payment form (requires SAQ A-EP or SAQ D)
// Never implement custom card input fields
```

---

## Testing Patterns

```dart
// test/endpoints/payments/stripe_endpoint_test.dart
void main() {
  group('StripeEndpoint', () {
    late TestSession session;
    late StripeEndpoint endpoint;
    
    setUp(() {
      session = TestSession();
      endpoint = StripeEndpoint();
    });
    
    test('createConnectAccount creates Express account', () async {
      final user = await _createTestUser(session);
      
      final account = await endpoint.createConnectAccount(
        session,
        user.id,
      );
      
      expect(account.stripeAccountId, startsWith('acct_'));
      expect(account.onboardingComplete, isFalse);
    });
    
    test('createCheckoutSession has 24h expiry', () async {
      final offer = await _createTestOffer(session);
      
      final checkoutSession = await endpoint.createCheckoutSession(
        session,
        offer.id,
      );
      
      final expiresIn = checkoutSession.expiresAt.difference(DateTime.now());
      expect(expiresIn.inHours, greaterThanOrEqualTo(23));
      expect(expiresIn.inHours, lessThanOrEqualTo(24));
    });
  });
}
```

---

## Common Mistakes

```dart
// ❌ WRONG - Custom payment UI (breaks SAQ A)
TextFormField(
  decoration: InputDecoration(labelText: 'Card Number'),
  // DON'T EVER COLLECT CARD DETAILS DIRECTLY
);

// ✅ CORRECT - Hosted checkout
await launchUrl(Uri.parse(checkoutSession.url));

// ❌ WRONG - Missing idempotency key
await stripe.checkout.sessions.create(...);

// ✅ CORRECT - Idempotency key prevents duplicates
await stripe.checkout.sessions.create(
  idempotencyKey: 'unique_key',
  ...
);

// ❌ WRONG - Trusting client amount
final amount = request.amount;  // From Flutter

// ✅ CORRECT - Server-side pricing
final offer = await Offer.findById(session, offerId);
final amount = offer.amount;  // From database
```

---

## Video Window Conventions

- **Platform Fee:** 10% of transaction amount
- **Checkout Expiry:** 24 hours
- **Onboarding:** Express accounts only (Stripe handles KYC)
- **Payouts:** Automatic via Stripe (no manual transfers)
- **SAQ Scope:** SAQ A (hosted checkout only)
- **3DS:** Automatic enforcement

---

## Reference

- **Stripe Connect:** https://stripe.com/docs/connect
- **Express Accounts:** https://stripe.com/docs/connect/express-accounts
- **Checkout Sessions:** https://stripe.com/docs/payments/checkout
- **Webhooks:** https://stripe.com/docs/webhooks

---

**Last Updated:** 2025-11-03 by Winston  
**Epic:** 12 (Marketplace Payments)
