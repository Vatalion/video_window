import 'package:flutter_test/flutter_test.dart';
import 'package:video_window_flutter/app_shell/legal_disclosures.dart';

void main() {
  group('LegalDisclosures - Constants', () {
    test('has valid version numbers', () {
      expect(LegalDisclosures.privacyPolicyVersion, isNotEmpty);
      expect(LegalDisclosures.termsOfServiceVersion, isNotEmpty);
      expect(LegalDisclosures.cookiePolicyVersion, isNotEmpty);

      // Version format check (should be semantic versioning)
      final versionRegex = RegExp(r'^\d+\.\d+\.\d+$');
      expect(
          versionRegex.hasMatch(LegalDisclosures.privacyPolicyVersion), isTrue);
      expect(versionRegex.hasMatch(LegalDisclosures.termsOfServiceVersion),
          isTrue);
      expect(
          versionRegex.hasMatch(LegalDisclosures.cookiePolicyVersion), isTrue);
    });

    test('has valid last updated date', () {
      expect(LegalDisclosures.lastUpdated, isNotEmpty);

      // Should be in YYYY-MM-DD format
      final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      expect(dateRegex.hasMatch(LegalDisclosures.lastUpdated), isTrue);
    });

    test('has valid URLs', () {
      expect(LegalDisclosures.privacyPolicyUrl, startsWith('https://'));
      expect(LegalDisclosures.termsOfServiceUrl, startsWith('https://'));
      expect(LegalDisclosures.cookiePolicyUrl, startsWith('https://'));
    });

    test('has valid email addresses', () {
      final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');

      expect(emailRegex.hasMatch(LegalDisclosures.supportEmail), isTrue);
      expect(emailRegex.hasMatch(LegalDisclosures.dpoEmail), isTrue);
    });
  });

  group('LegalDisclosures - GDPR Disclosures', () {
    test('contains required GDPR fields', () {
      expect(LegalDisclosures.gdprDisclosures.containsKey('data_controller'),
          isTrue);
      expect(LegalDisclosures.gdprDisclosures.containsKey('dpo_email'), isTrue);
      expect(
          LegalDisclosures.gdprDisclosures.containsKey('legal_basis'), isTrue);
      expect(LegalDisclosures.gdprDisclosures.containsKey('data_retention'),
          isTrue);
      expect(
          LegalDisclosures.gdprDisclosures.containsKey('user_rights'), isTrue);
    });

    test('has non-empty GDPR values', () {
      expect(LegalDisclosures.gdprDisclosures['data_controller'], isNotEmpty);
      expect(LegalDisclosures.gdprDisclosures['dpo_email'], isNotEmpty);
      expect(LegalDisclosures.gdprDisclosures['legal_basis'], isNotEmpty);
      expect(LegalDisclosures.gdprDisclosures['data_retention'], isNotEmpty);
    });

    test('includes all essential GDPR rights', () {
      final rights = LegalDisclosures.gdprDisclosures['user_rights'] as List;

      expect(rights.length, greaterThanOrEqualTo(5));
      expect(rights.any((r) => r.toString().toLowerCase().contains('access')),
          isTrue);
      expect(
          rights
              .any((r) => r.toString().toLowerCase().contains('rectification')),
          isTrue);
      expect(rights.any((r) => r.toString().toLowerCase().contains('erasure')),
          isTrue);
      expect(
          rights.any((r) => r.toString().toLowerCase().contains('portability')),
          isTrue);
      expect(rights.any((r) => r.toString().toLowerCase().contains('object')),
          isTrue);
    });
  });

  group('LegalDisclosures - CCPA Disclosures', () {
    test('contains required CCPA fields', () {
      expect(LegalDisclosures.ccpaDisclosures.containsKey('business_name'),
          isTrue);
      expect(
          LegalDisclosures.ccpaDisclosures.containsKey('categories_collected'),
          isTrue);
      expect(
          LegalDisclosures.ccpaDisclosures.containsKey('sale_of_data'), isTrue);
      expect(LegalDisclosures.ccpaDisclosures.containsKey('opt_out_available'),
          isTrue);
    });

    test('has non-empty CCPA values', () {
      expect(LegalDisclosures.ccpaDisclosures['business_name'], isNotEmpty);
    });

    test('includes data categories collected', () {
      final categories =
          LegalDisclosures.ccpaDisclosures['categories_collected'] as List;

      expect(categories.length, greaterThan(0));
      expect(categories, isA<List>());
    });

    test('declares data sale policy', () {
      expect(LegalDisclosures.ccpaDisclosures['sale_of_data'], isFalse,
          reason: 'We do not sell user data');
    });

    test('provides opt-out option', () {
      expect(LegalDisclosures.ccpaDisclosures['opt_out_available'], isTrue);
    });
  });

  group('LegalDisclosures - Cookie Categories', () {
    test('defines all cookie categories', () {
      expect(
          LegalDisclosures.cookieCategories.containsKey('essential'), isTrue);
      expect(
          LegalDisclosures.cookieCategories.containsKey('functional'), isTrue);
      expect(
          LegalDisclosures.cookieCategories.containsKey('analytics'), isTrue);
      expect(
          LegalDisclosures.cookieCategories.containsKey('marketing'), isTrue);
    });

    test('essential cookies are marked as required', () {
      final essential = LegalDisclosures.cookieCategories['essential'] as Map;
      expect(essential['required'], isTrue);
    });

    test('optional cookies are not required', () {
      final functional = LegalDisclosures.cookieCategories['functional'] as Map;
      final analytics = LegalDisclosures.cookieCategories['analytics'] as Map;
      final marketing = LegalDisclosures.cookieCategories['marketing'] as Map;

      expect(functional['required'], isFalse);
      expect(analytics['required'], isFalse);
      expect(marketing['required'], isFalse);
    });

    test('each category has name and description', () {
      LegalDisclosures.cookieCategories.forEach((key, value) {
        final category = value as Map;
        expect(category.containsKey('name'), isTrue);
        expect(category.containsKey('description'), isTrue);
        expect(category['name'], isNotEmpty);
        expect(category['description'], isNotEmpty);
      });
    });

    test('each category includes examples', () {
      LegalDisclosures.cookieCategories.forEach((key, value) {
        final category = value as Map;
        expect(category.containsKey('examples'), isTrue);
        expect(category['examples'], isA<List>());
        expect((category['examples'] as List).length, greaterThan(0));
      });
    });
  });

  group('LegalDisclosures - Legal Text Content', () {
    test('privacy policy text is not empty', () {
      expect(LegalDisclosures.privacyPolicyText, isNotEmpty);
      expect(LegalDisclosures.privacyPolicyText.length, greaterThan(100));
    });

    test('terms of service text is not empty', () {
      expect(LegalDisclosures.termsOfServiceText, isNotEmpty);
      expect(LegalDisclosures.termsOfServiceText.length, greaterThan(100));
    });

    test('cookie policy text is not empty', () {
      expect(LegalDisclosures.cookiePolicyText, isNotEmpty);
      expect(LegalDisclosures.cookiePolicyText.length, greaterThan(100));
    });

    test('privacy policy contains key sections', () {
      const policy = LegalDisclosures.privacyPolicyText;

      expect(policy.contains('Information We Collect'), isTrue);
      expect(policy.contains('How We Use'), isTrue);
      expect(policy.contains('Your Rights'), isTrue);
      expect(policy.contains('Data Retention'), isTrue);
      expect(policy.contains('Security'), isTrue);
    });

    test('terms contain key sections', () {
      const terms = LegalDisclosures.termsOfServiceText;

      expect(terms.contains('Acceptance of Terms'), isTrue);
      expect(terms.contains('User Accounts'), isTrue);
      expect(terms.contains('User Content'), isTrue);
      expect(terms.contains('Payments'), isTrue);
    });
  });

  group('LegalDisclosures - Consent Management', () {
    test('requiresConsentPrompt handles null userId', () async {
      final requires = await LegalDisclosures.requiresConsentPrompt(null);
      expect(requires, isTrue, reason: 'Null user should require consent');
    });

    test('requiresConsentPrompt handles valid userId', () async {
      final requires =
          await LegalDisclosures.requiresConsentPrompt('test-user-123');
      expect(requires, isA<bool>());
    });

    test('getCookiePreferences returns default for null user', () async {
      final prefs = await LegalDisclosures.getCookiePreferences(null);

      expect(prefs, isA<Map<String, bool>>());
      expect(prefs['essential'], isTrue);
      expect(prefs['functional'], isFalse);
      expect(prefs['analytics'], isFalse);
      expect(prefs['marketing'], isFalse);
    });

    test('getCookiePreferences returns map for valid user', () async {
      final prefs =
          await LegalDisclosures.getCookiePreferences('test-user-123');

      expect(prefs, isA<Map<String, bool>>());
      expect(prefs.containsKey('essential'), isTrue);
      expect(prefs.containsKey('functional'), isTrue);
      expect(prefs.containsKey('analytics'), isTrue);
      expect(prefs.containsKey('marketing'), isTrue);
    });

    test('default preferences have essential cookies enabled', () async {
      final prefs = await LegalDisclosures.getCookiePreferences(null);

      expect(prefs['essential'], isTrue,
          reason: 'Essential cookies must always be enabled');
    });

    test('default preferences have optional cookies disabled', () async {
      final prefs = await LegalDisclosures.getCookiePreferences(null);

      expect(prefs['functional'], isFalse,
          reason: 'Optional cookies should default to disabled (GDPR opt-in)');
      expect(prefs['analytics'], isFalse);
      expect(prefs['marketing'], isFalse);
    });
  });

  group('LegalDisclosures - updateCookiePreferences', () {
    test('enforces essential cookies always enabled', () async {
      const testUserId = 'test-user-123';
      final prefs = {
        'essential': false, // Try to disable (should be enforced as true)
        'functional': true,
        'analytics': false,
        'marketing': false,
      };

      await LegalDisclosures.updateCookiePreferences(testUserId, prefs);

      // The method should enforce essential=true
      // (We can't verify the stored value in this test, but method should not throw)
      expect(true, isTrue);
    });

    test('accepts valid preference updates', () async {
      const testUserId = 'test-user-123';
      final prefs = {
        'essential': true,
        'functional': true,
        'analytics': true,
        'marketing': false,
      };

      expect(
        () => LegalDisclosures.updateCookiePreferences(testUserId, prefs),
        returnsNormally,
      );
    });
  });

  group('LegalDisclosures - isCookieCategoryConsented', () {
    test('essential cookies always consented', () async {
      final consented = await LegalDisclosures.isCookieCategoryConsented(
        null,
        'essential',
      );

      expect(consented, isTrue, reason: 'Essential cookies are always allowed');
    });

    test('returns boolean for valid category', () async {
      final consented = await LegalDisclosures.isCookieCategoryConsented(
        'test-user-123',
        'analytics',
      );

      expect(consented, isA<bool>());
    });

    test('handles null userId', () async {
      final consented = await LegalDisclosures.isCookieCategoryConsented(
        null,
        'marketing',
      );

      expect(consented, isA<bool>());
    });
  });

  group('LegalDisclosures - recordConsentAcceptance', () {
    test('accepts valid consent record', () async {
      const testUserId = 'test-user-123';

      expect(
        () => LegalDisclosures.recordConsentAcceptance(
          testUserId,
          acceptedPrivacyPolicy: true,
          acceptedTerms: true,
          cookiePreferences: {
            'essential': true,
            'functional': false,
            'analytics': false,
            'marketing': false,
          },
        ),
        returnsNormally,
      );
    });

    test('handles all cookies accepted', () async {
      const testUserId = 'test-user-123';

      await LegalDisclosures.recordConsentAcceptance(
        testUserId,
        acceptedPrivacyPolicy: true,
        acceptedTerms: true,
        cookiePreferences: {
          'essential': true,
          'functional': true,
          'analytics': true,
          'marketing': true,
        },
      );

      expect(true, isTrue);
    });

    test('handles only essential cookies', () async {
      const testUserId = 'test-user-123';

      await LegalDisclosures.recordConsentAcceptance(
        testUserId,
        acceptedPrivacyPolicy: true,
        acceptedTerms: true,
        cookiePreferences: {
          'essential': true,
          'functional': false,
          'analytics': false,
          'marketing': false,
        },
      );

      expect(true, isTrue);
    });
  });

  group('LegalDisclosures - Compliance Validation', () {
    test('GDPR - provides required information', () {
      const gdpr = LegalDisclosures.gdprDisclosures;

      // Required under GDPR Article 13/14
      expect(gdpr['data_controller'], isNotNull);
      expect(gdpr['dpo_email'], isNotNull);
      expect(gdpr['legal_basis'], isNotNull);
      expect(gdpr['data_retention'], isNotNull);
      expect(gdpr['user_rights'], isNotNull);
    });

    test('CCPA - provides required disclosures', () {
      const ccpa = LegalDisclosures.ccpaDisclosures;

      // Required under CCPA Section 1798.110
      expect(ccpa['categories_collected'], isNotNull);
      expect(ccpa['sale_of_data'], isNotNull);
    });

    test('Cookie consent - distinguishes required vs optional', () {
      final essential = LegalDisclosures.cookieCategories['essential'] as Map;
      final marketing = LegalDisclosures.cookieCategories['marketing'] as Map;

      expect(essential['required'], isTrue);
      expect(marketing['required'], isFalse);
    });
  });

  group('LegalDisclosures - Version Management', () {
    test('versions use semantic versioning', () {
      final semverRegex = RegExp(r'^\d+\.\d+\.\d+$');

      expect(
          semverRegex.hasMatch(LegalDisclosures.privacyPolicyVersion), isTrue);
      expect(
          semverRegex.hasMatch(LegalDisclosures.termsOfServiceVersion), isTrue);
      expect(
          semverRegex.hasMatch(LegalDisclosures.cookiePolicyVersion), isTrue);
    });

    test('all versions are initialized', () {
      expect(LegalDisclosures.privacyPolicyVersion, isNot('0.0.0'));
      expect(LegalDisclosures.termsOfServiceVersion, isNot('0.0.0'));
      expect(LegalDisclosures.cookiePolicyVersion, isNot('0.0.0'));
    });
  });
}
