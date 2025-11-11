import 'dart:io';
import 'package:test/test.dart';
import 'package:video_window_server/src/services/media/media_processing_service.dart';

void main() {
  group('MediaProcessingService', () {
    setUpAll(() {
      // Note: Platform.environment is unmodifiable in Dart
      // In CI/CD, AWS credentials should be set via environment variables
      // For local testing, ensure AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are set
      // These tests will fail if credentials are not configured
    });

    test('generatePresignedUploadUrl returns valid URL structure', () async {
      // Skip if AWS credentials not configured
      if (Platform.environment['AWS_ACCESS_KEY_ID'] == null ||
          Platform.environment['AWS_SECRET_ACCESS_KEY'] == null) {
        return; // Skip test if credentials not available
      }

      // Arrange
      const userId = 1;
      const fileName = 'avatar.jpg';
      const mimeType = 'image/jpeg';
      const expirationMinutes = 5;

      // Act
      final url = await MediaProcessingService().generatePresignedUploadUrl(
        userId: userId,
        fileName: fileName,
        mimeType: mimeType,
        expirationMinutes: expirationMinutes,
      );

      // Assert
      expect(url, isNotEmpty);
      expect(url, startsWith('https://'));
      expect(url, contains('video-window-profile-media'));
      expect(url, contains('profile-media/$userId/temp/'));
    },
        skip: Platform.environment['AWS_ACCESS_KEY_ID'] == null ||
            Platform.environment['AWS_SECRET_ACCESS_KEY'] == null);

    test(
        'generatePresignedUploadUrl includes all required AWS SigV4 parameters',
        () async {
      // Skip if AWS credentials not configured
      if (Platform.environment['AWS_ACCESS_KEY_ID'] == null ||
          Platform.environment['AWS_SECRET_ACCESS_KEY'] == null) {
        return;
      }
      // Arrange
      const userId = 1;
      const fileName = 'avatar.jpg';
      const mimeType = 'image/jpeg';
      const expirationMinutes = 5;

      // Act
      final url = await MediaProcessingService().generatePresignedUploadUrl(
        userId: userId,
        fileName: fileName,
        mimeType: mimeType,
        expirationMinutes: expirationMinutes,
      );

      // Assert - verify all required AWS SigV4 query parameters are present
      expect(url, contains('X-Amz-Algorithm=AWS4-HMAC-SHA256'));
      expect(url, contains('X-Amz-Credential='));
      expect(url, contains('X-Amz-Date='));
      expect(url, contains('X-Amz-Expires=${expirationMinutes * 60}'));
      expect(url, contains('X-Amz-SignedHeaders=host'));
      expect(url, contains('X-Amz-Signature='),
          reason: 'Signature must be present for valid presigned URL');
    },
        skip: Platform.environment['AWS_ACCESS_KEY_ID'] == null ||
            Platform.environment['AWS_SECRET_ACCESS_KEY'] == null);

    test('generatePresignedUploadUrl signature is valid hex string', () async {
      // Skip if AWS credentials not configured
      if (Platform.environment['AWS_ACCESS_KEY_ID'] == null ||
          Platform.environment['AWS_SECRET_ACCESS_KEY'] == null) {
        return;
      }
      // Arrange
      const userId = 1;
      const fileName = 'avatar.jpg';
      const mimeType = 'image/jpeg';
      const expirationMinutes = 5;

      // Act
      final url = await MediaProcessingService().generatePresignedUploadUrl(
        userId: userId,
        fileName: fileName,
        mimeType: mimeType,
        expirationMinutes: expirationMinutes,
      );

      // Assert - extract signature and verify it's a valid hex string
      final uri = Uri.parse(url);
      final signature = uri.queryParameters['X-Amz-Signature'];
      expect(signature, isNotNull, reason: 'Signature must be present');
      expect(signature, matches(r'^[0-9a-f]{64}$'),
          reason: 'Signature must be 64-character hex string');
    },
        skip: Platform.environment['AWS_ACCESS_KEY_ID'] == null ||
            Platform.environment['AWS_SECRET_ACCESS_KEY'] == null);

    test('generatePresignedUploadUrl includes correct expiration time',
        () async {
      // Skip if AWS credentials not configured
      if (Platform.environment['AWS_ACCESS_KEY_ID'] == null ||
          Platform.environment['AWS_SECRET_ACCESS_KEY'] == null) {
        return;
      }
      // Arrange
      const userId = 1;
      const fileName = 'avatar.jpg';
      const mimeType = 'image/jpeg';
      const expirationMinutes = 5;

      // Act
      final url = await MediaProcessingService().generatePresignedUploadUrl(
        userId: userId,
        fileName: fileName,
        mimeType: mimeType,
        expirationMinutes: expirationMinutes,
      );

      // Assert
      final uri = Uri.parse(url);
      final expires = uri.queryParameters['X-Amz-Expires'];
      expect(expires, equals('${expirationMinutes * 60}'));
    },
        skip: Platform.environment['AWS_ACCESS_KEY_ID'] == null ||
            Platform.environment['AWS_SECRET_ACCESS_KEY'] == null);

    test(
        'generatePresignedUploadUrl generates different URLs for different files',
        () async {
      // Skip if AWS credentials not configured
      if (Platform.environment['AWS_ACCESS_KEY_ID'] == null ||
          Platform.environment['AWS_SECRET_ACCESS_KEY'] == null) {
        return;
      }
      // Arrange
      const userId = 1;
      const expirationMinutes = 5;

      // Act
      final url1 = await MediaProcessingService().generatePresignedUploadUrl(
        userId: userId,
        fileName: 'avatar1.jpg',
        mimeType: 'image/jpeg',
        expirationMinutes: expirationMinutes,
      );

      // Wait a moment to ensure different timestamps
      await Future.delayed(const Duration(milliseconds: 10));

      final url2 = await MediaProcessingService().generatePresignedUploadUrl(
        userId: userId,
        fileName: 'avatar2.jpg',
        mimeType: 'image/jpeg',
        expirationMinutes: expirationMinutes,
      );

      // Assert - URLs should be different (different S3 keys and signatures)
      expect(url1, isNot(equals(url2)));
    },
        skip: Platform.environment['AWS_ACCESS_KEY_ID'] == null ||
            Platform.environment['AWS_SECRET_ACCESS_KEY'] == null);

    test('purgeTemporaryFile handles missing file gracefully', () async {
      // Skip if AWS credentials not configured
      if (Platform.environment['AWS_ACCESS_KEY_ID'] == null ||
          Platform.environment['AWS_SECRET_ACCESS_KEY'] == null) {
        return;
      }
      // Arrange
      const s3Key = 'profile-media/1/temp/nonexistent.jpg';

      // Act & Assert - should not throw
      await expectLater(
        MediaProcessingService().purgeTemporaryFile(s3Key: s3Key),
        completes,
      );
    },
        skip: Platform.environment['AWS_ACCESS_KEY_ID'] == null ||
            Platform.environment['AWS_SECRET_ACCESS_KEY'] == null);
  });
}
