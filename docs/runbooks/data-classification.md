# Data Classification Framework

**Version:** 1.0.0  
**Last Updated:** 2025-11-10  
**Owner:** Privacy/Security Team  
**Status:** Active

## Overview

This document defines how Craft Video Marketplace classifies data for proper handling, retention, encryption, and compliance with GDPR/CCPA requirements.

## Purpose

Data classification ensures:
- Appropriate security controls for sensitive data
- Compliance with regulatory retention requirements
- Proper handling of user privacy
- Clear data lifecycle management

## Classification Categories

The `DataCategory` enum in `PrivacyService` defines five categories:

### 1. Personal (PII - Personally Identifiable Information)

**Definition:** Data that can identify an individual directly.

**Examples:**
- Name (first, last, full)
- Email address
- Phone number
- Physical address
- Government-issued ID numbers
- Date of birth
- Social Security Number (if collected)
- Biometric data
- IP address (can be PII under GDPR)

**Storage Requirements:**
- ✅ Encrypted at rest (AES-256)
- ✅ Encrypted in transit (TLS 1.3)
- ✅ Access logged for audit
- ✅ Geo-restrictions may apply (EU data stays in EU)

**Retention Policy:**
- Active accounts: Retained while account exists
- Inactive accounts: 2 years from last activity
- Deleted on user request (GDPR Right to Erasure)

**Access Control:**
- Restricted to authorized personnel only
- Require authentication + role-based permissions
- All access logged

**Regulatory:**
- GDPR: Requires explicit consent or legal basis
- CCPA: User has right to know, delete, opt-out of sale
- Must support data portability

### 2. Financial

**Definition:** Payment and transaction-related data.

**Examples:**
- Payment method (card last 4, type)
- Transaction history (purchases, sales)
- Payment amounts
- Refund records
- Tax information
- Payout account details
- Invoice records

**Storage Requirements:**
- ✅ Encrypted at rest (AES-256)
- ✅ Encrypted in transit (TLS 1.3)
- ✅ PCI-DSS compliance for card data (tokenized via Stripe)
- ✅ Immutable audit trail
- ❌ Never store full card numbers (use Stripe tokens)

**Retention Policy:**
- Financial records: 7 years (legal requirement)
- Tax records: 7 years
- Transaction logs: 7 years
- **Cannot be deleted on user request** (legal exemption)
- Personal identifiers anonymized after account deletion

**Access Control:**
- Highly restricted
- Finance team + authorized support only
- All access logged and audited
- Requires manager approval for bulk access

**Regulatory:**
- IRS: 7 year retention for tax purposes
- PCI-DSS: Specific requirements for payment data
- SOX: Audit trail requirements
- GDPR/CCPA: Legal obligation exemption from deletion

### 3. Content (User-Generated)

**Definition:** Content created by users on the platform.

**Examples:**
- Videos uploaded by makers
- Video thumbnails
- Offer descriptions
- Comments and reviews
- Messages between users
- User bios and profiles

**Storage Requirements:**
- ✅ Encrypted at rest (AES-256)
- ✅ Encrypted in transit (TLS 1.3)
- ✅ Access controls based on privacy settings
- ✅ Content moderation scanning

**Retention Policy:**
- Active content: Retained while account active
- Deleted content: 30 day soft delete (recovery period)
- After 30 days: Permanent deletion
- Content may be retained if part of completed transaction with another user

**Access Control:**
- Owners: Full access
- Viewers: Based on privacy settings
- Moderators: View-only access for moderation
- All moderation actions logged

**Regulatory:**
- GDPR: Right to erasure applies (with exceptions for contractual obligations)
- CCPA: Right to delete applies
- Content may need to be retained for active transactions

**Special Considerations:**
- Content involved in active transactions may be retained longer
- Content involved in disputes retained until resolution
- Illegal content reported to authorities before deletion

### 4. Behavioral (Analytics)

**Definition:** User behavior and usage patterns.

**Examples:**
- Page views
- Click events
- Feature usage
- Search queries
- Time spent on pages
- Navigation patterns
- A/B test participation
- Session data

**Storage Requirements:**
- ✅ Anonymized where possible
- ✅ Encrypted in transit
- ✅ May be encrypted at rest depending on sensitivity
- ⚠️ Requires user consent (GDPR) or opt-out option (CCPA)

**Retention Policy:**
- Hot storage: 90 days
- Cold storage (aggregated): 2 years
- Automatically deleted after retention period

**Access Control:**
- Analytics team: Aggregated data only
- Product team: Aggregated data only
- Engineering: Access to debug issues
- No PII exposed in analytics (pseudonymized user IDs only)

**Regulatory:**
- GDPR: Requires consent (not strictly necessary)
- CCPA: Must allow opt-out
- Can be deleted immediately on user request
- Must be included in data export (DSAR)

**Best Practices:**
- Pseudonymize: Use hashed user IDs, not real IDs
- Aggregate: Prefer aggregate statistics over individual tracking
- Consent: Always get consent before tracking
- Document: Clear disclosure in privacy policy

### 5. Technical (System)

**Definition:** System logs and technical operations data.

**Examples:**
- Application logs
- Error logs
- Performance metrics
- System health data
- Infrastructure logs
- Security events
- Audit trails

**Storage Requirements:**
- ✅ Encrypted in transit
- ⚠️ May contain PII (IP addresses, user IDs) - sanitize when possible
- ✅ Access restricted to operations team

**Retention Policy:**
- Application logs: 90 days
- Security logs: 2 years
- Audit logs (financial): 7 years
- Audit logs (general): 2 years
- System metrics: 90 days (real-time), 2 years (aggregated)

**Access Control:**
- Engineering team: Debug and troubleshooting
- Security team: Incident investigation
- Compliance team: Audits
- All access logged

**Regulatory:**
- GDPR: If contains PII, subject to same rules
- Security logs may be retained longer for legal reasons
- Audit logs required for compliance (SOX, PCI-DSS)

**PII Sanitization:**
- Remove or hash IP addresses after 30 days
- Remove user IDs from non-security logs after 90 days
- Keep only aggregated metrics long-term

## Processing Purposes

The `ProcessingPurpose` enum defines why we process data:

### 1. Service Delivery

**Definition:** Core functionality required to provide the service.

**Legal Basis:**
- GDPR: Contract performance (Art. 6.1.b)
- CCPA: Exempt as necessary for service

**Data Types:** Personal, Financial, Content
**Consent Required:** No (necessary for service)
**User Control:** Cannot opt-out (would break service)

**Examples:**
- Authenticating users
- Processing transactions
- Delivering videos
- Enabling communication

### 2. Analytics

**Definition:** Understanding how users interact with the platform.

**Legal Basis:**
- GDPR: Consent (Art. 6.1.a) OR Legitimate Interest (Art. 6.1.f)
- CCPA: Optional - user can opt-out

**Data Types:** Behavioral, Technical
**Consent Required:** Yes (GDPR), Opt-out available (CCPA)
**User Control:** Can opt-out completely

**Examples:**
- Page view tracking
- Feature usage analysis
- A/B testing
- Performance monitoring

### 3. Marketing

**Definition:** Promotional communications and targeted advertising.

**Legal Basis:**
- GDPR: Consent (Art. 6.1.a)
- CCPA: Opt-out required

**Data Types:** Personal, Behavioral
**Consent Required:** Yes (always)
**User Control:** Can opt-out anytime

**Examples:**
- Email newsletters
- Promotional offers
- Targeted ads
- Remarketing campaigns

### 4. Legal

**Definition:** Compliance with legal obligations.

**Legal Basis:**
- GDPR: Legal obligation (Art. 6.1.c)
- CCPA: Exempt for legal compliance

**Data Types:** All categories
**Consent Required:** No (legal requirement)
**User Control:** Cannot opt-out

**Examples:**
- Tax reporting
- Financial record keeping
- Responding to subpoenas
- Regulatory compliance

### 5. Security

**Definition:** Protecting the platform and users from threats.

**Legal Basis:**
- GDPR: Legitimate interest (Art. 6.1.f)
- CCPA: Exempt for security

**Data Types:** Technical, Personal (limited)
**Consent Required:** No (legitimate interest)
**User Control:** Cannot opt-out

**Examples:**
- Fraud detection
- Spam prevention
- Intrusion detection
- Audit logging

## Classification Decision Tree

```
Is the data used to identify a person?
  ├─ YES → Personal
  └─ NO ↓

Is the data related to payments/transactions?
  ├─ YES → Financial
  └─ NO ↓

Is the data created by users?
  ├─ YES → Content
  └─ NO ↓

Is the data about user behavior?
  ├─ YES → Behavioral
  └─ NO ↓

Is the data system/operations related?
  └─ YES → Technical
```

## Implementation

### Automatic Classification

The `PrivacyService.classifyData(String dataType)` method provides automatic classification:

```dart
final category = PrivacyService().classifyData('email');
// Returns: DataCategory.personal

final category = PrivacyService().classifyData('transaction');
// Returns: DataCategory.financial
```

### Manual Classification

For new data types, update the classification map in `PrivacyService`:

```dart
const categoryMap = {
  'email': DataCategory.personal,
  'transaction': DataCategory.financial,
  'video': DataCategory.content,
  'page_view': DataCategory.behavioral,
  'system_log': DataCategory.technical,
  // Add new types here
};
```

## Data Lifecycle

```
Collection → Classification → Storage → Usage → Retention → Deletion
     ↓            ↓             ↓          ↓         ↓          ↓
  Consent    Determine      Apply     Check      Apply    Verify
  Check      Category      Security   Purpose  Retention Complete
             (Personal,     Controls   Allows   Policy   Deletion
             Financial,              Access
             etc.)
```

## Encryption Requirements

| Category | At Rest | In Transit | Tokenization | Key Rotation |
|----------|---------|------------|--------------|--------------|
| Personal | AES-256 | TLS 1.3 | Optional | Annual |
| Financial | AES-256 | TLS 1.3 | Required | Quarterly |
| Content | AES-256 | TLS 1.3 | No | Annual |
| Behavioral | Optional | TLS 1.3 | Recommended | Annual |
| Technical | Optional | TLS 1.3 | No | Annual |

## Cross-Border Transfers

### GDPR Considerations:

- **Personal & Financial:** May require Standard Contractual Clauses (SCCs)
- **EU data:** Prefer EU storage when possible
- **US data:** Adequate safeguards required (DPF, SCCs)

### Storage Locations:

| Region | Primary Storage | Backup Storage |
|--------|----------------|----------------|
| US | us-east-1 | us-west-2 |
| EU | eu-west-1 | eu-central-1 |

## Compliance Mapping

| Category | GDPR | CCPA | PCI-DSS | SOX |
|----------|------|------|---------|-----|
| Personal | ✅ High | ✅ Yes | N/A | N/A |
| Financial | ✅ High | ✅ Yes | ✅ Required | ✅ Required |
| Content | ✅ Medium | ✅ Yes | N/A | N/A |
| Behavioral | ✅ Consent | ✅ Opt-out | N/A | N/A |
| Technical | ⚠️ If PII | N/A | N/A | ⚠️ Audit logs |

## Training

All team members with data access must complete:
- Annual privacy training
- Data classification training
- Incident response training

## Auditing

- Quarterly: Review classification accuracy
- Annual: Full data inventory audit
- Continuous: Monitor access patterns

## Related Documents

- [DSAR Process](./dsar-process.md)
- [Consent Management](./consent-management.md)
- [Privacy Policy](../stories/03-2-privacy-legal-disclosures.md)
- [Security Policy](../security/security-policy.md)

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0.0 | Initial version | Amelia (Dev Agent) |

