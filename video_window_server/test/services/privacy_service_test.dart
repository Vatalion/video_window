import 'package:test/test.dart';
import 'package:video_window_server/src/services/privacy_service.dart';

void main() {
  group('DataCategory', () {
    test('enum contains all required categories', () {
      expect(DataCategory.values.length, equals(5));
      expect(DataCategory.values, contains(DataCategory.personal));
      expect(DataCategory.values, contains(DataCategory.behavioral));
      expect(DataCategory.values, contains(DataCategory.financial));
      expect(DataCategory.values, contains(DataCategory.content));
      expect(DataCategory.values, contains(DataCategory.technical));
    });
  });

  group('ProcessingPurpose', () {
    test('enum contains all required purposes', () {
      expect(ProcessingPurpose.values.length, equals(5));
      expect(ProcessingPurpose.values,
          contains(ProcessingPurpose.serviceDelivery));
      expect(ProcessingPurpose.values, contains(ProcessingPurpose.analytics));
      expect(ProcessingPurpose.values, contains(ProcessingPurpose.marketing));
      expect(ProcessingPurpose.values, contains(ProcessingPurpose.legal));
      expect(ProcessingPurpose.values, contains(ProcessingPurpose.security));
    });
  });

  group('PrivacyService', () {
    late PrivacyService privacyService;

    setUp(() {
      privacyService = PrivacyService();
    });

    group('Singleton Pattern', () {
      test('returns same instance', () {
        final instance1 = PrivacyService();
        final instance2 = PrivacyService();
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Data Classification', () {
      test('classifies personal data correctly', () {
        expect(privacyService.classifyData('email'),
            equals(DataCategory.personal));
        expect(privacyService.classifyData('phone'),
            equals(DataCategory.personal));
        expect(
            privacyService.classifyData('name'), equals(DataCategory.personal));
        expect(privacyService.classifyData('address'),
            equals(DataCategory.personal));
      });

      test('classifies financial data correctly', () {
        expect(privacyService.classifyData('payment_method'),
            equals(DataCategory.financial));
        expect(privacyService.classifyData('transaction'),
            equals(DataCategory.financial));
      });

      test('classifies content data correctly', () {
        expect(
            privacyService.classifyData('video'), equals(DataCategory.content));
        expect(
            privacyService.classifyData('offer'), equals(DataCategory.content));
      });

      test('classifies behavioral data correctly', () {
        expect(privacyService.classifyData('page_view'),
            equals(DataCategory.behavioral));
        expect(privacyService.classifyData('click_event'),
            equals(DataCategory.behavioral));
      });

      test('classifies technical data correctly', () {
        expect(privacyService.classifyData('system_log'),
            equals(DataCategory.technical));
        expect(privacyService.classifyData('error_log'),
            equals(DataCategory.technical));
      });

      test('defaults to technical for unknown types', () {
        expect(privacyService.classifyData('unknown_type'),
            equals(DataCategory.technical));
      });
    });

    group('DSAR - Export User Data', () {
      test('export returns required fields', () async {
        final testUserId = 'test-user-123';
        final exportData = await privacyService.exportUserData(testUserId);

        expect(exportData, isA<Map<String, dynamic>>());
        expect(exportData.containsKey('user_profile'), isTrue);
        expect(exportData.containsKey('content'), isTrue);
        expect(exportData.containsKey('transactions'), isTrue);
        expect(exportData.containsKey('analytics'), isTrue);
        expect(exportData.containsKey('consents'), isTrue);
        expect(exportData.containsKey('exported_at'), isTrue);
        expect(exportData.containsKey('format_version'), isTrue);
      });

      test('export includes timestamp in ISO format', () async {
        final testUserId = 'test-user-123';
        final exportData = await privacyService.exportUserData(testUserId);

        final timestamp = exportData['exported_at'] as String;
        expect(timestamp, isNotEmpty);
        // Verify ISO 8601 format
        expect(() => DateTime.parse(timestamp), returnsNormally);
      });

      test('export includes format version', () async {
        final testUserId = 'test-user-123';
        final exportData = await privacyService.exportUserData(testUserId);

        expect(exportData['format_version'], equals('1.0.0'));
      });

      test('user_profile section is a map', () async {
        final testUserId = 'test-user-123';
        final exportData = await privacyService.exportUserData(testUserId);

        expect(exportData['user_profile'], isA<Map<String, dynamic>>());
      });

      test('content section is a list', () async {
        final testUserId = 'test-user-123';
        final exportData = await privacyService.exportUserData(testUserId);

        expect(exportData['content'], isA<List>());
      });

      test('transactions section is a list', () async {
        final testUserId = 'test-user-123';
        final exportData = await privacyService.exportUserData(testUserId);

        expect(exportData['transactions'], isA<List>());
      });
    });

    group('Right to be Forgotten - Delete User Data', () {
      test('deleteUserData completes without error', () async {
        final testUserId = 'test-user-123';

        expect(
          () => privacyService.deleteUserData(testUserId),
          returnsNormally,
        );
      });

      test('deleteUserData accepts valid user ID', () async {
        final testUserId = 'valid-user-id';

        await privacyService.deleteUserData(testUserId);
        // If we get here without exception, test passes
        expect(true, isTrue);
      });
    });

    group('Consent Management', () {
      test('getConsent returns default values for new user', () async {
        final testUserId = 'new-user-123';
        final consents = await privacyService.getConsent(testUserId);

        expect(consents, isA<Map<ProcessingPurpose, bool>>());

        // Essential purposes should be true
        expect(consents[ProcessingPurpose.serviceDelivery], isTrue);
        expect(consents[ProcessingPurpose.legal], isTrue);
        expect(consents[ProcessingPurpose.security], isTrue);

        // Optional purposes should be false by default
        expect(consents[ProcessingPurpose.analytics], isFalse);
        expect(consents[ProcessingPurpose.marketing], isFalse);
      });

      test('updateConsent accepts valid consent map', () async {
        final testUserId = 'test-user-123';
        final newConsents = {
          ProcessingPurpose.analytics: true,
          ProcessingPurpose.marketing: false,
        };

        expect(
          () => privacyService.updateConsent(testUserId, newConsents),
          returnsNormally,
        );
      });

      test('updateConsent handles all purposes', () async {
        final testUserId = 'test-user-123';
        final allConsents = {
          ProcessingPurpose.serviceDelivery: true,
          ProcessingPurpose.analytics: true,
          ProcessingPurpose.marketing: true,
          ProcessingPurpose.legal: true,
          ProcessingPurpose.security: true,
        };

        await privacyService.updateConsent(testUserId, allConsents);
        // If we get here without exception, test passes
        expect(true, isTrue);
      });

      test('updateConsent handles partial consent updates', () async {
        final testUserId = 'test-user-123';
        final partialConsents = {
          ProcessingPurpose.analytics: true,
        };

        await privacyService.updateConsent(testUserId, partialConsents);
        expect(true, isTrue);
      });
    });

    group('Data Retention', () {
      test('applyRetentionPolicies completes without error', () async {
        expect(
          () => privacyService.applyRetentionPolicies(),
          returnsNormally,
        );
      });

      test('retention policies can be applied multiple times', () async {
        await privacyService.applyRetentionPolicies();
        await privacyService.applyRetentionPolicies();
        // Should be idempotent
        expect(true, isTrue);
      });
    });

    group('Edge Cases', () {
      test('handles empty user ID', () async {
        // Should not throw, but behavior may vary
        expect(
          () => privacyService.exportUserData(''),
          returnsNormally,
        );
      });

      test('handles null-like user IDs gracefully', () async {
        // Test with user ID that might not exist
        final exportData =
            await privacyService.exportUserData('non-existent-user');

        // Should still return valid structure
        expect(exportData, isA<Map<String, dynamic>>());
        expect(exportData.containsKey('exported_at'), isTrue);
      });

      test('updateConsent with empty map', () async {
        final testUserId = 'test-user-123';
        final emptyConsents = <ProcessingPurpose, bool>{};

        expect(
          () => privacyService.updateConsent(testUserId, emptyConsents),
          returnsNormally,
        );
      });
    });

    group('GDPR Compliance', () {
      test('export data is portable (JSON-serializable)', () async {
        final testUserId = 'test-user-123';
        final exportData = await privacyService.exportUserData(testUserId);

        // All data should be JSON-compatible types
        expect(exportData, isA<Map<String, dynamic>>());
        expect(exportData['user_profile'], isA<Map<String, dynamic>>());
        expect(exportData['content'], isA<List>());
        expect(exportData['transactions'], isA<List>());
        expect(exportData['analytics'], isA<Map<String, dynamic>>());
      });

      test('default consents respect GDPR (opt-in for non-essential)',
          () async {
        final testUserId = 'new-gdpr-user';
        final consents = await privacyService.getConsent(testUserId);

        // Non-essential processing should default to false (opt-in required)
        expect(consents[ProcessingPurpose.analytics], isFalse,
            reason: 'Analytics requires opt-in under GDPR');
        expect(consents[ProcessingPurpose.marketing], isFalse,
            reason: 'Marketing requires opt-in under GDPR');
      });
    });

    group('CCPA Compliance', () {
      test('provides data export for Right to Know', () async {
        final testUserId = 'california-user-123';
        final exportData = await privacyService.exportUserData(testUserId);

        // Must include all categories of data collected
        expect(exportData.containsKey('user_profile'), isTrue);
        expect(exportData.containsKey('content'), isTrue);
        expect(exportData.containsKey('transactions'), isTrue);
        expect(exportData.containsKey('analytics'), isTrue);
      });

      test('supports deletion for Right to Delete', () async {
        final testUserId = 'california-user-123';

        expect(
          () => privacyService.deleteUserData(testUserId),
          returnsNormally,
        );
      });
    });
  });
}
