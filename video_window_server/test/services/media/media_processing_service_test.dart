import 'package:test/test.dart';
import 'package:video_window_server/src/services/media/media_processing_service.dart';

void main() {
  group('MediaProcessingService', () {
    test('generatePresignedUploadUrl returns valid URL structure', () async {
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
    });

    test('generatePresignedUploadUrl includes expiration parameters', () async {
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
      expect(url, contains('X-Amz-Expires'));
      expect(url, contains('X-Amz-Algorithm'));
      expect(url, contains('AWS4-HMAC-SHA256'));
    });

    test('purgeTemporaryFile handles missing file gracefully', () async {
      // Arrange
      const s3Key = 'profile-media/1/temp/nonexistent.jpg';

      // Act & Assert - should not throw
      await expectLater(
        MediaProcessingService().purgeTemporaryFile(s3Key: s3Key),
        completes,
      );
    });
  });
}
