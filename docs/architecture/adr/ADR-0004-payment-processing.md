# ADR-0004: Payment Processing: Stripe Connect Express

**Date:** 2025-10-09
**Status:** Accepted
**Decider(s):** Technical Lead, Product Owner, Finance Team
**Reviewers:** Development Team, Legal Team, Security Team

## Context
The video auctions platform requires a comprehensive payment processing solution that handles:
- Buyer payments for auction wins
- Seller payouts for successful auctions
- Platform fee collection
- Refund processing
- Compliance with financial regulations
- Multi-party payment flows
- International payment support (future)

## Decision
Implement Stripe Connect Express for payment processing, providing a comprehensive solution for marketplace payments with compliance, security, and scalability.

## Options Considered

1. **Option A** - Stripe Standard (Direct Integration)
   - Pros: Simple implementation, well-documented
   - Cons: Limited marketplace features, manual payout management
   - Risk: Compliance burden on platform, complex accounting

2. **Option B** - PayPal Marketplace
   - Pros: Established brand, global reach
   - Cons: Higher fees, complex integration, limited customization
   - Risk: Vendor lock-in, higher operational costs

3. **Option C** - Adyen for Platforms
   - Pros: Comprehensive platform solution, good international support
   - Cons: Complex implementation, higher entry requirements
   - Risk: Over-engineering for initial needs

4. **Option D** - Stripe Connect Express (Chosen)
   - Pros: Marketplace-specific features, compliance handling, excellent documentation, reasonable fees
   - Cons: Platform dependency, some customization limitations
   - Risk: Platform dependency, fee structure changes

## Decision Outcome
Chose Option D: Stripe Connect Express. This provides:
- Managed compliance and regulations
- Automated payouts to sellers
- Platform fee collection
- Comprehensive fraud protection
- Excellent developer experience
- Scalable for growth

## Consequences

- **Positive:**
  - Reduced compliance burden
  - Automated financial operations
  - Built-in fraud protection
  - Excellent API and documentation
  - Strong security measures
  - Scalable for international expansion

- **Negative:**
  - Platform dependency on Stripe
  - Transaction fees (2.9% + 30¢ + platform fee)
  - Limited customization of payment flows
  - Data residency considerations

- **Neutral:**
  - Integration complexity
  - Development timeline impact
  - User experience considerations

## Architecture Overview

### Payment Flow Architecture
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Buyer     │    │  Platform   │    │   Stripe    │    │   Seller    │
│             │    │             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
       │ 1. Place bid       │                   │                   │
       │──────────────────►│                   │                   │
       │                   │                   │                   │
       │                   │ 2. Create payment │                   │
       │                   │──────────────────►│                   │
       │                   │                   │                   │
       │ 3. Confirm payment │                   │                   │
       │◄──────────────────│                   │                   │
       │                   │                   │                   │
       │                   │                   │ 4. Transfer funds │
       │                   │                   │──────────────────►│
       │                   │                   │                   │
       │                   │ 5. Deduct fees    │                   │
       │                   │◄──────────────────│                   │
       │                   │                   │                   │
```

### Key Components

#### Stripe Connect Setup
```dart
// Seller Onboarding
class StripeConnectService {
  Future<String> createSellerAccount(String sellerId) async {
    final account = await stripe.accounts.create({
      'type': 'express',
      'country': 'US',
      'email': 'seller@example.com',
      'capabilities': {
        'card_payments': {'requested': true},
        'transfers': {'requested': true},
      },
      'business_type': 'individual',
    });

    return account.id;
  }

  Future<String> createAccountLink(String accountId) async {
    final accountLink = await stripe.accountLinks.create({
      'account': accountId,
      'refresh_url': 'https://app.example.com/reauth',
      'return_url': 'https://app.example.com/return',
      'type': 'account_onboarding',
    });

    return accountLink.url;
  }
}
```

#### Payment Processing
```dart
class PaymentService {
  Future<PaymentIntent> createPaymentIntent({
    required double amount,
    required String currency,
    required String sellerAccountId,
    double platformFee = 0.10, // 10% platform fee
  }) async {
    return await stripe.paymentIntents.create({
      'amount': (amount * 100).round(), // Convert to cents
      'currency': currency.toLowerCase(),
      'payment_method_types': ['card'],
      'transfer_data': {
        'destination': sellerAccountId,
        'amount': ((amount * (1 - platformFee)) * 100).round(),
      },
      'application_fee_amount': ((amount * platformFee) * 100).round(),
      'metadata': {
        'auction_id': 'auction_123',
        'buyer_id': 'user_456',
        'seller_id': 'user_789',
      },
    });
  }
}
```

#### Refund Processing
```dart
class RefundService {
  Future<Refund> processRefund({
    required String paymentIntentId,
    required double amount,
    required String reason,
  }) async {
    return await stripe.refunds.create({
      'payment_intent': paymentIntentId,
      'amount': (amount * 100).round(),
      'reason': reason,
      'metadata': {
        'refund_reason': reason,
        'processed_by': 'system',
      },
    });
  }
}
```

### Data Model Integration

#### Payment Database Schema
```sql
-- Payment Records
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stripe_payment_intent_id VARCHAR(255) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id),
    auction_id UUID NOT NULL REFERENCES auctions(id),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    status VARCHAR(50) NOT NULL,
    platform_fee DECIMAL(10,2) NOT NULL,
    seller_payout DECIMAL(10,2) NOT NULL,
    stripe_fee DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
);

-- Seller Accounts
CREATE TABLE seller_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    stripe_account_id VARCHAR(255) UNIQUE NOT NULL,
    status VARCHAR(50) NOT NULL,
    onboarding_completed BOOLEAN DEFAULT FALSE,
    charges_enabled BOOLEAN DEFAULT FALSE,
    payouts_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
);

-- Payout Records
CREATE TABLE payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_account_id UUID NOT NULL REFERENCES seller_accounts(id),
    stripe_transfer_id VARCHAR(255) UNIQUE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    status VARCHAR(50) NOT NULL,
    arrival_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
);
```

## Implementation Strategy

### Phase 1: Basic Integration (Week 1-2)
- Set up Stripe Connect Express account
- Implement seller onboarding flow
- Create basic payment intent processing
- Set up webhooks for payment events

### Phase 2: Advanced Features (Week 3-4)
- Implement refund processing
- Add dispute handling
- Create dashboard for financial overview
- Implement platform fee management

### Phase 3: Security & Compliance (Week 5)
- Implement proper authentication
- Add PCI compliance measures
- Create audit logging
- Set up monitoring and alerting

### Phase 4: Testing & Launch (Week 6)
- Comprehensive testing with Stripe test mode
- User acceptance testing
- Production deployment
- Post-launch monitoring

## Security Considerations

### PCI Compliance
- SAQ A compliance level (Stripe redirects)
- No card data stored on platform servers
- All card processing handled by Stripe
- Secure communication protocols

### Data Protection
- Sensitive financial data encrypted
- Access logs and audit trails
- Principle of least privilege
- Regular security audits

### Fraud Prevention
- Stripe Radar integration
- Transaction monitoring
- Velocity checks
- Device fingerprinting

## Fee Structure

### Transaction Fees
- **Stripe Fee**: 2.9% + 30¢ per transaction
- **Platform Fee**: 10% of transaction amount
- **Total Buyer Cost**: 12.9% + 30¢ per transaction

### Payout Fees
- **Standard Payout**: Free (2-7 business days)
- **Instant Payout**: 1% of payout amount
- **International Payout**: Additional fees apply

### Refund Fees
- **Refund Processing**: No fee for refunded transactions
- **Chargeback**: $15 fee if lost

## Webhook Handling

### Key Webhook Events
```dart
class StripeWebhookHandler {
  void handleWebhookEvent(String eventType, Map<String, dynamic> data) {
    switch (eventType) {
      case 'payment_intent.succeeded':
        _handlePaymentSuccess(data);
        break;
      case 'payment_intent.payment_failed':
        _handlePaymentFailure(data);
        break;
      case 'account.updated':
        _handleAccountUpdate(data);
        break;
      case 'transfer.created':
        _handleTransferCreated(data);
        break;
      case 'charge.dispute.created':
        _handleDisputeCreated(data);
        break;
    }
  }
}
```

## Error Handling

### Payment Error Scenarios
- Insufficient funds
- Card declined
- Network issues
- Invalid payment method
- Fraud detection triggers

### Recovery Strategies
- Retry mechanisms for transient failures
- Clear user error messages
- Fallback payment methods
- Manual review processes

## Monitoring and Analytics

### Key Metrics
- Payment success rate
- Average transaction value
- Refund rate
- Chargeback rate
- Processing time
- Revenue per transaction

### Alerting
- Payment failure rate > 5%
- High-value transactions
- Unusual activity patterns
- Service downtime

## Related ADRs
- ADR-0002: Flutter + Serverpod Architecture
- ADR-0003: Database Architecture: PostgreSQL + Redis
- ADR-0005: AWS Infrastructure Strategy

## References
- [Stripe Connect Documentation](https://stripe.com/docs/connect)
- [Stripe API Reference](https://stripe.com/docs/api)
- [PCI Compliance Guide](https://stripe.com/docs/security)
- [Payment Processing Technical Specification](../../tech-spec-epic-12.md)

## Status Updates
- **2025-10-09**: Accepted - Payment processing solution confirmed
- **2025-10-09**: Integration planning started
- **TBD**: Implementation phase begins

---

*This ADR establishes a comprehensive, compliant, and scalable payment processing solution using Stripe Connect Express for the video auctions marketplace.*