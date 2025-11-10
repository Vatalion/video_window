import 'dart:async';

/// Legal disclosure management for GDPR/CCPA compliance
///
/// Provides constants, URLs, and utilities for privacy policy,
/// terms of service, and cookie consent management.
class LegalDisclosures {
  // Version tracking
  static const privacyPolicyVersion = '1.0.0';
  static const termsOfServiceVersion = '1.0.0';
  static const cookiePolicyVersion = '1.0.0';
  static const lastUpdated = '2025-11-10';

  // Public URLs
  static const privacyPolicyUrl = 'https://craftvideomarketplace.com/privacy';
  static const termsOfServiceUrl = 'https://craftvideomarketplace.com/terms';
  static const cookiePolicyUrl = 'https://craftvideomarketplace.com/cookies';
  static const supportEmail = 'support@craftvideomarketplace.com';
  static const dpoEmail = 'dpo@craftvideomarketplace.com';

  /// GDPR disclosures for EU users
  static const gdprDisclosures = {
    'data_controller': 'Craft Video Marketplace, Inc.',
    'dpo_email': 'dpo@craftvideomarketplace.com',
    'legal_basis': 'Consent and legitimate interest',
    'data_retention': '2 years from last activity',
    'user_rights': [
      'Right to access',
      'Right to rectification',
      'Right to erasure',
      'Right to data portability',
      'Right to object',
      'Right to restrict processing',
    ],
    'supervisory_authority': 'Contact your local Data Protection Authority',
  };

  /// CCPA disclosures for California users
  static const ccpaDisclosures = {
    'business_name': 'Craft Video Marketplace, Inc.',
    'categories_collected': [
      'Identifiers (name, email, phone)',
      'Commercial information (purchase history)',
      'Internet activity (browsing, interactions)',
      'Geolocation data',
      'Audio and visual information (videos)',
    ],
    'sale_of_data': false,
    'opt_out_available': true,
    'contact_email': 'privacy@craftvideomarketplace.com',
  };

  /// Cookie categories and descriptions
  static const cookieCategories = {
    'essential': {
      'name': 'Essential Cookies',
      'description':
          'Required for the website to function properly. Cannot be disabled.',
      'required': true,
      'examples': ['session_id', 'auth_token', 'csrf_token'],
    },
    'functional': {
      'name': 'Functional Cookies',
      'description':
          'Enable personalized features and remember your preferences.',
      'required': false,
      'examples': ['language_preference', 'theme_preference'],
    },
    'analytics': {
      'name': 'Analytics Cookies',
      'description':
          'Help us understand how visitors use our website to improve user experience.',
      'required': false,
      'examples': ['_ga', '_gid', 'amplitude_session'],
    },
    'marketing': {
      'name': 'Marketing Cookies',
      'description':
          'Track visitors across websites to display relevant advertisements.',
      'required': false,
      'examples': ['_fbp', 'ads_preference'],
    },
  };

  /// Privacy policy full text
  static const String privacyPolicyText = '''
# Privacy Policy

**Last Updated:** $lastUpdated
**Version:** $privacyPolicyVersion

## 1. Introduction

Craft Video Marketplace, Inc. ("we", "our", "us") respects your privacy and is committed to protecting your personal data. This privacy policy explains how we collect, use, and protect your information.

## 2. Information We Collect

We collect the following types of information:

### Personal Information
- Name, email address, phone number
- Account credentials
- Profile information

### Financial Information
- Payment method details
- Transaction history
- Billing address

### User-Generated Content
- Videos you upload
- Offers you create
- Comments and reviews

### Usage Data
- Pages visited
- Features used
- Time spent on platform

### Technical Data
- IP address
- Browser type
- Device information
- Cookies and similar technologies

## 3. How We Use Your Information

We use your data for:
- Providing and improving our services
- Processing transactions
- Communicating with you
- Analytics and performance monitoring
- Security and fraud prevention
- Legal compliance

## 4. Legal Basis (GDPR)

For EU users, we process your data based on:
- Consent (when you accept cookies or marketing)
- Contract performance (to provide our services)
- Legitimate interests (fraud prevention, analytics)
- Legal obligations (tax, financial regulations)

## 5. Data Sharing

We may share your data with:
- Payment processors (Stripe)
- Cloud hosting providers (AWS)
- Analytics services (if consented)
- Legal authorities (when required by law)

We do not sell your personal data.

## 6. Your Rights

### GDPR Rights (EU Users)
- Right to access your data
- Right to rectification
- Right to erasure ("right to be forgotten")
- Right to data portability
- Right to object to processing
- Right to restrict processing

### CCPA Rights (California Users)
- Right to know what data we collect
- Right to delete your data
- Right to opt-out of data sales (we don't sell data)
- Right to non-discrimination

To exercise your rights, contact: $dpoEmail

## 7. Data Retention

We retain your data for:
- Active accounts: Duration of account plus 2 years
- Financial records: 7 years (legal requirement)
- Application logs: 90 days
- Marketing data: Until consent withdrawn

## 8. Security

We implement industry-standard security measures including:
- Encryption in transit (TLS)
- Encryption at rest (AES-256)
- Access controls and authentication
- Regular security audits

## 9. International Transfers

Your data may be transferred to and processed in countries outside your residence. We ensure adequate safeguards through standard contractual clauses.

## 10. Children's Privacy

Our service is not intended for users under 18. We do not knowingly collect data from children.

## 11. Changes to This Policy

We may update this policy. Changes will be posted with a new "Last Updated" date. Continued use constitutes acceptance.

## 12. Contact Us

For privacy questions or to exercise your rights:
- Email: $dpoEmail
- Support: $supportEmail

## 13. Supervisory Authority

EU users have the right to lodge a complaint with their local Data Protection Authority.
''';

  /// Terms of Service full text
  static const String termsOfServiceText = '''
# Terms of Service

**Last Updated:** $lastUpdated
**Version:** $termsOfServiceVersion

## 1. Acceptance of Terms

By accessing or using Craft Video Marketplace ("Service"), you agree to be bound by these Terms of Service.

## 2. Eligibility

You must be at least 18 years old to use this Service.

## 3. User Accounts

### Account Creation
- You must provide accurate information
- You are responsible for account security
- One account per person

### Account Termination
- We may suspend or terminate accounts for violations
- You may close your account at any time

## 4. User Content

### Content Ownership
- You retain ownership of content you upload
- You grant us a license to display and distribute your content

### Content Guidelines
- No illegal, harmful, or offensive content
- No copyright infringement
- No spam or misleading content

### Content Moderation
- We reserve the right to remove violating content
- Repeated violations may result in account termination

## 5. Marketplace Rules

### Sellers
- Must deliver items as described
- Must ship within agreed timeframes
- Must respond to buyer inquiries

### Buyers
- Must pay for items promptly
- Must provide accurate shipping information
- Must communicate issues in good faith

## 6. Payments

### Fees
- Service fees apply to transactions
- Payment processing fees (Stripe)
- Fees are non-refundable except as required by law

### Refunds
- Subject to our refund policy
- Disputes handled through our resolution process

## 7. Intellectual Property

### Our IP
- All Service trademarks and IP are owned by us
- You may not use without permission

### User IP
- You warrant that your content doesn't infringe third-party rights
- You indemnify us against IP claims

## 8. Disclaimers

THE SERVICE IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND.

## 9. Limitation of Liability

WE ARE NOT LIABLE FOR INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES.

## 10. Governing Law

These Terms are governed by the laws of Delaware, USA.

## 11. Dispute Resolution

Disputes will be resolved through binding arbitration, except where prohibited by law.

## 12. Changes to Terms

We may modify these Terms. Continued use constitutes acceptance of changes.

## 13. Contact

For questions about these Terms:
- Email: $supportEmail
''';

  /// Cookie policy full text
  static const String cookiePolicyText = '''
# Cookie Policy

**Last Updated:** $lastUpdated
**Version:** $cookiePolicyVersion

## What Are Cookies?

Cookies are small text files stored on your device when you visit our website.

## How We Use Cookies

We use cookies for:
- Essential site functionality
- Remembering your preferences
- Analytics and performance monitoring
- Security and fraud prevention

## Cookie Categories

### Essential Cookies (Required)
These cookies are necessary for the website to function and cannot be disabled.

### Functional Cookies (Optional)
These cookies enable enhanced features and personalization.

### Analytics Cookies (Optional)
These cookies help us understand how visitors use our site.

### Marketing Cookies (Optional)
These cookies are used to deliver relevant advertisements.

## Managing Cookies

You can control cookies through:
- Our cookie consent banner
- Your browser settings
- Your account privacy settings

Note: Disabling essential cookies will affect site functionality.

## Third-Party Cookies

We may use third-party services that set cookies:
- Google Analytics (if consented)
- Stripe (payment processing)

## More Information

For more information about our data practices, see our Privacy Policy.

## Contact

For questions about cookies:
- Email: $dpoEmail
''';

  // Consent management

  /// Check if user needs to see consent prompt
  ///
  /// Returns true if:
  /// - User has never accepted terms
  /// - Terms have been updated since last acceptance
  /// - Consent has expired (re-prompt after 1 year)
  static Future<bool> requiresConsentPrompt(String? userId) async {
    if (userId == null) return true;

    // TODO: Query database for user's consent record
    // Check if consent version matches current version
    // Check if consent was given in the last 12 months

    return false;
  }

  /// Record user's consent acceptance
  ///
  /// Stores:
  /// - Timestamp of acceptance
  /// - Versions accepted (privacy, terms, cookies)
  /// - Specific cookie preferences
  static Future<void> recordConsentAcceptance(
    String userId, {
    required bool acceptedPrivacyPolicy,
    required bool acceptedTerms,
    Map<String, bool>? cookiePreferences,
  }) async {
    // TODO: Store in database
    // INSERT INTO consent_records (user_id, timestamp, versions, preferences)
    // Example record structure:
    // {
    //   'user_id': userId,
    //   'timestamp': DateTime.now().toUtc().toIso8601String(),
    //   'privacy_policy_version': privacyPolicyVersion,
    //   'terms_version': termsOfServiceVersion,
    //   'cookie_policy_version': cookiePolicyVersion,
    //   'accepted_privacy_policy': acceptedPrivacyPolicy,
    //   'accepted_terms': acceptedTerms,
    //   'cookie_preferences': cookiePreferences ?? {
    //     'essential': true,
    //     'functional': false,
    //     'analytics': false,
    //     'marketing': false,
    //   },
    // }
  }

  /// Get user's current cookie preferences
  static Future<Map<String, bool>> getCookiePreferences(String? userId) async {
    if (userId == null) {
      // Default for non-authenticated users
      return {
        'essential': true,
        'functional': false,
        'analytics': false,
        'marketing': false,
      };
    }

    // TODO: Query from database
    return {
      'essential': true,
      'functional': false,
      'analytics': false,
      'marketing': false,
    };
  }

  /// Update user's cookie preferences
  static Future<void> updateCookiePreferences(
    String userId,
    Map<String, bool> preferences,
  ) async {
    // Ensure essential cookies always enabled
    preferences['essential'] = true;

    // TODO: Update database
    // UPDATE consent_records SET cookie_preferences = ? WHERE user_id = ?
  }

  /// Check if specific cookie category is consented
  static Future<bool> isCookieCategoryConsented(
    String? userId,
    String category,
  ) async {
    if (category == 'essential') return true;

    final preferences = await getCookiePreferences(userId);
    return preferences[category] ?? false;
  }
}
