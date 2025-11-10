# Consent Management Procedures

**Version:** 1.0.0  
**Last Updated:** 2025-11-10  
**Owner:** Privacy/Legal Team  
**Status:** Active

## Overview

This document outlines how Craft Video Marketplace manages user consent for data processing in compliance with GDPR Article 7 and CCPA requirements.

## Legal Requirements

### GDPR (EU Users)

**Article 7 - Conditions for Consent:**
- Freely given
- Specific
- Informed
- Unambiguous indication of wishes
- Clear affirmative action required
- Easy to withdraw as to give
- Cannot be bundled with other terms
- Must keep records of consent

### CCPA (California Users)

**Section 1798.120 - Right to Opt-Out:**
- Clear notice before collection
- Opt-out mechanism required
- Cannot deny service for opting out
- Must honor Do Not Sell requests

## Consent Types

### 1. Essential Consent (Required)

**Purpose:** Necessary for service delivery  
**Legal Basis:** Contract performance (GDPR Art. 6.1.b)  
**User Control:** Cannot opt-out (service won't work)  
**Consent Required:** No (implicit through service use)

**Includes:**
- Account creation
- Authentication
- Basic service functionality
- Security measures
- Legal compliance

**Processing:**
```dart
ProcessingPurpose.serviceDelivery  // Always enabled
ProcessingPurpose.security         // Always enabled
ProcessingPurpose.legal            // Always enabled
```

### 2. Functional Consent (Optional)

**Purpose:** Enhanced features and personalization  
**Legal Basis:** Consent (GDPR Art. 6.1.a) or Legitimate Interest (Art. 6.1.f)  
**User Control:** Can opt-out  
**Consent Required:** Yes (best practice) or clear notice

**Includes:**
- Remember preferences
- Personalized experience
- Enhanced features
- Functional cookies

**Processing:**
```dart
ProcessingPurpose.serviceDelivery  // Subset for enhancements
```

### 3. Analytics Consent (Optional)

**Purpose:** Understanding user behavior  
**Legal Basis:** Consent (GDPR Art. 6.1.a) or Legitimate Interest (Art. 6.1.f)  
**User Control:** Must be able to opt-out  
**Consent Required:** Yes (recommended)

**Includes:**
- Usage analytics
- Performance monitoring
- A/B testing
- Heatmaps
- Session recording

**Processing:**
```dart
ProcessingPurpose.analytics  // Requires consent or opt-out
```

### 4. Marketing Consent (Optional)

**Purpose:** Promotional communications  
**Legal Basis:** Consent (GDPR Art. 6.1.a)  
**User Control:** Must opt-in (cannot be default)  
**Consent Required:** Yes (always)

**Includes:**
- Marketing emails
- Push notifications
- Targeted advertising
- Remarketing
- Newsletter

**Processing:**
```dart
ProcessingPurpose.marketing  // Always requires explicit consent
```

## Consent Collection

### At Account Creation

**Timing:** Before account is created

**Method:** Checkboxes with clear language

**Example:**
```
☐ I agree to the Terms of Service and Privacy Policy (Required)

☐ Send me updates, tips, and promotional offers (Optional)

☐ Allow analytics to improve my experience (Optional)
```

**Requirements:**
- ✅ Separate checkboxes for each purpose
- ✅ Pre-checked boxes prohibited for optional consent
- ✅ Clear description of what user is consenting to
- ✅ Link to full privacy policy and terms
- ❌ No "continued use constitutes acceptance" for GDPR

### Cookie Consent Banner

**Timing:** First visit to website/app

**Method:** Cookie consent banner (see `CookieConsentBanner` widget)

**Options:**
1. Accept All - Consent to all cookie categories
2. Reject Optional - Only essential cookies
3. Customize - Granular control per category

**Implementation:**
```dart
CookieConsentWrapper(
  userId: currentUser?.id,
  child: MainApp(),
)
```

**Storage:**
```dart
// Record consent
await LegalDisclosures.recordConsentAcceptance(
  userId,
  acceptedPrivacyPolicy: true,
  acceptedTerms: true,
  cookiePreferences: {
    'essential': true,
    'functional': userChoice,
    'analytics': userChoice,
    'marketing': userChoice,
  },
);
```

### In-App Consent Prompts

**Timing:** Before enabling specific feature

**Method:** Just-in-time consent prompts

**Example Scenarios:**
- Push notifications: "Enable notifications?"
- Location access: "Allow location for [specific reason]?"
- Camera access: "Allow camera for video upload?"

**Best Practices:**
- Explain WHY permission is needed
- Allow "Not now" option
- Don't ask repeatedly if denied

## Consent Storage

### Database Schema

```sql
CREATE TABLE consent_records (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  consent_timestamp TIMESTAMPTZ NOT NULL,
  privacy_policy_version VARCHAR(10) NOT NULL,
  terms_version VARCHAR(10) NOT NULL,
  cookie_policy_version VARCHAR(10) NOT NULL,
  accepted_privacy_policy BOOLEAN NOT NULL,
  accepted_terms BOOLEAN NOT NULL,
  cookie_preferences JSONB NOT NULL,
  purpose_consents JSONB NOT NULL,
  ip_address INET,
  user_agent TEXT,
  consent_method VARCHAR(50), -- 'banner', 'account_creation', 'settings'
  updated_at TIMESTAMPTZ NOT NULL,
  CONSTRAINT valid_cookie_prefs CHECK (
    cookie_preferences ? 'essential' AND 
    cookie_preferences->>'essential' = 'true'
  )
);

CREATE INDEX idx_consent_user_id ON consent_records(user_id);
CREATE INDEX idx_consent_timestamp ON consent_records(consent_timestamp);
```

### Record Contents

Each consent record must include:
- **User ID:** Who gave consent
- **Timestamp:** When consent was given
- **Version:** Which policy version was accepted
- **Specifics:** What exactly was consented to
- **Method:** How consent was collected (banner, checkbox, etc.)
- **Context:** IP address, user agent (for verification)

### Example Record

```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "consent_timestamp": "2025-11-10T14:30:00Z",
  "privacy_policy_version": "1.0.0",
  "terms_version": "1.0.0",
  "cookie_policy_version": "1.0.0",
  "accepted_privacy_policy": true,
  "accepted_terms": true,
  "cookie_preferences": {
    "essential": true,
    "functional": true,
    "analytics": false,
    "marketing": false
  },
  "purpose_consents": {
    "serviceDelivery": true,
    "analytics": false,
    "marketing": false,
    "legal": true,
    "security": true
  },
  "ip_address": "192.0.2.1",
  "user_agent": "Mozilla/5.0...",
  "consent_method": "cookie_banner"
}
```

## Consent Verification

Before processing data, verify consent:

```dart
// Check if user has consented to analytics
final canTrack = await LegalDisclosures.isCookieCategoryConsented(
  userId,
  'analytics',
);

if (canTrack) {
  // Track event
  Analytics.track('page_view', {...});
}
```

## Consent Withdrawal

### User-Initiated

**Access:** Account Settings → Privacy → Manage Consent

**Process:**
1. User modifies consent preferences
2. System updates consent record with new timestamp
3. Changes applied immediately across all systems
4. Confirmation shown to user

**Implementation:**
```dart
// User withdraws analytics consent
await PrivacyService().updateConsent(
  userId,
  {
    ProcessingPurpose.analytics: false,  // Withdrawn
    ProcessingPurpose.marketing: false,  // Still withdrawn
  },
);

// Stop analytics tracking immediately
await Analytics.disableTracking(userId);

// Delete existing analytics data
await Analytics.deleteUserData(userId);
```

### Automatic Withdrawal

**Scenarios:**
- Account deletion
- Consent expires (after 12 months, re-prompt)
- Terms updated (require re-acceptance)

## Consent Refresh

### When to Re-Prompt

1. **Policy Updates:** Privacy policy or terms change
2. **Consent Expiry:** 12 months since last consent
3. **Scope Expansion:** New processing purposes added
4. **User Request:** User wants to review/change

### Re-Prompt Process

```dart
// Check if consent needs refresh
final needsPrompt = await LegalDisclosures.requiresConsentPrompt(userId);

if (needsPrompt) {
  // Show consent banner again
  showCookieConsentBanner(context);
}
```

### Version Tracking

```dart
// Check if user accepted current version
SELECT * FROM consent_records
WHERE user_id = ?
  AND privacy_policy_version = '1.0.0'  -- Current version
ORDER BY consent_timestamp DESC
LIMIT 1;
```

## Consent for Minors

**Policy:** Service not available to users under 18

**Verification:**
- Age declaration at signup
- If suspected minor, request ID verification
- Immediate account suspension if minor confirmed

**Parental Consent:** Not applicable (18+ only service)

## Consent Across Channels

### Web + Mobile App

- Consent synchronized across all platforms
- Changes on web reflected in app immediately
- Single consent record per user

### Third-Party Services

When sharing data with third parties (e.g., Stripe):
- Ensure user consented to sharing
- Verify third party has compliant privacy policy
- Data Processing Agreement (DPA) required
- User can withdraw consent

## Consent Proof

### What to Record

For each consent event:
- ✅ User ID
- ✅ Timestamp (ISO 8601 UTC)
- ✅ IP address (for verification)
- ✅ User agent (browser/device)
- ✅ Consent method (how collected)
- ✅ Policy versions accepted
- ✅ Specific purposes consented to
- ✅ Cookie categories allowed

### Retention

- Consent records: Retained for 3 years after account deletion
- Purpose: Prove compliance if challenged
- Storage: Secure, encrypted, access-controlled

### Audit Trail

```sql
SELECT 
  user_id,
  consent_timestamp,
  consent_method,
  purpose_consents,
  cookie_preferences
FROM consent_records
WHERE user_id = ?
ORDER BY consent_timestamp DESC;
```

Shows complete consent history for audit purposes.

## Consent Management API

### Check Consent

```dart
// Get user's current consent preferences
final consents = await PrivacyService().getConsent(userId);
// Returns: Map<ProcessingPurpose, bool>

// Check specific cookie category
final analyticsOk = await LegalDisclosures.isCookieCategoryConsented(
  userId,
  'analytics',
);
```

### Update Consent

```dart
// Update consent preferences
await PrivacyService().updateConsent(
  userId,
  {
    ProcessingPurpose.analytics: true,   // Now consented
    ProcessingPurpose.marketing: false,  // Still rejected
  },
);

// Update cookie preferences
await LegalDisclosures.updateCookiePreferences(
  userId,
  {
    'essential': true,
    'functional': true,
    'analytics': true,   // Now allowed
    'marketing': false,
  },
);
```

### Record New Consent

```dart
// Record consent acceptance
await LegalDisclosures.recordConsentAcceptance(
  userId,
  acceptedPrivacyPolicy: true,
  acceptedTerms: true,
  cookiePreferences: {
    'essential': true,
    'functional': true,
    'analytics': false,
    'marketing': false,
  },
);
```

## Testing Consent Flows

### Test Cases

1. **New User Signup:**
   - Verify consent banner appears
   - Test "Accept All" path
   - Test "Reject Optional" path
   - Test "Customize" path
   - Verify consent recorded correctly

2. **Returning User:**
   - Verify banner doesn't show if already consented
   - Verify banner shows if policy updated
   - Verify banner shows if 12 months passed

3. **Consent Withdrawal:**
   - Verify user can change preferences
   - Verify analytics stops immediately
   - Verify data deleted if requested

4. **Cross-Platform:**
   - Change consent on web, verify on mobile
   - Change consent on mobile, verify on web

### Automated Tests

```dart
// Test consent recording
test('records consent correctly', () async {
  await LegalDisclosures.recordConsentAcceptance(
    'test-user-id',
    acceptedPrivacyPolicy: true,
    acceptedTerms: true,
    cookiePreferences: {'essential': true, 'analytics': false},
  );
  
  final prefs = await LegalDisclosures.getCookiePreferences('test-user-id');
  expect(prefs['analytics'], false);
});

// Test consent expiry
test('requires re-prompt after 12 months', () async {
  // Set consent timestamp to 13 months ago
  await _setConsentTimestamp('test-user-id', DateTime.now().subtract(Duration(days: 395)));
  
  final needsPrompt = await LegalDisclosures.requiresConsentPrompt('test-user-id');
  expect(needsPrompt, true);
});
```

## Compliance Checklist

- [ ] Consent obtained before processing non-essential data
- [ ] Separate opt-in for each purpose (no bundling)
- [ ] Easy to withdraw consent (same effort as giving)
- [ ] Consent records maintained for 3+ years
- [ ] Cookie banner appears before cookies set
- [ ] Essential cookies clearly identified
- [ ] Privacy policy linked from consent flows
- [ ] Consent synchronized across platforms
- [ ] Re-prompt on policy changes
- [ ] Marketing consent always opt-in (never default)
- [ ] Proof of consent stored securely
- [ ] Audit trail available for regulatory review

## Common Pitfalls

### ❌ Don't Do This:

1. **Pre-checked boxes** for optional consent
2. **Bundling** consent (e.g., "I agree to terms AND marketing")
3. **Continuing use = consent** language (not valid for GDPR)
4. **Hiding withdraw option** deep in settings
5. **Ignoring consent** after collecting it
6. **Forgetting to apply** consent changes immediately

### ✅ Do This:

1. **Separate checkboxes** for each purpose
2. **Clear language** explaining what user consents to
3. **Affirmative action** required (clicking button, checking box)
4. **Easy withdrawal** (one click in settings)
5. **Immediate application** of consent preferences
6. **Regular audits** of consent implementation

## Regional Variations

### EU (GDPR)

- Consent must be explicit (affirmative action)
- Withdrawing must be as easy as giving
- Cannot deny service for not consenting to non-essential processing
- 30 day window to respond to consent inquiries

### California (CCPA)

- Notice before collection
- Opt-out available for all non-essential processing
- "Do Not Sell My Personal Information" link required
- Cannot discriminate for opting out

### Brazil (LGPD)

- Similar to GDPR
- Explicit consent required
- Easy withdrawal required

### Other Jurisdictions

- Review local requirements
- Consult legal counsel
- Document compliance approach

## Related Documents

- [Privacy Policy](../stories/03-2-privacy-legal-disclosures.md)
- [DSAR Process](./dsar-process.md)
- [Data Classification](./data-classification.md)
- [Cookie Policy](../stories/03-2-privacy-legal-disclosures.md)

## Training

All team members must understand:
- When consent is required
- How to collect consent properly
- How to honor consent withdrawals
- Where consent records are stored
- How to handle consent-related support tickets

**Training Frequency:** Annually + when policies update

## Metrics

Track and report:
- % users accepting analytics vs rejecting
- % users accepting marketing vs rejecting
- Consent withdrawal rate
- Time to apply consent changes
- Support tickets related to consent

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0.0 | Initial version | Amelia (Dev Agent) |

