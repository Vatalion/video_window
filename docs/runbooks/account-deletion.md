# Account Deletion Process

**Version:** 1.0.0  
**Last Updated:** 2025-11-10  
**Owner:** Privacy/Legal Team  
**Status:** Active

## Overview

This runbook documents the process for account deletion and data cleanup operations, implementing GDPR Article 17 (Right to Erasure) and CCPA Section 1798.105 (Right to Delete).

## Scope

Applies to all user-initiated account deletion requests through:
- Account Settings → Account → Delete Account
- DSAR deletion requests (Right to be Forgotten)
- Administrative account closure procedures

## Security Requirements

**CRITICAL:** All account deletion actions require re-authentication (OTP) if last authentication was more than 10 minutes ago.

### Re-authentication Flow
1. User initiates deletion request
2. System checks session age (`lastAuthTime`)
3. If `DateTime.now().difference(lastAuthTime) > Duration(minutes: 10)`:
   - Trigger OTP confirmation modal
   - Require OTP verification before proceeding
   - Log re-authentication event for audit

## Deletion Workflow

### Step 1: User Initiation & Verification
1. User navigates to Account Settings → Account tab
2. User clicks "Delete Account" or "Request Account Deletion"
3. System displays confirmation dialog with:
   - Warning about data loss
   - List of data that will be deleted
   - List of data that will be anonymized (retained for legal reasons)
   - Final confirmation checkbox
4. If session age > 10 minutes, require OTP verification
5. User confirms deletion request

### Step 2: Create Deletion Request Record
```dart
// Backend - video_window_server
final dsarRequest = DsarRequest(
  userId: userId,
  requestType: 'deletion',
  status: 'processing',
  requestedAt: DateTime.now().toUtc(),
  auditLog: json.encode({
    'deletionRequestedAt': DateTime.now().toUtc().toIso8601String(),
    'deletionRequestedBy': userId.toString(),
    'reAuthRequired': sessionAge > Duration(minutes: 10),
    'reAuthCompleted': otpVerified,
  }),
);
await DsarRequest.db.insertRow(session, dsarRequest);
```

### Step 3: Anonymize Profile Data
```dart
// Anonymize user profile (required for legal retention)
await UserProfile.db.updateWhere(
  session,
  where: (t) => t.userId.equals(userId),
  values: {
    'username': 'deleted_user_${userId}',
    'fullName': null,
    'bio': null,
    'avatarUrl': null,
    'dateOfBirthEncrypted': null,
    'phoneEncrypted': null,
    'locationEncrypted': null,
    'visibility': 'private',
    'isVerified': false,
  },
);
```

### Step 4: Delete Sensitive Data
```dart
// Delete privacy settings
await PrivacySettings.db.deleteWhere(
  session,
  where: (t) => t.userId.equals(userId),
);

// Delete notification preferences
await NotificationPreferences.db.deleteWhere(
  session,
  where: (t) => t.userId.equals(userId),
);
```

### Step 5: Delete Media Files
```dart
// Get all media files for user
final mediaFiles = await MediaFile.db.find(
  session,
  where: (t) => t.userId.equals(userId),
);

// Delete from S3 and database
for (final mediaFile in mediaFiles) {
  // Delete from S3
  await s3Service.deleteFile(mediaFile.s3Key);
  
  // Delete database record
  await MediaFile.db.deleteRow(session, mediaFile);
}
```

### Step 6: Revoke Sessions & Tokens
```dart
// Revoke all active sessions
await Session.db.deleteWhere(
  session,
  where: (t) => t.userId.equals(userId),
);

// Revoke refresh tokens
await RefreshToken.db.deleteWhere(
  session,
  where: (t) => t.userId.equals(userId),
);

// Revoke trusted devices
await TrustedDevice.db.deleteWhere(
  session,
  where: (t) => t.userId.equals(userId),
);
```

### Step 7: Queue Background Cleanup
```dart
// Queue background jobs for:
// - Activity log cleanup (after retention period)
// - Analytics data anonymization
// - Content anonymization (if required for other users' data)
await BackgroundJobService.enqueue(
  jobType: 'account_deletion_cleanup',
  userId: userId,
  priority: 'high',
  scheduledAt: DateTime.now().add(Duration(minutes: 15)),
);
```

### Step 8: Audit Logging
```dart
// Log account deletion event
await AuditLogger.log(
  eventType: 'account_deletion',
  userId: userId,
  metadata: {
    'deletionRequestedAt': DateTime.now().toUtc().toIso8601String(),
    'reAuthRequired': sessionAge > Duration(minutes: 10),
    'reAuthCompleted': otpVerified,
    'deletionCompletedAt': DateTime.now().toUtc().toIso8601String(),
  },
);

// Notify compliance team via audit stream
await EventBridge.publish(
  stream: 'audit.profile',
  event: {
    'type': 'account_deletion',
    'userId': userId,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  },
);
```

### Step 9: Update DSAR Request Status
```dart
// Mark deletion as completed
await DsarRequest.db.updateWhere(
  session,
  where: (t) => t.id.equals(dsarRequestId),
  values: {
    'status': 'completed',
    'processingCompletedAt': DateTime.now().toUtc(),
  },
);
```

### Step 10: User Confirmation
1. Display final confirmation screen:
   - "Your account has been deleted"
   - "All personal data has been removed"
   - "Some anonymized records may be retained for legal compliance"
   - "You can create a new account at any time"
2. Log user out automatically
3. Redirect to home/login screen

## Data Retention Exceptions

The following data is **anonymized** (not deleted) due to legal requirements:

### Financial Records (7-year retention)
- Transaction history (anonymized)
- Payment records (anonymized)
- Tax-related data (anonymized)

### Security & Compliance
- Audit logs (retained for security incidents)
- Records related to active legal disputes
- Fraud prevention records

### Content Retention
- User-generated content may be retained if:
  - Required for contract fulfillment with other users
  - Part of other users' data (e.g., comments on others' videos)
  - Required for legal claims

## Error Handling

### Deletion Failures
If deletion fails at any step:
1. Log error with full context
2. Update DSAR request status to 'failed'
3. Notify compliance team via audit stream
4. Allow user to retry deletion request
5. Provide support contact for manual processing

### Partial Deletion
If some data cannot be deleted:
1. Log which data failed to delete
2. Continue with remaining deletions
3. Notify user of partial completion
4. Escalate to manual cleanup if needed

## Performance Considerations

### Deletion Timeline
- **Immediate:** Profile anonymization, session revocation
- **Within 15 minutes:** Media deletion, privacy settings removal
- **Background (24 hours):** Activity log cleanup, analytics anonymization

### User Feedback
- Show progress indicator during deletion
- Provide estimated completion time
- Send email confirmation when complete

## Testing

### Test Scenarios
1. **Standard Deletion:** User with no active transactions
2. **Deletion with Active Transactions:** User with pending offers/purchases
3. **Deletion with Media:** User with uploaded avatars/media files
4. **Re-authentication Required:** Session age > 10 minutes
5. **Partial Failure:** Simulate S3 deletion failure
6. **Concurrent Deletion:** Multiple deletion requests for same user

### Verification
After deletion, verify:
- ✅ Profile is anonymized (not deleted)
- ✅ Privacy settings deleted
- ✅ Notification preferences deleted
- ✅ Media files deleted from S3 and database
- ✅ Sessions revoked
- ✅ DSAR request marked complete
- ✅ Audit log entry created
- ✅ Compliance team notified

## Related Documents

- [DSAR Process](./dsar-process.md) - General DSAR handling procedures
- [Tech Spec Epic 3](../tech-spec-epic-3.md) - Technical implementation details
- [Security Architecture](../architecture/adr/ADR-0009-security-architecture.md) - Security requirements
- [Compliance Guide](../compliance/compliance-guide.md) - GDPR/CCPA compliance

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0.0 | Initial version | Amelia (Dev Agent) |

