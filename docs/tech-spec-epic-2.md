# Epic 2: Maker Authentication & Access Control - Technical Specification

**Epic Goal:** Provide secure invitation-based maker onboarding with comprehensive role-based access control (RBAC), identity verification, and maker-specific authentication capabilities that extend the viewer authentication foundation.

**Stories:**
- 2.1: Maker Onboarding & Invitation Flow
- 2.2: RBAC Enforcement & Permission Management
- 2.3: Maker Identity Verification & KYC Processes
- 2.4: Maker Profile Management & Device Security

## Architecture Overview

### Component Mapping
- **Flutter App:** Maker Auth Module (invitation management, onboarding flows, role-based UI)
- **Serverpod:** Maker Access Service (invitation system, RBAC enforcement, verification workflows)
- **Database:** Users, maker_profiles, invitations, roles, permissions, verification_documents tables
- **External:** KYC verification services, document storage with encryption, email/SMS providers

### Technology Stack
- **Flutter:** Secure Storage 9.2.0, file_picker 6.1.1, image_picker 1.0.4
- **Serverpod:** Built-in authentication, custom invitation system, role-based middleware
- **Security:** HMAC-SHA256 invitation codes, end-to-end document encryption, RBAC with JWT claims
- **Storage:** Encrypted document storage, secure invitation code management
- **Verification:** Third-party KYC service integration with secure API handling

## Data Models

### Invitation Entity
```dart
class Invitation {
  final String id;
  final String code; // HMAC-SHA256 signed
  final String recipientEmail;
  final String inviterId;
  final List<String> assignedRoles;
  final InvitationStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? claimedAt;
  final String? claimedBy;
  final Map<String, dynamic>? metadata;
}

enum InvitationStatus {
  pending,
  claimed,
  expired,
  revoked,
  used
}
```

### Role & Permission Entities
```dart
class Role {
  final String id;
  final String name;
  final String description;
  final List<String> permissions;
  final String? parentRoleId; // For role hierarchy
  final int level; // For inheritance
  final bool isActive;
  final DateTime createdAt;
}

class Permission {
  final String id;
  final String name;
  final String resource;
  final String action;
  final String description;
  final String category;
}

class UserRole {
  final String id;
  final String userId;
  final String roleId;
  final String? assignedBy;
  final DateTime assignedAt;
  final DateTime? expiresAt;
  final bool isActive;
}
```

### Maker Profile Entity
```dart
class MakerProfile {
  final String id;
  final String userId;
  final String displayName;
  final String? businessName;
  final String? taxId;
  final String? ein;
  final String address;
  final String city;
  final String? state;
  final String? postalCode;
  final String? country;
  final MakerVerificationStatus verificationStatus;
  final Map<String, dynamic> businessInfo;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum MakerVerificationStatus {
  not_submitted,
  pending,
  under_review,
  verified,
  rejected,
  needs_more_info
}
```

### Verification Document Entity
```dart
class VerificationDocument {
  final String id;
  final String makerProfileId;
  final String documentType; // 'government_id', 'business_license', 'tax_document'
  final String fileName;
  final String encryptedFilePath;
  final String fileHash;
  final VerificationStatus status;
  final String? reviewedBy;
  final String? rejectionReason;
  final DateTime uploadedAt;
  final DateTime? reviewedAt;
  final Map<String, dynamic>? metadata;
}

enum VerificationStatus {
  uploaded,
  processing,
  approved,
  rejected,
  needs_more_info
}
```

## API Endpoints

### Invitation Management Endpoints
```
POST /invitations/create
POST /invitations/{code}/claim
GET /invitations/status/{code}
GET /invitations/list
POST /invitations/{id}/revoke
POST /invitations/{id}/resend
```

### Role & Permission Endpoints
```
GET /roles
POST /roles
PUT /roles/{id}
DELETE /roles/{id}
GET /permissions
POST /permissions
GET /users/{userId}/roles
POST /users/{userId}/roles
DELETE /users/{userId}/roles/{roleId}
```

### Maker Verification Endpoints
```
POST /maker/verification/documents/upload
GET /maker/verification/documents
PUT /maker/verification/documents/{id}
GET /maker/verification/status
POST /maker/verification/submit
GET /maker/profile
PUT /maker/profile
```

### Endpoint Specifications

#### Create Invitation
```dart
// Request
{
  "recipientEmail": "maker@example.com",
  "assignedRoles": ["basic_maker"],
  "expiresInDays": 7,
  "customMessage": "Welcome to our platform!",
  "metadata": {
    "source": "admin_invite",
    "campaign": "spring_2025"
  }
}

// Response
{
  "id": "invitation_uuid",
  "code": "HMAC-SHA256_signed_code",
  "expiresAt": "2025-01-16T10:00:00Z",
  "status": "pending",
  "trackingId": "tracking_uuid"
}
```

#### Claim Invitation
```dart
// Request
{
  "code": "HMAC-SHA256_signed_code",
  "deviceInfo": "iPhone 15 Pro",
  "acceptTerms": true
}

// Response
{
  "user": { ... },
  "makerProfile": { ... },
  "session": { ... },
  "roles": ["basic_maker"],
  "onboardingSteps": [
    "profile_setup",
    "identity_verification",
    "business_verification"
  ]
}
```

#### Upload Verification Document
```dart
// Request (multipart/form-data)
{
  "documentType": "government_id",
  "file": [encrypted_file_data],
  "metadata": {
    "documentNumber": "123456789",
    "issuingCountry": "US",
    "expirationDate": "2028-01-01"
  }
}

// Response
{
  "id": "document_uuid",
  "status": "processing",
  "uploadedAt": "2025-01-09T10:00:00Z",
  "estimatedProcessingTime": "5-10 minutes"
}
```

## Implementation Details

### Flutter Maker Auth Module Structure

#### Invitation Flow Implementation
1. **Admin Invitation Creation:** Admin selects maker → Assigns roles → Sets expiration → Sends invitation
2. **Maker Invitation Claim:** Maker receives email → Clicks link → Enters code → Creates account → Begins onboarding
3. **Invitation Security:** HMAC-SHA256 signed codes → One-time use → Rate limiting → Expiration enforcement
4. **Audit Logging:** All invitation events logged with timestamps, IP addresses, and user context

#### State Management (BLoC)
```dart
// Maker Auth Events
abstract class MakerAuthEvent {}
class CreateInvitationRequested extends MakerAuthEvent {
  final String email;
  final List<String> roles;
}
class ClaimInvitationRequested extends MakerAuthEvent {
  final String code;
}
class UploadVerificationDocumentRequested extends MakerAuthEvent {
  final String documentType;
  final File file;
}
class UpdateMakerProfileRequested extends MakerAuthEvent {
  final MakerProfile profile;
}

// Maker Auth States
abstract class MakerAuthState {}
class MakerAuthInitial extends MakerAuthState {}
class MakerAuthLoading extends MakerAuthState {}
class InvitationCreated extends MakerAuthState {
  final Invitation invitation;
}
class InvitationClaimed extends MakerAuthState {
  final User user;
  final MakerProfile profile;
}
class MakerProfileUpdated extends MakerAuthState {
  final MakerProfile profile;
}
class MakerAuthError extends MakerAuthState {
  final String error;
  final MakerAuthErrorType type;
}
```

#### Secure Invitation System
```dart
class InvitationService {
  static const String _hmacKey = 'invitations_hmac_secret_key';

  // Generate cryptographically secure invitation code
  String generateInvitationCode() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    final code = base64Url.encode(bytes);

    // Sign with HMAC-SHA256
    final hmac = Hmac(sha256, utf8.encode(_hmacKey));
    final signature = hmac.convert(utf8.encode(code));

    return '$code.${base64Url.encode(signature.bytes)}';
  }

  // Verify invitation code signature
  bool verifyInvitationCode(String signedCode) {
    final parts = signedCode.split('.');
    if (parts.length != 2) return false;

    final code = parts[0];
    final signature = base64Url.decode(parts[1]);

    final hmac = Hmac(sha256, utf8.encode(_hmacKey));
    final expectedSignature = hmac.convert(utf8.encode(code));

    return const ListEquality().equals(signature, expectedSignature.bytes);
  }
}
```

#### Role-Based UI Components
```dart
class RoleBasedWidget extends StatelessWidget {
  final Widget child;
  final List<String> requiredPermissions;
  final Widget? fallback;

  const RoleBasedWidget({
    required this.child,
    required this.requiredPermissions,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final userPermissions = state.user.roles
              .expand((role) => role.permissions)
              .toList();

          final hasPermission = requiredPermissions
              .every((permission) => userPermissions.contains(permission));

          if (hasPermission) {
            return child;
          } else {
            return fallback ?? const SizedBox.shrink();
          }
        }

        return const SizedBox.shrink();
      },
    );
  }
}
```

### Serverpod Maker Access Service

#### Invitation Management Service
```dart
class MakerAccessService {
  // Create secure invitation
  Future<Invitation> createInvitation({
    required String recipientEmail,
    required String inviterId,
    required List<String> assignedRoles,
    required int expiresInDays,
    Map<String, dynamic>? metadata,
  }) async {
    // Validate inviter permissions
    final inviter = await _userRepository.findById(inviterId);
    if (!inviter.hasPermission('invitations.create')) {
      throw AccessDeniedException('Insufficient permissions to create invitations');
    }

    // Generate secure invitation code
    final code = _invitationService.generateSecureCode();

    // Create invitation record
    final invitation = Invitation(
      id: _generateUuid(),
      code: code,
      recipientEmail: recipientEmail,
      inviterId: inviterId,
      assignedRoles: assignedRoles,
      status: InvitationStatus.pending,
      expiresAt: DateTime.now().add(Duration(days: expiresInDays)),
      createdAt: DateTime.now(),
      metadata: metadata,
    );

    await _invitationRepository.create(invitation);

    // Send invitation email
    await _emailService.sendInvitationEmail(
      recipientEmail,
      code,
      inviter.displayName,
      expiresInDays,
    );

    // Log invitation creation
    await _auditService.logInvitationCreated(invitation, inviterId);

    return invitation;
  }

  // Claim invitation with security checks
  Future<MakerOnboardingResult> claimInvitation({
    required String code,
    required String email,
    required String deviceInfo,
    required Map<String, dynamic> registrationData,
  }) async {
    // Verify invitation code signature
    if (!_invitationService.verifyCode(code)) {
      throw InvalidInvitationException('Invalid invitation code');
    }

    // Find and validate invitation
    final invitation = await _invitationRepository.findByCode(code);
    if (invitation == null) {
      throw InvitationNotFoundException('Invitation not found');
    }

    if (invitation.status != InvitationStatus.pending) {
      throw InvitationAlreadyUsedException('Invitation already claimed');
    }

    if (invitation.expiresAt.isBefore(DateTime.now())) {
      throw InvitationExpiredException('Invitation has expired');
    }

    if (invitation.recipientEmail.toLowerCase() != email.toLowerCase()) {
      throw InvitationMismatchException('Email does not match invitation');
    }

    // Check rate limiting
    if (await _rateLimitService.isRateLimited(email, 'invitation_claim')) {
      throw RateLimitExceededException('Too many claim attempts');
    }

    // Create user account
    final user = await _userService.createUser(
      email: email,
      roles: invitation.assignedRoles,
      authProvider: AuthProvider.email_otp,
      deviceInfo: deviceInfo,
      registrationData: registrationData,
    );

    // Create maker profile
    final makerProfile = await _makerProfileService.createProfile(
      userId: user.id,
      initialStatus: MakerVerificationStatus.not_submitted,
    );

    // Update invitation status
    invitation.status = InvitationStatus.claimed;
    invitation.claimedAt = DateTime.now();
    invitation.claimedBy = user.id;
    await _invitationRepository.update(invitation);

    // Create session
    final session = await _sessionService.createSession(user.id, deviceInfo);

    // Log invitation claim
    await _auditService.logInvitationClaimed(invitation, user.id);

    return MakerOnboardingResult(
      user: user,
      makerProfile: makerProfile,
      session: session,
      roles: invitation.assignedRoles,
      onboardingSteps: _getOnboardingSteps(invitation.assignedRoles),
    );
  }
}
```

#### Role-Based Access Control Implementation
```dart
class RBACService {
  // Check user permissions
  Future<bool> hasPermission(String userId, String permission) async {
    final userRoles = await _userRoleRepository.getActiveRoles(userId);

    for (final userRole in userRoles) {
      final role = await _roleRepository.findById(userRole.roleId);
      if (role != null && role.permissions.contains(permission)) {
        return true;
      }
    }

    return false;
  }

  // Get all user permissions (including inherited)
  Future<List<String>> getUserPermissions(String userId) async {
    final userRoles = await _userRoleRepository.getActiveRoles(userId);
    final allPermissions = <String>{};

    for (final userRole in userRoles) {
      final role = await _roleRepository.findById(userRole.roleId);
      if (role != null) {
        // Add direct permissions
        allPermissions.addAll(role.permissions);

        // Add inherited permissions from parent roles
        if (role.parentRoleId != null) {
          final parentPermissions = await _getInheritedPermissions(role.parentRoleId!);
          allPermissions.addAll(parentPermissions);
        }
      }
    }

    return allPermissions.toList();
  }

  // Assign role to user with audit logging
  Future<void> assignRole({
    required String userId,
    required String roleId,
    required String assignedBy,
    DateTime? expiresAt,
  }) async {
    // Validate assigner permissions
    if (!await hasPermission(assignedBy, 'roles.assign')) {
      throw AccessDeniedException('Insufficient permissions to assign roles');
    }

    // Validate role assignment rules
    final role = await _roleRepository.findById(roleId);
    if (role == null) {
      throw RoleNotFoundException('Role not found');
    }

    // Check for role conflicts
    if (await _hasConflictingRole(userId, roleId)) {
      throw RoleConflictException('Role conflicts with existing roles');
    }

    // Create user role assignment
    final userRole = UserRole(
      id: _generateUuid(),
      userId: userId,
      roleId: roleId,
      assignedBy: assignedBy,
      assignedAt: DateTime.now(),
      expiresAt: expiresAt,
      isActive: true,
    );

    await _userRoleRepository.create(userRole);

    // Log role assignment
    await _auditService.logRoleAssignment(userRole, assignedBy);
  }
}
```

## Security Implementation

### Cryptographic Invitation Codes
```dart
class InvitationCodeGenerator {
  static const int _codeLength = 32;
  static const String _hmacSecret = 'invitation_hmac_secret_key';

  String generateSecureCode() {
    // Generate cryptographically secure random bytes
    final random = Random.secure();
    final bytes = List<int>.generate(_codeLength, (i) => random.nextInt(256));

    // Create base64url-encoded code
    final code = base64Url.encode(bytes);

    // Create HMAC-SHA256 signature
    final hmac = Hmac(sha256, utf8.encode(_hmacSecret));
    final digest = hmac.convert(utf8.encode(code));
    final signature = base64Url.encode(digest.bytes);

    // Return combined code and signature
    return '$code.$signature';
  }

  bool verifyCode(String signedCode) {
    final parts = signedCode.split('.');
    if (parts.length != 2) return false;

    final code = parts[0];
    final providedSignature = base64Url.decode(parts[1]);

    // Compute expected signature
    final hmac = Hmac(sha256, utf8.encode(_hmacSecret));
    final expectedDigest = hmac.convert(utf8.encode(code));
    final expectedSignature = expectedDigest.bytes;

    // Constant-time comparison to prevent timing attacks
    return _constantTimeEquals(providedSignature, expectedSignature);
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }

    return result == 0;
  }
}
```

### Document Encryption & Storage
```dart
class DocumentEncryptionService {
  static const String _encryptionKey = 'document_encryption_key';

  Future<EncryptedDocument> encryptDocument(File document) async {
    // Generate random IV
    final iv = List<int>.generate(16, (i) => Random.secure().nextInt(256));

    // Generate file key
    final fileKey = List<int>.generate(32, (i) => Random.secure().nextInt(256));

    // Encrypt file key with master key
    final masterKey = await _getMasterKey();
    final encryptedFileKey = await _encryptWithAes(fileKey, masterKey);

    // Encrypt document with file key
    final documentBytes = await document.readAsBytes();
    final encryptedData = await _encryptWithAes(documentBytes, fileKey, iv);

    // Calculate file hash
    final fileHash = sha256.convert(documentBytes).toString();

    return EncryptedDocument(
      encryptedData: encryptedData,
      iv: iv,
      encryptedFileKey: encryptedFileKey,
      fileHash: fileHash,
      fileName: path.basename(document.path),
      mimeType: _lookupMimeType(document.path),
    );
  }

  Future<Uint8List> decryptDocument(EncryptedDocument encryptedDoc) async {
    // Decrypt file key with master key
    final masterKey = await _getMasterKey();
    final fileKey = await _decryptWithAes(encryptedDoc.encryptedFileKey, masterKey);

    // Decrypt document with file key
    return await _decryptWithAes(encryptedDoc.encryptedData, fileKey, encryptedDoc.iv);
  }
}
```

### RBAC JWT Token Structure
```dart
// JWT Token Claims for Makers
{
  "sub": "user_id",
  "email": "maker@example.com",
  "roles": ["basic_maker"],
  "permissions": [
    "content.create",
    "content.publish",
    "analytics.view",
    "orders.manage"
  ],
  "makerProfileId": "maker_profile_uuid",
  "verificationStatus": "verified",
  "roleLevel": 1,
  "iat": 1697049600,
  "exp": 1697050500,
  "sessionId": "session_uuid"
}
```

## Testing Strategy

### Unit Tests
- **Invitation Service:** Test code generation, verification, expiration, and rate limiting
- **RBAC Service:** Test permission checks, role inheritance, and assignment validation
- **Document Encryption:** Test encryption/decryption, key management, and hash verification
- **Maker Auth BLoC:** Test all state transitions and error handling

### Integration Tests
- **Invitation Flow:** End-to-end invitation creation, claiming, and onboarding
- **Role Assignment:** Test role assignment, permission inheritance, and access control
- **Document Upload:** Test secure upload, encryption, storage, and retrieval
- **Verification Workflow:** Test complete KYC verification process

### Security Tests
- **Invitation Code Security:** Test brute force protection, signature verification, and replay prevention
- **RBAC Enforcement:** Test privilege escalation attempts and unauthorized access prevention
- **Document Security:** Test encryption strength, key management, and data breach protection
- **Session Security:** Test session hijacking prevention and device binding

### Performance Tests
- **Invitation Load Testing:** Test system behavior under high invitation creation/claiming volume
- **Permission Lookup Performance:** Test permission resolution speed for complex role hierarchies
- **Document Upload Performance:** Test large file upload and encryption performance
- **Concurrent User Testing:** Test system behavior with multiple makers authenticating simultaneously

## Error Handling

### Error Types
```dart
abstract class MakerAuthException implements Exception {
  final String message;
  final MakerAuthErrorCode code;
}

class InvalidInvitationException extends MakerAuthException { }
class InvitationExpiredException extends MakerAuthException { }
class RoleConflictException extends MakerAuthException { }
class VerificationDocumentException extends MakerAuthException { }
class InsufficientPermissionsException extends MakerAuthException { }
```

### Error Recovery
- **Invalid Invitation Codes:** Provide clear error messages without revealing system information
- **Role Assignment Conflicts:** Suggest alternative roles or contact admin
- **Document Upload Failures:** Provide retry mechanism with file validation
- **Verification Rejections:** Clear guidance on required changes and appeal process

## Performance Considerations

### Client Optimizations
- Lazy loading of maker dashboard components
- Cached permission sets to reduce server requests
- Optimized document upload with progress indicators
- Background synchronization of profile data

### Server Optimizations
- Database indexes on invitation codes, user roles, and verification status
- Redis caching for frequently accessed permission sets
- Asynchronous document processing with queue management
- Connection pooling for verification service APIs

### Security Performance Balance
- Efficient permission caching with automatic invalidation
- Optimized HMAC verification using constant-time operations
- Batch permission checks for complex UI operations
- Secure session management with minimal overhead

## Monitoring and Analytics

### Key Metrics
- Invitation creation and conversion rates
- Maker verification success rates and processing times
- Role assignment frequency and permission usage
- Document upload success rates and processing times
- Authentication success/failure rates for makers
- Permission check frequency and performance

### Security Monitoring
- Failed invitation attempt patterns
- Suspicious document upload behavior
- Privilege escalation attempt detection
- Unusual access pattern recognition
- Authentication anomaly detection

### Logging Strategy
- Structured JSON logs with correlation IDs
- All invitation lifecycle events with full audit trail
- Role assignment changes with approver information
- Document processing events with status updates
- Permission check failures with security context

## Deployment Considerations

### Environment Variables
```dart
// Required Environment Variables
INVITATION_HMAC_SECRET=your-invitation-hmac-secret
DOCUMENT_ENCRYPTION_KEY=your-document-encryption-key
KYC_SERVICE_API_KEY=your-kyc-service-api-key
RBAC_CACHE_TTL=3600
INVITATION_DEFAULT_EXPIRY_DAYS=7
MAX_INVITATION_ATTEMPTS_PER_HOUR=5
DOCUMENT_MAX_SIZE_MB=50
```

### Database Migrations
```sql
-- Invitations table
CREATE TABLE invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(255) UNIQUE NOT NULL,
  recipient_email VARCHAR(255) NOT NULL,
  inviter_id UUID NOT NULL REFERENCES users(id),
  assigned_roles JSONB NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  claimed_at TIMESTAMPTZ,
  claimed_by UUID REFERENCES users(id),
  metadata JSONB
);

-- Roles table
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  permissions JSONB NOT NULL,
  parent_role_id UUID REFERENCES roles(id),
  level INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User roles table
CREATE TABLE user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  role_id UUID NOT NULL REFERENCES roles(id),
  assigned_by UUID REFERENCES users(id),
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  UNIQUE(user_id, role_id)
);

-- Maker profiles table
CREATE TABLE maker_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  display_name VARCHAR(255) NOT NULL,
  business_name VARCHAR(255),
  tax_id VARCHAR(100),
  ein VARCHAR(20),
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(50),
  postal_code VARCHAR(20),
  country VARCHAR(2),
  verification_status VARCHAR(50) DEFAULT 'not_submitted',
  business_info JSONB,
  preferences JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Verification documents table
CREATE TABLE verification_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  maker_profile_id UUID NOT NULL REFERENCES maker_profiles(id),
  document_type VARCHAR(50) NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  encrypted_file_path VARCHAR(500) NOT NULL,
  file_hash VARCHAR(128) NOT NULL,
  status VARCHAR(50) DEFAULT 'uploaded',
  reviewed_by UUID REFERENCES users(id),
  rejection_reason TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  metadata JSONB
);

-- Performance indexes
CREATE INDEX idx_invitations_code ON invitations(code);
CREATE INDEX idx_invitations_email ON invitations(recipient_email);
CREATE INDEX idx_invitations_status ON invitations(status);
CREATE INDEX idx_invitations_expires_at ON invitations(expires_at);
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);
CREATE INDEX idx_maker_profiles_user_id ON maker_profiles(user_id);
CREATE INDEX idx_maker_profiles_verification_status ON maker_profiles(verification_status);
CREATE INDEX idx_verification_documents_maker_profile_id ON verification_documents(maker_profile_id);
CREATE INDEX idx_verification_documents_status ON verification_documents(status);
```

### Security Configuration
- HMAC secret rotation with version support
- Document encryption key management with AWS KMS
- Role-based database access with least privilege
- API rate limiting for invitation endpoints
- Document upload virus scanning and validation

## Success Criteria

### Functional Requirements
- ✅ Admins can create secure invitations with role assignment
- ✅ Makers can claim invitations and complete onboarding flow
- ✅ RBAC system enforces permissions across all maker features
- ✅ Identity verification process with secure document handling
- ✅ Maker profile management with proper validation

### Non-Functional Requirements
- ✅ Invitation codes are cryptographically secure and non-guessable
- ✅ All verification documents are encrypted at rest and in transit
- ✅ Permission checks complete within 100ms for cached permissions
- ✅ Document upload completes within 30 seconds for files up to 50MB
- ✅ Comprehensive audit logging for all maker-related activities

### Success Metrics
- Invitation conversion rate > 80%
- Maker verification completion time < 24 hours
- Permission check success rate > 99.9%
- Document upload success rate > 95%
- Security incident rate < 0.1%
- User satisfaction score > 4.5/5 for onboarding experience

## Next Steps

1. **Implement Flutter Maker Auth Module** - BLoC, UI components, secure storage
2. **Develop Serverpod Maker Access Service** - Invitation system, RBAC enforcement
3. **Configure Document Security** - Encryption, storage, verification workflows
4. **Implement KYC Integration** - Third-party service integration, data handling
5. **Comprehensive Testing** - Unit, integration, security, and performance testing
6. **Performance Optimization** - Caching, database optimization, monitoring

**Dependencies:** Epic 1 (Viewer Authentication) for authentication foundation, Epic F2 (Core Platform Services) for design tokens and navigation, Epic F3 (Observability) for monitoring and logging

**Blocks:** Epic 3 (Content Creation & Publishing) depends on maker access control being established

---

*Document Version: v0.1*
*Last Updated: 2025-01-09*
*Author: Development Team*