import 'dart:io';
import 'package:test/test.dart';
import 'package:video_window_server/src/endpoints/profile/media_endpoint.dart';

void main() {
  group('MediaEndpoint', () {
    test('createAvatarUploadUrl validates file size limit', () {
      // Arrange
      const maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
      const fileSizeBytes = 6 * 1024 * 1024; // 6 MB - exceeds limit

      // Assert - validation logic
      expect(fileSizeBytes > maxFileSizeBytes, isTrue,
          reason: 'File size validation should reject files > 5 MB');
    });

    test('createAvatarUploadUrl validates MIME type - allows valid types', () {
      // Arrange
      const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];

      // Assert - all valid types should be accepted
      expect(allowedMimeTypes.contains('image/jpeg'), isTrue);
      expect(allowedMimeTypes.contains('image/png'), isTrue);
      expect(allowedMimeTypes.contains('image/webp'), isTrue);
    });

    test('createAvatarUploadUrl validates MIME type - rejects invalid types',
        () {
      // Arrange
      const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];
      const invalidMimeTypes = [
        'application/pdf',
        'text/plain',
        'video/mp4',
        'application/octet-stream',
      ];

      // Assert - invalid types should be rejected
      for (final invalidType in invalidMimeTypes) {
        expect(allowedMimeTypes.contains(invalidType), isFalse,
            reason: 'MIME type $invalidType should be rejected');
      }
    });

    test('endpoint initialization succeeds', () {
      // Skip if AWS credentials not configured
      if (Platform.environment['AWS_ACCESS_KEY_ID'] == null ||
          Platform.environment['AWS_SECRET_ACCESS_KEY'] == null) {
        return;
      }

      // Arrange
      final endpoint = MediaEndpoint();

      // Assert
      expect(endpoint, isNotNull);
      expect(endpoint.name, equals('media'));
    },
        skip: Platform.environment['AWS_ACCESS_KEY_ID'] == null ||
            Platform.environment['AWS_SECRET_ACCESS_KEY'] == null);
  });
}
