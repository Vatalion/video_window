# Epic 3: Profile & Settings Management - Technical Specification

**Epic Goal:** Provide comprehensive profile management with secure avatar/media handling, granular privacy controls, and notification preferences while maintaining PII protection and regulatory compliance.

**Stories:**
- 3.1: Viewer Profile Management
- 3.2: Avatar & Media Upload System
- 3.3: Privacy Settings & Controls
- 3.4: Notification Preferences
- 3.5: Account Settings Management

## Architecture Overview

### Component Mapping
- **Flutter App:** Profile Module (profile editing, privacy controls, notification preferences, avatar management)
- **Serverpod:** Profile Service (user data, privacy settings, preferences, media processing)
- **Database:** Users table, user_profiles table, user_privacy_settings table, user_notification_preferences table, media_files table
- **External:** AWS S3 (media storage), AWS KMS (encryption keys), SendGrid (email notifications), virus scanning service

### Technology Stack
- **Flutter:** cached_network_image 3.3.0, image_picker 1.0.4, flutter_secure_storage 9.2.0, flutter_file_picker 6.2.1
- **Serverpod:** Built-in file handling, encryption services, webhook handling
- **Security:** AES-256-GCM field-level encryption, AWS KMS key management, virus scanning with AWS Macie
- **Storage:** Encrypted S3 buckets with signed URLs, secure CDN distribution

## Data Models

### User Profile Entity
```dart
class UserProfile {
  final String id;
  final String userId;
  final String username;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final String? dateOfBirth; // Encrypted
  final String? phone; // Encrypted
  final String? location; // Encrypted
  final ProfileVisibility visibility;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum ProfileVisibility {
  public,
  friendsOnly,
  private,
}
```

### Privacy Settings Entity
```dart
class PrivacySettings {
  final String userId;
  final ProfileVisibility profileVisibility;
  final bool showEmailToPublic;
  final bool showPhoneToFriends;
  final bool allowTagging;
  final bool allowSearchByPhone;
  final bool allowDataAnalytics;
  final bool allowMarketingEmails;
  final bool allowPushNotifications;
  final bool shareProfileWithPartners;
  final List<String> blockedUsers;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Notification Preferences Entity
```dart
class NotificationPreferences {
  final String userId;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool inAppNotifications;
  final Map<String, NotificationSetting> settings;
  final QuietHours quietHours;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class NotificationSetting {
  final bool enabled;
  final NotificationFrequency frequency;
  final List<NotificationChannel> channels;
}

enum NotificationFrequency {
  instant,
  hourly,
  daily,
  weekly,
  never,
}

enum NotificationChannel {
  email,
  push,
  inApp,
}
```

### Media File Entity
```dart
class MediaFile {
  final String id;
  final String userId;
  final MediaFileType type;
  final String originalFileName;
  final String s3Key;
  final String? cdnUrl;
  final String mimeType;
  final int fileSizeBytes;
  final Map<String, dynamic> metadata;
  final MediaProcessingStatus status;
  final bool isVirusScanned;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum MediaFileType {
  avatar,
  banner,
  gallery,
}

enum MediaProcessingStatus {
  pending,
  processing,
  completed,
  failed,
}
```

### Profile Request/Response
```dart
class GetProfileResponse {
  final UserProfile profile;
  final PrivacySettings privacySettings;
  final NotificationPreferences notificationPreferences;
}

class UpdateProfileRequest {
  final String? fullName;
  final String? bio;
  final ProfileVisibility? visibility;
  final String? dateOfBirth; // Will be encrypted
  final String? phone; // Will be encrypted
  final String? location; // Will be encrypted
}

class UpdatePrivacySettingsRequest {
  final ProfileVisibility? profileVisibility;
  final bool? showEmailToPublic;
  final bool? showPhoneToFriends;
  final bool? allowTagging;
  final bool? allowSearchByPhone;
  final bool? allowDataAnalytics;
  final bool? allowMarketingEmails;
  final bool? allowPushNotifications;
  final bool? shareProfileWithPartners;
  final List<String>? blockedUsers;
}

class UpdateNotificationPreferencesRequest {
  final bool? emailNotifications;
  final bool? pushNotifications;
  final bool? inAppNotifications;
  final Map<String, NotificationSetting>? settings;
  final QuietHours? quietHours;
}
```

## API Endpoints

### Profile Management Endpoints
```
GET /users/me/profile
PUT /users/me/profile
GET /users/me/privacy-settings
PUT /users/me/privacy-settings
GET /users/me/notification-preferences
PUT /users/me/notification-preferences
GET /users/me/dsar/export
DELETE /users/me/dsar/delete
POST /users/me/avatar/upload
DELETE /users/me/avatar
GET /users/{userId}/public-profile
POST /users/me/blocked-users
DELETE /users/me/blocked-users/{userId}
```

### Endpoint Specifications

#### Get User Profile
```dart
// Request: GET /users/me/profile
// Headers: Authorization: Bearer <token>

// Response (200)
{
  "profile": {
    "id": "profile_id",
    "userId": "user_id",
    "username": "username",
    "fullName": "John Doe",
    "bio": "Video creator and enthusiast",
    "avatarUrl": "https://cdn.example.com/avatars/user_id.jpg",
    "visibility": "public",
    "isVerified": true,
    "createdAt": "2025-10-09T10:00:00Z",
    "updatedAt": "2025-10-09T10:00:00Z"
  },
  "privacySettings": { ... },
  "notificationPreferences": { ... }
}
```

#### Update User Profile
```dart
// Request: PUT /users/me/profile
{
  "fullName": "John Smith",
  "bio": "Updated bio description",
  "visibility": "public",
  "dateOfBirth": "1990-01-01",
  "phone": "+1234567890",
  "location": "San Francisco, CA"
}

// Response (200)
{
  "profile": { ... },
  "message": "Profile updated successfully"
}
```

#### Upload Avatar
```dart
// Request: POST /users/me/avatar/upload
// Content-Type: multipart/form-data
// Body: file (image/jpeg, image/png) + metadata

// Response (200)
{
  "mediaFile": {
    "id": "media_id",
    "cdnUrl": "https://cdn.example.com/avatars/user_id.jpg",
    "status": "completed",
    "fileSizeBytes": 1024000
  },
  "profile": {
    "avatarUrl": "https://cdn.example.com/avatars/user_id.jpg"
  }
}
```

#### DSAR Data Export
```dart
// Request: GET /users/me/dsar/export
// Headers: Authorization: Bearer <token>

// Response (200)
{
  "exportId": "export_id",
  "status": "processing",
  "createdAt": "2025-10-09T10:00:00Z",
  "estimatedCompletionAt": "2025-10-09T10:05:00Z"
}

// Response when ready (200)
{
  "exportId": "export_id",
  "status": "completed",
  "downloadUrl": "https://secure-cdn.example.com/exports/export_id.zip",
  "expiresAt": "2025-10-10T10:00:00Z",
  "fileSizeBytes": 2048000,
  "includedData": ["profile", "privacy_settings", "notifications", "activity_logs"]
}
```

## Implementation Details

### Flutter Profile Module Structure

#### Profile Management Flow
1. **Profile Loading:** Load user profile with privacy settings and notification preferences
2. **Profile Editing:** Real-time validation, auto-save, optimistic updates
3. **Avatar Upload:** File selection, validation, upload with progress, cropping
4. **Privacy Settings:** Granular controls with immediate effect and explanations
5. **Notification Preferences:** Matrix of settings with frequency controls
6. **DSAR Management:** Data export and deletion with audit logging

#### State Management (BLoC)
```dart
// Profile Events
abstract class ProfileEvent {}
class LoadProfileRequested extends ProfileEvent {}
class UpdateProfileRequested extends ProfileEvent {
  final UpdateProfileRequest request;
}
class UpdatePrivacySettingsRequested extends ProfileEvent {
  final UpdatePrivacySettingsRequest request;
}
class UpdateNotificationPreferencesRequested extends ProfileEvent {
  final UpdateNotificationPreferencesRequest request;
}
class UploadAvatarRequested extends ProfileEvent {
  final File imageFile;
}
class DeleteAvatarRequested extends ProfileEvent {}
class ExportDataRequested extends ProfileEvent {}
class DeleteAccountRequested extends ProfileEvent {}

// Profile States
abstract class ProfileState {}
class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}
class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final PrivacySettings privacySettings;
  final NotificationPreferences notificationPreferences;
}
class ProfileUpdating extends ProfileState {}
class ProfileUpdated extends ProfileState {}
class ProfileError extends ProfileState {
  final String message;
  final ProfileErrorType type;
}
```

#### Secure Storage Implementation
```dart
class ProfileSecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _encryptionKey = 'profile_data_encryption_key';

  static Future<void> saveEncryptedProfileData(
    Map<String, dynamic> data
  ) async {
    final encryptionKey = await _getOrCreateEncryptionKey();
    final encryptedData = await _encryptData(data, encryptionKey);
    await _storage.write(key: 'encrypted_profile_data', value: encryptedData);
  }

  static Future<Map<String, dynamic>?> getEncryptedProfileData() async {
    final encryptionKey = await _getOrCreateEncryptionKey();
    final encryptedData = await _storage.read(key: 'encrypted_profile_data');

    if (encryptedData != null) {
      return await _decryptData(encryptedData, encryptionKey);
    }
    return null;
  }

  static Future<String> _getOrCreateEncryptionKey() async {
    String? key = await _storage.read(key: _encryptionKey);
    if (key == null) {
      key = _generateSecureKey();
      await _storage.write(key: _encryptionKey, value: key);
    }
    return key;
  }
}
```

#### Avatar Upload Implementation
```dart
class AvatarUploadService {
  static Future<String> uploadAvatar(File imageFile) async {
    // Validate file
    final validation = await _validateImageFile(imageFile);
    if (!validation.isValid) {
      throw AvatarUploadException(validation.error);
    }

    // Get presigned upload URL
    final uploadUrl = await _getPresignedUploadUrl(imageFile);

    // Upload file to S3
    final uploadResult = await _uploadToS3(imageFile, uploadUrl);

    // Trigger processing and virus scanning
    await _triggerMediaProcessing(uploadResult.mediaId);

    return uploadResult.cdnUrl;
  }

  static Future<ImageValidationResult> _validateImageFile(File file) async {
    final bytes = await file.readAsBytes();
    final decodedImage = await decodeImageFromList(bytes);

    // Check file size (max 5MB)
    if (bytes.length > 5 * 1024 * 1024) {
      return ImageValidationResult(false, 'File size exceeds 5MB limit');
    }

    // Check file type
    final contentType = lookupMimeType(file.path);
    if (contentType != 'image/jpeg' && contentType != 'image/png') {
      return ImageValidationResult(false, 'Only JPEG and PNG images are supported');
    }

    // Check image dimensions
    if (decodedImage.width < 200 || decodedImage.height < 200) {
      return ImageValidationResult(false, 'Image must be at least 200x200 pixels');
    }

    return ImageValidationResult(true, null);
  }
}
```

### Serverpod Profile Service

#### Profile Management Service
```dart
class ProfileService {
  // Get user profile with privacy settings
  Future<GetProfileResponse> getProfile(String userId) async {
    final profile = await _profileRepository.findByUserId(userId);
    if (profile == null) {
      throw ProfileNotFoundException('Profile not found');
    }

    final privacySettings = await _privacyRepository.findByUserId(userId);
    final notificationPrefs = await _notificationRepository.findByUserId(userId);

    // Decrypt sensitive data
    final decryptedProfile = await _decryptSensitiveFields(profile);

    return GetProfileResponse(
      profile: decryptedProfile,
      privacySettings: privacySettings ?? PrivacySettings.defaults(),
      notificationPreferences: notificationPrefs ?? NotificationPreferences.defaults(),
    );
  }

  // Update user profile with security controls
  Future<UserProfile> updateProfile(
    String userId,
    UpdateProfileRequest request
  ) async {
    // Validate user ownership
    await _validateUserOwnership(userId);

    // Encrypt sensitive fields
    final encryptedRequest = await _encryptSensitiveFields(request);

    // Update profile
    final updatedProfile = await _profileRepository.update(
      userId,
      encryptedRequest,
    );

    // Log profile change
    await _auditLogger.logProfileChange(userId, request);

    return updatedProfile;
  }

  // Process avatar upload
  Future<MediaFile> processAvatarUpload(
    String userId,
    FileUploadData uploadData
  ) async {
    // Validate file
    await _validateUploadedFile(uploadData);

    // Virus scanning
    final scanResult = await _virusScanner.scan(uploadData.tempPath);
    if (scanResult.isInfected) {
      throw SecurityException('File failed virus scan');
    }

    // Process image (resize, optimize)
    final processedImage = await _imageProcessor.processAvatar(uploadData);

    // Upload to S3
    final s3Key = await _s3Service.uploadAvatar(
      userId,
      processedImage,
    );

    // Create media record
    final mediaFile = await _mediaRepository.create(
      MediaFile(
        userId: userId,
        type: MediaFileType.avatar,
        s3Key: s3Key,
        cdnUrl: processedImage.cdnUrl,
        mimeType: uploadData.mimeType,
        fileSizeBytes: processedImage.size,
        status: MediaProcessingStatus.completed,
        isVirusScanned: true,
      ),
    );

    // Update user profile
    await _profileRepository.updateAvatarUrl(userId, processedImage.cdnUrl);

    return mediaFile;
  }
}
```

#### Data Subject Access Request (DSAR) Service
```dart
class DSARService {
  // Export all user data
  Future<DSARExport> exportUserData(String userId) async {
    // Validate user ownership
    await _validateUserOwnership(userId);

    // Collect all user data
    final profile = await _getEncryptedUserProfile(userId);
    final privacySettings = await _privacyRepository.findByUserId(userId);
    final notificationPrefs = await _notificationRepository.findByUserId(userId);
    final activityLogs = await _activityRepository.findByUserId(userId);
    final mediaFiles = await _mediaRepository.findByUserId(userId);

    // Compile export data
    final exportData = {
      'profile': await _decryptForExport(profile),
      'privacySettings': privacySettings,
      'notificationPreferences': notificationPrefs,
      'activityLogs': activityLogs,
      'mediaFiles': mediaFiles.map((m) => m.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'exportVersion': '1.0',
    };

    // Create secure ZIP file
    final zipFile = await _createSecureExportFile(exportData, userId);

    // Generate secure download URL
    final downloadUrl = await _generateSecureDownloadUrl(zipFile);

    // Log DSAR export
    await _auditLogger.logDSARExport(userId, zipFile.id);

    return DSARExport(
      id: zipFile.id,
      downloadUrl: downloadUrl,
      expiresAt: DateTime.now().add(Duration(days: 7)),
      fileSizeBytes: zipFile.size,
    );
  }

  // Delete user data (Right to be Forgotten)
  Future<void> deleteUserData(String userId) async {
    // Validate user ownership and consent
    await _validateUserOwnership(userId);
    await _validateDeletionConsent(userId);

    // Begin deletion transaction
    await _database.transaction(() async {
      // Anonymize user profile
      await _profileRepository.anonymize(userId);

      // Delete sensitive data
      await _privacyRepository.delete(userId);
      await _notificationRepository.delete(userId);

      // Delete media files
      final mediaFiles = await _mediaRepository.findByUserId(userId);
      for (final mediaFile in mediaFiles) {
        await _s3Service.deleteFile(mediaFile.s3Key);
        await _mediaRepository.delete(mediaFile.id);
      }

      // Delete activity logs after retention period
      await _activityRepository.markForDeletion(userId);

      // Cancel active sessions
      await _sessionRepository.revokeAllSessions(userId);
    });

    // Log DSAR deletion
    await _auditLogger.logDSARDeletion(userId);
  }
}
```

## Security Implementation

### Field-Level Encryption
```dart
// lib/core/security/field_encryption.dart
class FieldEncryptionService {
  static final algorithm = AesGcm.with256bits();

  // Encrypt sensitive profile fields
  static Future<Map<String, dynamic>> encryptSensitiveFields(
    Map<String, dynamic> data
  ) async {
    final sensitiveFields = ['dateOfBirth', 'phone', 'location'];
    final encryptedData = Map<String, dynamic>.from(data);

    for (final field in sensitiveFields) {
      if (encryptedData.containsKey(field) && encryptedData[field] != null) {
        final encryptionKey = await _getUserEncryptionKey();
        final encryptedValue = await _encryptField(
          encryptedData[field].toString(),
          encryptionKey,
        );
        encryptedData['${field}_encrypted'] = encryptedValue;
        encryptedData.remove(field);
      }
    }

    return encryptedData;
  }

  // Decrypt sensitive profile fields
  static Future<Map<String, dynamic>> decryptSensitiveFields(
    Map<String, dynamic> encryptedData
  ) async {
    final sensitiveFields = ['dateOfBirth', 'phone', 'location'];
    final decryptedData = Map<String, dynamic>.from(encryptedData);

    for (final field in sensitiveFields) {
      final encryptedField = '${field}_encrypted';
      if (decryptedData.containsKey(encryptedField)) {
        final encryptionKey = await _getUserEncryptionKey();
        final decryptedValue = await _decryptField(
          decryptedData[encryptedField],
          encryptionKey,
        );
        decryptedData[field] = decryptedValue;
        decryptedData.remove(encryptedField);
      }
    }

    return decryptedData;
  }
}
```

### Secure Media Upload Pipeline
```dart
// lib/features/profile/security/secure_media_upload.dart
class SecureMediaUploadService {
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxImageDimension = 2048;

  static Future<MediaUploadResult> uploadSecureMedia(
    File imageFile,
    String userId,
  ) async {
    // Step 1: File validation
    final validationResult = await _validateFile(imageFile);
    if (!validationResult.isValid) {
      throw MediaUploadException(validationResult.error);
    }

    // Step 2: Virus scanning
    final scanResult = await _performVirusScan(imageFile);
    if (scanResult.isInfected) {
      throw SecurityException('File failed security scan');
    }

    // Step 3: Image processing and optimization
    final processedImage = await _processImage(imageFile);

    // Step 4: Generate signed upload URL
    final uploadUrl = await _generateSignedUploadUrl(
      userId,
      processedImage.fileName,
      processedImage.mimeType,
    );

    // Step 5: Upload to secure S3 bucket
    final s3Result = await _uploadToSecureS3(
      processedImage.data,
      uploadUrl,
      processedImage.mimeType,
    );

    // Step 6: Trigger CDN distribution
    final cdnUrl = await _triggerCDNDistribution(s3Result.key);

    return MediaUploadResult(
      cdnUrl: cdnUrl,
      fileSizeBytes: processedImage.data.length,
      dimensions: processedImage.dimensions,
      securityScanPassed: true,
    );
  }

  static Future<VirusScanResult> _performVirusScan(File file) async {
    // Integration with AWS Macie or similar scanning service
    final scanResult = await _virusScanningService.scan(file.path);
    return scanResult;
  }
}
```

### Privacy Control Enforcement
```dart
// lib/features/profile/security/privacy_enforcement.dart
class PrivacyEnforcementService {
  // Enforce privacy settings for profile access
  static Future<UserProfile> enforceProfilePrivacy(
    UserProfile profile,
    PrivacySettings privacySettings,
    String requestingUserId,
  ) async {
    if (requestingUserId == profile.userId) {
      return profile; // Full access to own profile
    }

    final filteredProfile = UserProfile.copyWith(profile);

    // Apply visibility settings
    switch (privacySettings.profileVisibility) {
      case ProfileVisibility.private:
        return _createPrivateProfile();
      case ProfileVisibility.friendsOnly:
        if (await _isFriend(requestingUserId, profile.userId)) {
          return _createFriendProfile(filteredProfile, privacySettings);
        }
        return _createPublicProfile(filteredProfile, privacySettings);
      case ProfileVisibility.public:
        return _createPublicProfile(filteredProfile, privacySettings);
    }
  }

  static UserProfile _createPublicProfile(
    UserProfile profile,
    PrivacySettings settings,
  ) {
    return UserProfile.copyWith(
      profile,
      fullName: settings.showEmailToPublic ? profile.fullName : null,
      bio: profile.bio,
      avatarUrl: profile.avatarUrl,
      // Remove sensitive fields
      dateOfBirth: null,
      phone: null,
      location: null,
    );
  }

  static UserProfile _createFriendProfile(
    UserProfile profile,
    PrivacySettings settings,
  ) {
    return UserProfile.copyWith(
      profile,
      fullName: profile.fullName,
      bio: profile.bio,
      avatarUrl: profile.avatarUrl,
      phone: settings.showPhoneToFriends ? profile.phone : null,
      location: profile.location,
      // Remove most sensitive fields
      dateOfBirth: null,
    );
  }
}
```

## Testing Strategy

### Unit Tests
- **Profile BLoC:** Test all state transitions, validation, and error handling
- **Encryption Service:** Test field encryption/decryption with various scenarios
- **Privacy Enforcement:** Test privacy filtering for different user types
- **Media Upload:** Test file validation, processing, and security scanning
- **DSAR Service:** Test data export and deletion workflows

### Integration Tests
- **Profile CRUD Operations:** End-to-end profile management with database
- **Avatar Upload Flow:** Complete upload pipeline with S3 integration
- **Privacy Controls:** Integration with privacy settings and data filtering
- **Notification Preferences:** Update and apply preferences across services
- **Security Scenarios:** Test encryption, access controls, and audit logging

### Security Tests
- **Field Encryption:** Verify sensitive data is encrypted at rest
- **Access Controls:** Test user ownership validation and permission checks
- **Data Leakage:** Ensure PII doesn't leak through logs or responses
- **File Upload Security:** Test virus scanning, file validation, and secure storage
- **DSAR Compliance:** Test data export completeness and deletion thoroughness

### Performance Tests
- **Profile Loading:** Test with large profiles and media collections
- **Avatar Upload:** Test upload performance with various file sizes
- **Concurrent Access:** Test multiple users updating profiles simultaneously
- **Caching:** Test profile data caching and invalidation strategies

## Error Handling

### Error Types
```dart
abstract class ProfileException implements Exception {
  final String message;
  final ProfileErrorCode code;
}

class ProfileNotFoundException extends ProfileException { }
class InvalidProfileDataException extends ProfileException { }
class UnauthorizedAccessException extends ProfileException { }
class MediaUploadException extends ProfileException { }
class SecurityException extends ProfileException { }
class DSARProcessingException extends ProfileException { }
class EncryptionException extends ProfileException { }
```

### Error Recovery
- **Network Errors:** Automatic retry with exponential backoff for profile updates
- **Upload Failures:** Resume upload from last successful chunk, fallback to retry
- **Privacy Setting Errors:** Maintain user privacy by default when settings are unavailable
- **Encryption Failures:** Secure fallback to previous profile version, log security incident
- **DSAR Errors:** Provide clear status updates and retry mechanisms

## Performance Considerations

### Client Optimizations
- **Profile Caching:** Cache profile data with intelligent invalidation
- **Avatar Caching:** Implement multi-level caching with cache-busting URLs
- **Lazy Loading:** Load privacy settings and notifications on demand
- **Image Optimization:** Progressive image loading and WebP format support
- **Optimistic Updates:** Immediate UI updates with server synchronization

### Server Optimizations
- **Database Indexing:** Optimized indexes on user_id, visibility settings, and timestamps
- **Redis Caching:** Cache frequently accessed profile data with TTL
- **CDN Distribution:** Global CDN for avatar and media files with cache headers
- **Background Processing:** Async image processing and virus scanning
- **Connection Pooling:** Efficient database connection management

## Monitoring and Analytics

### Key Metrics
- Profile completion rates and fields updated
- Avatar upload success rates and processing times
- Privacy setting changes and distribution analysis
- Notification preference modifications and engagement
- DSAR export/completion requests and processing times

### Analytics Events
```dart
// Profile Analytics Events
'profile_viewed' — params: profile_id, viewer_type — maps: Story 3.1
'profile_updated' — params: fields_updated, completion_score — maps: Story 3.1
'avatar_uploaded' — params: file_size, processing_time — maps: Story 3.2
'privacy_settings_changed' — params: setting_name, old_value, new_value — maps: Story 3.3
'notification_preferences_updated' — params: channel, frequency — maps: Story 3.4
'dsar_export_requested' — params: export_type, included_data — maps: Story 3.1
'dsar_deletion_requested' — params: confirmation_method — maps: Story 3.1
```

### Security Monitoring
- Failed access attempts and unauthorized profile access
- Encryption key rotation and management events
- File upload security violations and virus detection
- DSAR processing completion and audit trail verification
- Privacy setting changes and data access patterns

## Deployment Considerations

### Environment Variables
```dart
// Required Environment Variables
PROFILE_ENCRYPTION_KEY=your-profile-encryption-key
AWS_S3_PROFILE_BUCKET=your-secure-profile-bucket
AWS_KMS_KEY_ID=your-kms-key-id
VIRUS_SCANNING_API_KEY=your-virus-scanner-key
CDN_BASE_URL=https://cdn.example.com
DSAR_EXPORT_RETENTION_DAYS=7
AVATAR_MAX_SIZE_BYTES=5242880
```

### Database Migrations
```sql
-- User Profiles table
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  username VARCHAR(50) UNIQUE NOT NULL,
  full_name VARCHAR(100),
  bio TEXT,
  avatar_url TEXT,
  date_of_birth_encrypted TEXT,
  phone_encrypted TEXT,
  location_encrypted TEXT,
  visibility VARCHAR(20) DEFAULT 'public',
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Privacy Settings table
CREATE TABLE user_privacy_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  profile_visibility VARCHAR(20) DEFAULT 'public',
  show_email_to_public BOOLEAN DEFAULT false,
  show_phone_to_friends BOOLEAN DEFAULT false,
  allow_tagging BOOLEAN DEFAULT true,
  allow_search_by_phone BOOLEAN DEFAULT false,
  allow_data_analytics BOOLEAN DEFAULT true,
  allow_marketing_emails BOOLEAN DEFAULT false,
  allow_push_notifications BOOLEAN DEFAULT true,
  share_profile_with_partners BOOLEAN DEFAULT false,
  blocked_users JSONB DEFAULT '[]',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Notification Preferences table
CREATE TABLE user_notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email_notifications BOOLEAN DEFAULT true,
  push_notifications BOOLEAN DEFAULT true,
  in_app_notifications BOOLEAN DEFAULT true,
  settings JSONB DEFAULT '{}',
  quiet_hours JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Media Files table
CREATE TABLE media_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(20) NOT NULL,
  original_file_name VARCHAR(255) NOT NULL,
  s3_key VARCHAR(500) NOT NULL,
  cdn_url TEXT,
  mime_type VARCHAR(100) NOT NULL,
  file_size_bytes INTEGER NOT NULL,
  metadata JSONB DEFAULT '{}',
  status VARCHAR(20) DEFAULT 'pending',
  is_virus_scanned BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- DSAR Requests table
CREATE TABLE dsar_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  request_type VARCHAR(20) NOT NULL, -- 'export' or 'deletion'
  status VARCHAR(20) DEFAULT 'processing',
  download_url TEXT,
  expires_at TIMESTAMP,
  processing_started_at TIMESTAMP,
  processing_completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_user_profiles_username ON user_profiles(username);
CREATE INDEX idx_user_profiles_visibility ON user_profiles(visibility);
CREATE INDEX idx_user_privacy_settings_user_id ON user_privacy_settings(user_id);
CREATE INDEX idx_user_notification_preferences_user_id ON user_notification_preferences(user_id);
CREATE INDEX idx_media_files_user_id ON media_files(user_id);
CREATE INDEX idx_media_files_type ON media_files(type);
CREATE INDEX idx_media_files_status ON media_files(status);
CREATE INDEX idx_dsar_requests_user_id ON dsar_requests(user_id);
CREATE INDEX idx_dsar_requests_status ON dsar_requests(status);
```

## Success Criteria

### Functional Requirements
- ✅ Users can create and manage comprehensive profiles with avatar support
- ✅ Secure media upload system with virus scanning and file validation
- ✅ Granular privacy settings with GDPR/CCPA compliance
- ✅ Field-level encryption for sensitive PII data
- ✅ Complete DSAR functionality for data export and deletion
- ✅ Comprehensive notification preference management
- ✅ Role-based access controls ensuring user ownership validation
- ✅ Profile visibility controls with public/friend/private settings

### Non-Functional Requirements
- ✅ Profile data encryption at rest using AES-256-GCM
- ✅ All PII data protected with field-level encryption
- ✅ Avatar uploads complete within 10 seconds
- ✅ Profile updates reflect immediately across platforms
- ✅ 99.9% uptime for profile services
- ✅ Complete audit logging for all profile operations
- ✅ GDPR/CCPA compliant data handling and DSAR processing

### Success Metrics
- Profile completion rate > 80%
- Avatar upload success rate > 95%
- Average profile update time < 2 seconds
- Privacy setting change success rate > 99%
- DSAR processing completion within 24 hours
- User satisfaction score > 4.5/5
- Zero data breaches or PII leakage incidents

## Next Steps

1. **Implement Profile Module Foundation** - Data models, BLoC architecture, secure storage
2. **Develop Avatar Upload System** - File validation, processing, secure storage with virus scanning
3. **Create Privacy Controls** - Granular settings with enforcement and GDPR compliance
4. **Build Notification Preferences** - Matrix of settings with intelligent delivery
5. **Implement DSAR Functionality** - Data export, deletion, and audit logging
6. **Security Hardening** - Encryption, access controls, and comprehensive testing
7. **Performance Optimization** - Caching, CDN integration, and monitoring

**Dependencies:** Epic 1 (Viewer Authentication & Session Handling) for user authentication and session management
**Blocks:** Epic 4 (Content Creation & Publishing) for user content management integration

**Cross-References:**
- [Security Configuration](../architecture/security-configuration.md) - Encryption, access controls, and security measures
- [OpenAPI Specification](../architecture/openapi-spec.yaml) - API endpoints and data models
- [Compliance Guide](../compliance/compliance-guide.md) - GDPR/CCPA requirements and data protection
- [Front-End Architecture](../architecture/front-end-architecture.md) - BLoC patterns and state management
- [Database Architecture](../architecture/adr/ADR-0003-database-architecture.md) - Database schema and indexing