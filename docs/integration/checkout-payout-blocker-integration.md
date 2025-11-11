# Checkout Payout Blocker Integration Guide

## Overview

This guide documents how to integrate `PayoutBlockerSheet` with the checkout flow to satisfy AC1 of Story 2-3.

## AC1 Requirement

**Attempting to launch checkout when `!canCollectPayments` opens a modal summarizing payout prerequisites and provides Stripe Express onboarding CTA.**

## Implementation Pattern

### Step 1: Check Capability Before Checkout

Before launching checkout, check the user's payment capability:

```dart
// In your checkout flow (e.g., checkout_page.dart or checkout_bloc.dart)
final capabilityService = CapabilityService();
final status = await capabilityService.getStatus(userId);

if (!status.canCollectPayments) {
  // Show PayoutBlockerSheet
  await _showPayoutBlocker(context, status.blockers);
  return; // Don't proceed with checkout
}

// Proceed with checkout
await _launchCheckout();
```

### Step 2: Show PayoutBlockerSheet

```dart
Future<void> _showPayoutBlocker(
  BuildContext context,
  Map<String, String> blockers,
) async {
  // Get Stripe onboarding URL if needed
  String? onboardingUrl;
  try {
    final response = await capabilityEndpoint.getStripeOnboardingLink(
      userId: userId,
      returnUrl: 'videowindow://capabilities/return',
    );
    onboardingUrl = response['onboardingUrl'] as String?;
  } catch (e) {
    // Handle error - onboarding URL optional
  }

  // Extract requirements from blockers
  final requirements = blockers.values.toList();

  // Show the blocker sheet
  await PayoutBlockerSheet.show(
    context,
    onEnablePayments: () {
      // Navigate to capability center or Stripe onboarding
      Navigator.pushNamed(context, '/capabilities');
    },
    requirements: requirements,
    stripeOnboardingUrl: onboardingUrl,
  );
}
```

### Step 3: Handle Server Response

When `PaymentEndpoint.createCheckoutSession` returns `PAYMENT_CAPABILITY_REQUIRED` error:

```dart
try {
  final session = await paymentEndpoint.createCheckoutSession(orderId);
  // Proceed with checkout
} catch (e) {
  if (e is PaymentCapabilityRequiredException) {
    // Show PayoutBlockerSheet
    await _showPayoutBlocker(context, e.blockers);
  } else {
    // Handle other errors
  }
}
```

## Integration Points

1. **Checkout Page/Bloc**: Check capability before creating checkout session
2. **Payment Endpoint**: Returns `PAYMENT_CAPABILITY_REQUIRED` error with blockers
3. **Capability Endpoint**: Provides Stripe onboarding link generation
4. **PayoutBlockerSheet**: Displays modal with requirements and Stripe CTA

## Testing

1. Test checkout blocked when `canCollectPayments = false`
2. Test PayoutBlockerSheet displays with correct requirements
3. Test Stripe onboarding link launches correctly
4. Test checkout proceeds when capability enabled

## Notes

- The server-side guard in `PaymentEndpoint` provides defense-in-depth
- Client-side check provides better UX (immediate feedback)
- Stripe onboarding URL is optional - fallback to capability center if unavailable

