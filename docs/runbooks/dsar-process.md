# Data Subject Access Request (DSAR) Process

**Version:** 1.0.0  
**Last Updated:** 2025-11-10  
**Owner:** Privacy/Legal Team  
**Status:** Active

## Overview

This runbook documents the process for handling Data Subject Access Requests (DSARs) under GDPR Article 15-20 and CCPA Section 1798.100-1798.150.

## Scope

Applies to all requests from users to:
- Access their personal data (GDPR Article 15, CCPA §1798.100)
- Correct their personal data (GDPR Article 16)
- Delete their personal data (GDPR Article 17, CCPA §1798.105)
- Port their personal data (GDPR Article 20, CCPA §1798.100)
- Restrict processing (GDPR Article 18)
- Object to processing (GDPR Article 21)

## Response Timeline

- **GDPR:** 30 days (can extend to 60 days if complex)
- **CCPA:** 45 days (can extend to 90 days with notice)
- **Internal SLA:** 15 days for standard requests

## Request Types

### 1. Right to Access (GDPR Art. 15, CCPA §1798.100)

**Request:** User wants to know what data we hold about them.

**Process:**
1. Verify user identity (email confirmation + account verification)
2. Run data export via `PrivacyService.exportUserData(userId)`
3. Generate comprehensive data package including:
   - User profile information
   - Content (videos, offers, comments)
   - Transaction history
   - Analytics data (if consented)
   - Consent history
4. Provide data in machine-readable format (JSON)
5. Document request completion in audit log

**Technical Implementation:**
```dart
// Backend - video_window_server
final privacyService = PrivacyService();
final userData = await privacyService.exportUserData(userId);

// Save to secure temporary location
final exportFile = await _generateExportFile(userData, userId);

// Send secure download link to user's verified email
await _sendExportLink(user.email, exportFile);
```

**Data Included:**
- Account: name, email, phone, address, created_at, status
- Profile: avatar, bio, preferences, settings
- Content: all videos uploaded, offers created, comments made
- Transactions: purchase history, sale history, payment records
- Analytics: page views, interactions (if consented)
- Consents: privacy policy acceptance, cookie preferences, marketing opt-in/out

### 2. Right to Erasure / Right to Delete (GDPR Art. 17, CCPA §1798.105)

**Request:** User wants their personal data deleted.

**Process:**
1. Verify user identity (strong authentication required)
2. Check if deletion exceptions apply:
   - Legal obligation to retain (e.g., financial records for 7 years)
   - Contract fulfillment (e.g., active transactions)
   - Legal claims (e.g., disputes)
3. If exceptions apply, explain to user what cannot be deleted and why
4. Run deletion process via `PrivacyService.deleteUserData(userId)`
5. Anonymize data that must be retained
6. Delete all non-essential personal data
7. Confirm deletion to user
8. Document in audit log

**Technical Implementation:**
```dart
// Backend - video_window_server
final privacyService = PrivacyService();

// This will:
// - Anonymize financial records (retained 7 years)
// - Delete personal profile data
// - Delete user-generated content (or anonymize if part of others' data)
// - Delete analytics data
// - Cancel subscriptions
// - Remove from marketing lists
await privacyService.deleteUserData(userId);

// Verify deletion
final remainingData = await _auditRemainingData(userId);
// Should only show anonymized records required by law
```

**What Gets Deleted:**
- ✅ Account profile (name, email, phone, bio)
- ✅ Personal preferences and settings
- ✅ User-generated content (videos, offers, comments)*
- ✅ Analytics and behavioral data
- ✅ Session history
- ✅ Marketing preferences

**What Gets Anonymized (Not Deleted):**
- 🔒 Financial transaction records (7 year retention required)
- 🔒 Audit logs for security incidents
- 🔒 Records related to active legal disputes

\* Content may be retained if required for contract fulfillment with other users

### 3. Right to Rectification (GDPR Art. 16)

**Request:** User wants to correct inaccurate personal data.

**Process:**
1. Verify user identity
2. Allow user to update their profile through account settings
3. For data not directly editable, process correction request manually
4. Update records within 5 business days
5. Notify any third parties if data was shared
6. Confirm correction to user
7. Log in audit trail

**Self-Service Options:**
- Profile information: Users can edit directly in app
- Email address: Change via account settings (requires verification)
- Phone number: Change via account settings (requires verification)

**Manual Processing Required:**
- Transaction records (contact support)
- Historical data corrections

### 4. Right to Data Portability (GDPR Art. 20, CCPA §1798.100)

**Request:** User wants their data in a portable format to transfer to another service.

**Process:**
1. Verify user identity
2. Generate data export in machine-readable format (JSON)
3. Include only data provided by user or generated through their use
4. Provide secure download link
5. Data expires after 7 days for security

**Format:** JSON with standard schema

### 5. Right to Restrict Processing (GDPR Art. 18)

**Request:** User wants to limit how we process their data.

**Process:**
1. Verify user identity
2. Flag account for restricted processing
3. Maintain data but limit processing to:
   - Storage only
   - Legal claims
   - Rights of others
   - Public interest
4. Notify user before lifting restriction

### 6. Right to Object (GDPR Art. 21)

**Request:** User objects to processing based on legitimate interest or marketing.

**Process:**
1. Verify user identity
2. Stop processing unless compelling legitimate grounds
3. For marketing: Always stop immediately, no questions asked
4. Update consent preferences
5. Confirm to user

**Marketing Opt-Out:**
- Immediate cessation of marketing emails
- Remove from all marketing lists
- Update preferences to block future marketing

## Identity Verification

**Critical:** Always verify identity before fulfilling DSAR to prevent unauthorized access.

### Verification Methods:

1. **Email Verification:**
   - Send verification link to registered email
   - User must click within 24 hours

2. **Account Login:**
   - User must log in with their password
   - 2FA if enabled

3. **Additional Verification (if needed):**
   - Security questions
   - Government ID (for sensitive requests)
   - Phone verification

### High-Risk Requests:

For deletion or portability requests, use **enhanced verification**:
- Email verification + account login
- May require government ID for accounts with significant transaction history

## Request Handling Workflow

```
1. Request Received
   ↓
2. Log Request (create ticket)
   ↓
3. Verify Identity
   ↓
4. Assess Request Type
   ↓
5. Check for Exceptions/Conflicts
   ↓
6. Process Request (automated or manual)
   ↓
7. Generate Response
   ↓
8. Deliver to User
   ↓
9. Document Completion
   ↓
10. Close Ticket
```

## Contact Channels

Users can submit DSARs via:
- Email: dpo@craftvideomarketplace.com
- In-app: Account Settings → Privacy → Submit Request
- Web form: https://craftvideomarketplace.com/privacy/dsar

## Audit Trail

All DSARs must be logged with:
- Request date/time
- User ID and verification method
- Request type
- Processing time
- Response date
- Outcome (fulfilled, partially fulfilled, denied with reason)
- Staff member who processed

**Storage:** DSAR audit logs retained for 3 years.

## Exceptions and Limitations

We may refuse or limit a DSAR if:
- Identity cannot be verified
- Request is manifestly unfounded or excessive
- Legal obligation requires data retention
- Request conflicts with rights of others
- Required for legal claims or public interest

**If refusing:** Must inform user within 30 days with explanation and their right to complain to supervisory authority.

## Supervisory Authorities

### GDPR (EU):
Users can complain to their local Data Protection Authority.
- List: https://edpb.europa.eu/about-edpb/board/members_en

### CCPA (California):
Users can contact California Attorney General.
- Phone: (916) 210-6276
- Web: https://oag.ca.gov/contact/consumer-complaint-against-business-or-company

## Team Responsibilities

- **DPO (Data Protection Officer):** Oversee DSAR compliance, handle escalations
- **Privacy Team:** Process routine DSARs, verify identity
- **Engineering:** Maintain automated DSAR tools, assist with complex extractions
- **Legal:** Review edge cases, handle disputes
- **Support:** First point of contact, triage requests

## Automation

The `PrivacyService` class provides automated support for:
- Data export: `exportUserData(userId)`
- Data deletion: `deleteUserData(userId)`
- Consent management: `updateConsent(userId, consents)`

Manual intervention required for:
- Identity verification
- Exception handling
- Edge cases and disputes

## Metrics to Track

- Number of DSARs per month (by type)
- Average response time
- % fulfilled within SLA
- % requiring manual intervention
- User satisfaction with process

## Testing

Test DSAR process quarterly:
1. Submit test request as fake user
2. Verify identity verification works
3. Check data export completeness
4. Verify deletion removes appropriate data
5. Confirm audit logging

## Related Documents

- [Data Classification Framework](./data-classification.md)
- [Consent Management Procedures](./consent-management.md)
- [Privacy Policy](../stories/03-2-privacy-legal-disclosures.md)
- [Tech Spec Epic 03](../tech-spec-epic-03.md)

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|---------|
| 2025-11-10 | 1.0.0 | Initial version | Amelia (Dev Agent) |

