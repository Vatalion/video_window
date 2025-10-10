# Code Documentation Standards

## Overview

This document establishes comprehensive standards for code documentation across the Craft Video Marketplace project. Consistent documentation practices improve code maintainability, knowledge sharing, and team collaboration.

## Philosophy

### Documentation Principles
1. **Code is Documentation** - Well-written, self-documenting code is the primary documentation
2. **Complementary Documentation** - Comments and documentation complement, don't duplicate, the code
3. **Developer Experience** - Documentation should enhance the developer experience, not hinder it
4. **Maintenance Matters** - Documentation must be maintained alongside code changes

### When to Document
- **Always** - Public APIs, complex business logic, algorithms
- **Sometimes** - Non-obvious implementations, temporary workarounds
- **Never** - Self-evident code, getters/setters, simple functions

## Dart/Flutter Documentation Standards

### 1. File Header Documentation

Every Dart file should include a comprehensive header comment:

```dart
/// # Authentication Module - User Registration
///
/// This file contains the user registration functionality for the Craft Video Marketplace.
/// Handles email validation, password creation, and user profile initialization.
///
/// ## Features
/// - Email validation with disposable email detection
/// - Password strength requirements
/// - User profile creation
/// - Email verification workflow
///
/// ## Usage
/// ```dart
/// final registrationService = UserRegistrationService();
/// final result = await registrationService.registerUser(
///   email: 'user@example.com',
///   password: 'SecurePassword123!',
///   displayName: 'John Doe'
/// );
/// ```
///
/// ## Dependencies
/// - `package:formz/formz.dart` - Form validation
/// - `package:crypto/crypto.dart` - Password hashing
/// - `package:http/http.dart` - API communication
///
/// ## Architecture
/// This service follows the Repository pattern and integrates with the
/// Authentication BLoC for state management.
///
/// @author Flutter Team
/// @since v1.0.0
/// @see https://docs.craft.marketplace/auth/registration
library auth_registration;

import 'package:formz/formz.dart';
import 'package:crypto/crypto.dart';
```

### 2. Class Documentation

#### Public Classes
```dart
/// Manages user registration workflow and validation.
///
/// The [UserRegistrationService] handles the complete user registration process,
/// including input validation, account creation, and email verification.
///
/// ## Example
/// ```dart
/// final service = UserRegistrationService(
///   userRepository: mockRepository,
///   emailValidator: EmailValidator(),
/// );
///
/// final result = await service.registerUser(
///   email: 'user@example.com',
///   password: 'SecurePassword123!',
///   displayName: 'John Doe'
/// );
///
/// if (result.success) {
///   print('User registered successfully');
/// } else {
///   print('Registration failed: ${result.error}');
/// }
/// ```
///
/// ## Error Handling
/// Throws [RegistrationException] for validation errors and [ApiException]
/// for network-related failures.
///
/// ## Thread Safety
/// This class is thread-safe and can be shared across isolates.
///
/// @immutable
class UserRegistrationService {
  /// Creates a new [UserRegistrationService].
  ///
  /// [userRepository] handles user data persistence.
  /// [emailValidator] validates email format and domain.
  /// [passwordValidator] ensures password strength requirements.
  ///
  /// Throws [ArgumentError] if any dependency is null.
  const UserRegistrationService({
    required this.userRepository,
    required this.emailValidator,
    required this.passwordValidator,
  }) : assert(userRepository != null),
       assert(emailValidator != null),
       assert(passwordValidator != null);

  /// Repository for user data persistence operations.
  final UserRepository userRepository;

  /// Validator for email format and domain checking.
  final EmailValidator emailValidator;

  /// Validator for password strength requirements.
  final PasswordValidator passwordValidator;

  /// Registers a new user with the provided credentials.
  ///
  /// Validates input, creates user account, and sends verification email.
  ///
  /// ## Parameters
  /// - [email] User's email address (must be valid format)
  /// - [password] User's password (must meet strength requirements)
  /// - [displayName] User's display name (2-50 characters)
  ///
  /// ## Returns
  /// [RegistrationResult] containing success status and user data or error.
  ///
  /// ## Throws
  /// - [ValidationException] when input validation fails
  /// - [DuplicateUserException] when email already exists
  /// - [ApiException] for network/server errors
  ///
  /// ## Example
  /// ```dart
  /// try {
  ///   final result = await registerUser(
  ///     email: 'user@example.com',
  ///     password: 'SecurePass123!',
  ///     displayName: 'John Doe'
  ///   );
  ///
  ///   if (result.isEmailVerificationRequired) {
  ///     await _sendVerificationEmail(result.userId);
  ///   }
  /// } on ValidationException catch (e) {
  ///   _showValidationError(e.message);
  /// }
  /// ```
  Future<RegistrationResult> registerUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // Implementation...
  }
}
```

#### Private Classes
```dart
/// Internal validator for email format and disposable email detection.
///
/// Not exported from this library. Used only by [UserRegistrationService].
class _EmailValidator {
  /// Validates email format and checks against disposable email domains.
  ///
  /// Returns true for valid, non-disposable email addresses.
  bool isValid(String email) {
    // Implementation...
  }
}
```

### 3. Function/Method Documentation

#### Simple Functions
```dart
/// Calculates the total price including tax and shipping.
///
/// Returns the final amount the customer will be charged.
///
/// [basePrice] The item's base price in cents.
/// [taxRate] Tax rate as a decimal (e.g., 0.08 for 8%).
/// [shippingCost] Shipping cost in cents.
///
/// ```dart
/// final total = calculateTotalPrice(
///   basePrice: 10000, // $100.00
///   taxRate: 0.08,    // 8% tax
///   shippingCost: 500 // $5.00 shipping
/// );
/// print(total); // 11300 ($113.00)
/// ```
int calculateTotalPrice({
  required int basePrice,
  required double taxRate,
  required int shippingCost,
}) {
  final taxAmount = (basePrice * taxRate).round();
  return basePrice + taxAmount + shippingCost;
}
```

#### Complex Functions
```dart
/// Processes an auction bid with validation and state management.
///
/// This method performs comprehensive bid validation, updates auction state,
/// handles outbidding notifications, and manages bid history.
///
/// ## Process Flow
/// 1. Validate bid amount meets minimum requirements
/// 2. Verify user has sufficient funds
/// 3. Check auction timing and status
/// 4. Update auction state atomically
/// 5. Send notifications to outbid users
/// 6. Record bid in history
///
/// ## Validation Rules
/// - Bid must be at least current bid + minimum increment
/// - Bid cannot exceed user's maximum bid limit
/// - Auction must be in active state
/// - User cannot outbid themselves
///
/// ## Parameters
/// - [auctionId] Unique identifier of the auction
/// - [userId] ID of the user placing the bid
/// - [amount] Bid amount in local currency
/// - [maximumBid] User's maximum auto-bid amount (optional)
///
/// ## Returns
/// [BidResult] containing success status and updated auction state
///
/// ## Throws
/// - [BidValidationException] for invalid bid parameters
/// - [AuctionNotActiveException] when auction is not accepting bids
/// - [InsufficientFundsException] when user lacks funds
/// - [ConcurrentModificationException] for race conditions
///
/// ## Race Condition Handling
/// Uses optimistic locking with auction version numbers to prevent
/// concurrent bid placement conflicts.
///
/// ## Example
/// ```dart
/// try {
///   final result = await placeBid(
///     auctionId: 'auction_123',
///     userId: 'user_456',
///     amount: Money.fromDouble(150.00),
///     maximumBid: Money.fromDouble(200.00)
///   );
///
///   if (result.isNewHighBid) {
///     print('You are the highest bidder!');
///   }
/// } on BidValidationException catch (e) {
///   print('Invalid bid: ${e.message}');
/// }
/// ```
Future<BidResult> placeBid({
  required String auctionId,
  required String userId,
  required Money amount,
  Money? maximumBid,
}) async {
  // Implementation...
}
```

### 4. Variable and Property Documentation

#### Public Properties
```dart
class Auction {
  /// Current highest bid amount.
  ///
  /// This value is updated in real-time as new bids are placed.
  /// Use [highestBidderId] to identify the current leader.
  ///
  /// Will be `null` for auctions with no bids yet.
  Money? get currentHighestBid => _currentHighestBid;

  /// Unique identifier for the user with the highest bid.
  ///
  /// This user will win the auction if no higher bids are placed
  /// before the auction ends.
  ///
  /// Will be `null` when [currentHighestBid] is null.
  String? get highestBidderId => _highestBidderId;

  /// Minimum bid increment for this auction.
  ///
  /// New bids must be at least this amount higher than the current
  /// highest bid. This is typically 5-10% of the current bid.
  final Money minimumIncrement;

  /// Timestamp when this auction is scheduled to end.
  ///
  /// The auction may extend beyond this time if bids are placed
  /// within the soft-close period (typically 5 minutes).
  final DateTime scheduledEndTime;
}
```

#### Private Properties
```dart
class _BidValidator {
  /// Cache of recently validated email domains to improve performance.
  ///
  /// Key: domain name, Value: validation result
  /// Cache expires after 1 hour to ensure fresh results.
  final Map<String, bool> _domainValidationCache = {};

  /// Rate limiter to prevent abuse of validation API.
  ///
  /// Limits validation requests to 10 per minute per IP address.
  final RateLimiter _rateLimiter;
}
```

### 5. Enum Documentation

```dart
/// Represents the current state of an auction in the marketplace.
///
/// Each state has specific business rules and allowed transitions.
/// See [AuctionStateTransitions] for valid state changes.
///
/// ## State Diagram
/// ```
/// Draft → Scheduled → Active → Ended (→ Disputed)
///                ↓           ↓
///            Cancelled    Sold
/// ```
enum AuctionState {
  /// Auction is being created by the seller.
  ///
  /// Not visible to buyers. Can be edited or deleted.
  /// Transitions to: [Scheduled] or [Cancelled]
  draft,

  /// Auction is scheduled to start at a future time.
  ///
  /// Visible to buyers but bids cannot be placed yet.
  /// Transitions to: [Active] or [Cancelled]
  scheduled,

  /// Auction is currently active and accepting bids.
  ///
  /// Bids can be placed within auction rules.
  /// Transitions to: [Ended] or [Cancelled]
  active,

  /// Auction has ended without a winning bid.
  ///
  /// No bids met the reserve price or auction was cancelled.
  /// Transitions to: None (terminal state)
  ended,

  /// Auction has been sold to the highest bidder.
  ///
  /// Payment processing begins. Buyer and seller are notified.
  /// Transitions to: [Disputed] or [Completed]
  sold,

  /// Auction has been cancelled by the seller or system.
  ///
  /// All bids are refunded and the auction is removed from listings.
  /// Transitions to: None (terminal state)
  cancelled,

  /// Winner has initiated a dispute regarding the item or transaction.
  ///
  /// Marketplace admin intervention required.
  /// Transitions to: [Completed] or [Refunded]
  disputed,

  /// Transaction has been completed successfully.
  ///
  /// Payment processed, item delivered, both parties satisfied.
  /// Transitions to: None (terminal state)
  completed;

  /// Returns true if this state allows bid placement.
  bool get allowsBidding => this == active;

  /// Returns true if this state is a terminal state.
  bool get isTerminal => [ended, cancelled, completed, refunded].contains(this);

  /// Returns a user-friendly description of this state.
  String get description {
    switch (this) {
      case draft:
        return 'Draft - Being prepared by seller';
      case scheduled:
        return 'Scheduled - Awaiting start time';
      case active:
        return 'Active - Accepting bids';
      case ended:
        return 'Ended - No winning bid';
      case sold:
        return 'Sold - Awaiting payment';
      case cancelled:
        return 'Cancelled - Removed from marketplace';
      case disputed:
        return 'Disputed - Admin review required';
      case completed:
        return 'Completed - Transaction finished';
    }
  }
}
```

### 6. Widget Documentation

#### Flutter Widgets
```dart
/// A customizable video player widget for marketplace listings.
///
/// The [VideoPlayerWidget] provides a fully-featured video player with
/// controls optimized for product demonstrations. It includes:
/// - Custom play/pause controls
/// - Volume and fullscreen options
/// - Video quality selection
/// - Chapter markers for product features
/// - Share functionality
///
/// ## Features
/// - Adaptive bitrate streaming
/// - Picture-in-picture support (iOS 14+)
/// - AirPlay/Chromecast casting
/// - Accessibility support with VoiceOver
///
/// ## Usage
/// ```dart
/// VideoPlayerWidget(
///   videoUrl: 'https://cdn.example.com/product-demo.m3u8',
///   thumbnailUrl: 'https://cdn.example.com/product-thumb.jpg',
///   autoPlay: false,
///   showControls: true,
///   onVideoEnd: () => _showRelatedProducts(),
/// )
/// ```
///
/// ## Performance Considerations
/// - Uses [VideoPlayerController] for efficient memory management
/// - Implements proper disposal in [dispose] method
/// - Supports video caching for improved loading times
///
/// ## Accessibility
/// - Provides semantic labels for screen readers
/// - Supports high contrast mode
/// - Includes keyboard navigation
class VideoPlayerWidget extends StatefulWidget {
  /// Creates a new video player widget.
  ///
  /// [videoUrl] is the URL of the video stream (required).
  /// [thumbnailUrl] is displayed while video loads (optional).
  /// [autoPlay] starts playback automatically when true.
  /// [showControls] displays video control overlay.
  /// [aspectRatio] sets the video aspect ratio (default 16:9).
  /// [onVideoEnd] callback when video playback completes.
  ///
  /// Example:
  /// ```dart
  /// VideoPlayerWidget(
  ///   videoUrl: 'https://example.com/video.m3u8',
  ///   thumbnailUrl: 'https://example.com/thumb.jpg',
  ///   autoPlay: false,
  /// )
  /// ```
  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoPlay = false,
    this.showControls = true,
    this.aspectRatio = 16 / 9,
    this.onVideoEnd,
  }) : super(key: key);

  /// URL of the video to be played.
  ///
  /// Supports HTTP Live Streaming (HLS), DASH, and progressive formats.
  /// Must be a valid URL accessible by the client.
  final String videoUrl;

  /// URL of the thumbnail image displayed before video loads.
  ///
  /// If null, a default placeholder is shown.
  /// Recommended size: 1280x720 pixels for 16:9 videos.
  final String? thumbnailUrl;

  /// Whether video should start playing automatically.
  ///
  /// Note: Most browsers block autoplay with sound.
  /// Consider using [muted: true] with autoPlay for better compatibility.
  final bool autoPlay;

  /// Whether to show the video control overlay.
  ///
  /// Controls include play/pause, volume, fullscreen, and quality settings.
  /// Set to false for custom control implementations.
  final bool showControls;

  /// Aspect ratio of the video player.
  ///
  /// Default is 16:9. Use 4:3 for older content or square format for social media.
  final double aspectRatio;

  /// Callback function called when video playback reaches the end.
  ///
  /// Use this to trigger related content display or analytics events.
  final VoidCallback? onVideoEnd;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('videoUrl', videoUrl));
    properties.add(StringProperty('thumbnailUrl', thumbnailUrl));
    properties.add(FlagProperty('autoPlay', value: autoPlay));
    properties.add(FlagProperty('showControls', value: showControls));
    properties.add(DoubleProperty('aspectRatio', aspectRatio));
  }
}
```

## API Documentation Standards

### 1. Endpoint Documentation

```dart
/// Authentication endpoints for user management.
///
/// Provides RESTful API endpoints for user registration, login,
/// profile management, and security operations.
///
/// ## Base URL
/// `https://api.craft.marketplace/v1/auth`
///
/// ## Authentication
/// All endpoints (except `/register`) require a valid JWT token
/// in the `Authorization: Bearer <token>` header.
///
/// ## Rate Limiting
/// - Registration: 5 requests per IP per hour
/// - Login: 20 requests per IP per minute
/// - Other endpoints: 100 requests per user per minute
///
/// @since v1.0.0
/// @see https://docs.craft.marketplace/api/auth
class AuthApi {
  /// Registers a new user account.
  ///
  /// Creates a new user with the provided credentials and sends
  /// a verification email. The account will be in 'pending' status
  /// until email verification is completed.
  ///
  /// ## Endpoint
  /// `POST /auth/register`
  ///
  /// ## Request Body
  /// ```json
  /// {
  ///   "email": "user@example.com",
  ///   "password": "SecurePassword123!",
  ///   "displayName": "John Doe",
  ///   "agreeToTerms": true
  /// }
  /// ```
  ///
  /// ## Response (201 Created)
  /// ```json
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "userId": "uuid-v4",
  ///     "email": "user@example.com",
  ///     "displayName": "John Doe",
  ///     "status": "pending_verification",
  ///     "createdAt": "2024-01-15T10:30:00Z"
  ///   },
  ///   "message": "Registration successful. Please check your email."
  /// }
  /// ```
  ///
  /// ## Error Responses
  /// - **400 Bad Request**: Invalid input data
  /// - **409 Conflict**: Email already exists
  /// - **429 Too Many Requests**: Rate limit exceeded
  ///
  /// ## Example
  /// ```dart
  /// try {
  ///   final response = await authApi.register(
  ///     email: 'user@example.com',
  ///     password: 'SecurePassword123!',
  ///     displayName: 'John Doe'
  ///   );
  ///   print('User registered: ${response.data.userId}');
  /// } on ApiException catch (e) {
  ///   print('Registration failed: ${e.message}');
  /// }
  /// ```
  Future<ApiResponse<RegistrationResponse>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // Implementation...
  }
}
```

### 2. Model Documentation

```dart
/// Represents a user profile in the marketplace system.
///
/// Contains user information, preferences, and account status.
/// This model is used across frontend and backend for consistency.
///
/// ## JSON Serialization
/// This class supports JSON serialization for API communication.
///
/// ## Equality
/// Two [UserProfile] instances are considered equal if they have the same [id].
///
/// ## Immutability
/// All fields are final. Create new instances for updates.
///
/// @immutable
@JsonSerializable()
class UserProfile {
  /// Creates a new user profile.
  ///
  /// [id] Unique identifier (UUID v4)
  /// [email] User's email address (unique)
  /// [displayName] Public display name (2-50 characters)
  /// [avatarUrl] Profile picture URL (optional)
  /// [bio] User biography (max 500 characters)
  /// [createdAt] Account creation timestamp
  /// [updatedAt] Last update timestamp
  /// [status] Current account status
  /// [preferences] User-specific preferences
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
    this.status = UserStatus.active,
    this.preferences = const UserPreferences(),
  });

  /// Unique identifier for this user profile.
  ///
  /// Generated using UUID v4. This value never changes.
  final String id;

  /// User's email address.
  ///
  /// Must be unique across all users. Used for login and notifications.
  /// Never exposed in public API responses.
  final String email;

  /// Public display name shown in the marketplace.
  ///
  /// Must be between 2-50 characters. Cannot contain offensive content.
  /// Can be changed by the user at any time.
  final String displayName;

  /// URL to the user's profile picture.
  ///
  /// If null, a default avatar is used.
  /// Recommended size: 200x200 pixels.
  /// Supported formats: JPEG, PNG, WebP.
  final String? avatarUrl;

  /// User's biography or personal description.
  ///
  /// Optional field with maximum 500 characters.
  /// Supports basic Markdown formatting.
  final String? bio;

  /// Timestamp when this user account was created.
  ///
  /// Set during account creation and never changes.
  /// ISO 8601 format in UTC timezone.
  final DateTime createdAt;

  /// Timestamp when this profile was last updated.
  ///
  /// Automatically updated when any field changes.
  /// ISO 8601 format in UTC timezone.
  final DateTime updatedAt;

  /// Current status of this user account.
  ///
  /// Determines what actions the user can perform.
  /// See [UserStatus] for possible values and their meanings.
  final UserStatus status;

  /// User-specific preferences and settings.
  ///
  /// Includes notification preferences, privacy settings,
  /// display preferences, etc.
  final UserPreferences preferences;

  /// Creates a copy of this [UserProfile] with updated values.
  ///
  /// Any parameters provided will replace the corresponding
  /// values in the new instance. Unchanged values are preserved.
  ///
  /// ## Example
  /// ```dart
  /// final updatedProfile = profile.copyWith(
  ///   displayName: 'New Name',
  ///   bio: 'Updated biography'
  /// );
  /// ```
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserStatus? status,
    UserPreferences? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
    );
  }

  /// Converts this [UserProfile] to a JSON map.
  ///
  /// Used for API serialization and database storage.
  ///
  /// The [avatarUrl] and [bio] fields are omitted if null.
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  /// Creates a [UserProfile] from a JSON map.
  ///
  /// Used for API deserialization and database retrieval.
  ///
  /// Throws [FormatException] if required fields are missing or invalid.
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, displayName: $displayName)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('id', id));
    properties.add(StringProperty('email', email));
    properties.add(StringProperty('displayName', displayName));
    properties.add(StringProperty('avatarUrl', avatarUrl));
    properties.add(StringProperty('bio', bio));
    properties.add(DiagnosticsProperty<DateTime>('createdAt', createdAt));
    properties.add(DiagnosticsProperty<DateTime>('updatedAt', updatedAt));
    properties.add(EnumProperty<UserStatus>('status', status));
    properties.add(DiagnosticsProperty<UserPreferences>('preferences', preferences));
  }
}
```

## Code Review Documentation Standards

### 1. Pull Request Template

Create `.github/pull_request_template.md`:

```markdown
## 📝 Description
Brief description of changes made in this pull request.

## 🎯 Purpose
- [ ] Bug fix
- [ ] New feature
- [ ] Refactoring
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Security enhancement

## 📋 Changes Made
- Bullet point 1: Specific change made
- Bullet point 2: Another change
- etc.

## 🧪 Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Edge cases considered
- [ ] Performance testing (if applicable)

## 📸 Screenshots/Videos
(For UI changes)

## 🔗 Related Issues
Closes #123
Related to #456

## 📖 Documentation
- [ ] Code comments updated
- [ ] API documentation updated
- [ ] User documentation updated

## ⚠️ Breaking Changes
- [ ] Yes - describe impact
- [ ] No

## 🚀 Deployment Notes
- Database migrations required: Yes/No
- Configuration changes needed: Yes/No
- Rollback procedure: Description

## 📋 Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation is up to date
- [ ] Tests are passing
- [ ] No merge conflicts
- [ ] Ready for QA review
```

### 2. Code Review Guidelines

#### Reviewer Guidelines
```markdown
## Code Review Best Practices

### What to Look For
1. **Correctness**: Does the code work as intended?
2. **Performance**: Are there performance bottlenecks?
3. **Security**: Are there security vulnerabilities?
4. **Maintainability**: Is the code easy to understand and modify?
5. **Testing**: Are tests comprehensive and appropriate?
6. **Documentation**: Is code well-documented?

### Review Process
1. **First Pass**: High-level understanding and architecture
2. **Detailed Review**: Line-by-line analysis
3. **Testing**: Verify test coverage and quality
4. **Documentation**: Check documentation completeness
5. **Integration**: Consider impact on other parts of system

### Providing Feedback
- Be specific and constructive
- Explain the "why" behind suggestions
- Offer solutions, not just problems
- Use examples to illustrate points
- Recognize good work and improvements

### Approval Criteria
- Code works correctly
- Tests are comprehensive
- Documentation is complete
- Performance is acceptable
- Security considerations addressed
- Code follows project standards
```

## Pair Programming Guidelines

### 1. Pair Programming Setup

#### Driver/Navigator Roles
```markdown
## Pair Programming Best Practices

### Driver (Keyboard)
- Focus on implementation details
- Think aloud while coding
- Welcome suggestions and input
- Follow navigator's guidance
- Ask questions when uncertain

### Navigator (Observer)
- Focus on strategic direction
- Watch for potential issues
- Suggest improvements
- Keep track of remaining tasks
- Review code as it's written

### Session Management
- Switch roles every 25-30 minutes
- Take regular breaks
- Stay hydrated and comfortable
- Use screen sharing for remote pairing
- Record key decisions and insights

### Communication
- Be respectful and patient
- Explain your reasoning
- Listen actively
- Ask clarifying questions
- Keep an open mind to different approaches
```

### 2. Collaborative Development Tools

#### Live Share Configuration
```json
{
  "liveShare.enableGuestDebugging": true,
  "liveShare.enableGuestCommandHistory": true,
  "liveShare.enableGuestTerminal": true,
  "liveShare.allowGuestDebugControl": true
}
```

## Documentation Maintenance

### 1. Review Schedule

#### Regular Reviews
- **Weekly**: Code comment quality review
- **Monthly**: API documentation accuracy
- **Quarterly**: Documentation completeness audit
- **Annually**: Standards update and revision

#### Triggers for Review
- New feature implementation
- Major refactoring
- API changes
- Team onboarding
- External audit findings

### 2. Documentation Metrics

#### Quality Metrics
```dart
/// Metrics for documentation quality assessment.
class DocumentationMetrics {
  /// Percentage of public APIs with complete documentation
  final double apiDocumentationCoverage;

  /// Percentage of complex functions with examples
  final double exampleCoverage;

  /// Number of outdated documentation items
  final int outdatedItems;

  /// Documentation freshness (days since last update)
  final int averageAge;
}
```

### 3. Automated Documentation Checks

#### CI/CD Integration
```yaml
# .github/workflows/documentation-check.yml
name: Documentation Quality Check

on: [pull_request, push]

jobs:
  check-documentation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'

      - name: Check documentation coverage
        run: |
          dart run dartdoc
          dart run coverage:documentation

      - name: Validate code examples
        run: dart run validate_examples.dart

      - name: Check broken links
        run: dart run check_links.dart
```

## Training and Onboarding

### 1. Documentation Training Curriculum

#### New Developer Onboarding
```
Week 1: Documentation Basics
- Code comment standards
- When and what to document
- Documentation tools and workflows

Week 2: Advanced Documentation
- API documentation best practices
- Diagram and flowchart creation
- User documentation writing

Week 3: Documentation Maintenance
- Review processes
- Documentation updates
- Quality metrics

Week 4: Practical Application
- Document a real feature
- Participate in code review
- Create documentation for team
```

### 2. Reference Materials

#### Quick Reference Guide
```markdown
# Documentation Quick Reference

## File Headers
```dart
/// Brief one-line description
///
/// More detailed description of the file's purpose.
/// Include usage examples and important notes.
///
/// @author Team Name
/// @since v1.0.0
```

## Class Documentation
```dart
/// Brief description of the class.
///
/// Detailed description including:
/// - Purpose and responsibilities
/// - Usage examples
/// - Important notes and constraints
///
/// @immutable if applicable
class ClassName {
  /// Constructor documentation...
  const ClassName({
    required this.parameter,
  });

  /// Method documentation...
  ReturnType methodName() {
    // Implementation...
  }
}
```

## Method Documentation
```dart
/// Brief description of what the method does.
///
/// Detailed explanation if needed. Include usage examples.
///
/// ## Parameters
/// - [param1]: Description of parameter
/// - [param2]: Description of parameter
///
/// ## Returns
/// Description of return value
///
/// ## Throws
/// - [ExceptionType]: When this exception occurs
///
/// ## Example
/// ```dart
/// final result = methodName(param1: value1, param2: value2);
/// ```
ReturnType methodName({
  required Type param1,
  Type param2,
}) {
  // Implementation...
}
```
```

## Validation Checklist

### Code Documentation Quality
- [ ] All public APIs have complete documentation
- [ ] Documentation includes usage examples
- [ ] Complex algorithms are well-explained
- [ ] Error conditions are documented
- [ ] Performance considerations are noted
- [ ] Thread safety is documented where relevant
- [ ] Dependencies and integration points are clear

### Documentation Maintenance
- [ ] Documentation is kept in sync with code
- [ ] Outdated information is removed promptly
- [ ] Review processes are followed
- [ ] Quality metrics are tracked
- [ ] Team feedback is incorporated

### Team Training
- [ ] New developers receive documentation training
- [ ] Standards are regularly reviewed and updated
- [ ] Best practices are shared across the team
- [ ] Documentation tools are properly configured
- [ ] Quality metrics are monitored and improved

Remember: Good documentation is an investment in your team's future productivity and the maintainability of your codebase.