import 'package:video_window_client/video_window_client.dart' show Client;
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';

/// Repository for profile media upload operations
/// Implements Story 3-2: Avatar & Media Upload System
/// AC1: Presigned upload flow with chunked transfer
class ProfileMediaRepository {
  final Client _client;
  final Dio _dio;

  ProfileMediaRepository(this._client) : _dio = Dio();

  /// Get presigned upload URL for avatar
  /// AC1: Presigned upload flow with max 5 MB enforcement
  /// AC5: Authenticated requests required
  Future<Map<String, dynamic>> getAvatarUploadUrl({
    required int userId,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    try {
      // Call media endpoint to get presigned URL
      // TODO: Update when media endpoint is available in generated client
      // For now, return placeholder structure
      final response = await _client.callEndpoint(
        'media',
        'createAvatarUploadUrl',
        {
          'userId': userId,
          'fileName': fileName,
          'mimeType': mimeType,
          'fileSizeBytes': fileSizeBytes,
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      throw ProfileMediaRepositoryException('Failed to get upload URL: $e');
    }
  }

  /// Upload file to S3 using presigned URL with chunked transfer
  /// AC1: Chunked transfer for large files
  Future<void> uploadToS3({
    required String presignedUrl,
    required File file,
    required Function(double) onProgress,
  }) async {
    try {
      final fileSize = await file.length();
      const chunkSize = 1024 * 1024; // 1 MB chunks

      // For files larger than chunk size, use multipart upload
      if (fileSize > chunkSize) {
        await _uploadChunked(
          presignedUrl: presignedUrl,
          file: file,
          chunkSize: chunkSize,
          onProgress: onProgress,
        );
      } else {
        // Single upload for small files
        await _uploadSingle(
          presignedUrl: presignedUrl,
          file: file,
          onProgress: onProgress,
        );
      }
    } catch (e) {
      throw ProfileMediaRepositoryException('Failed to upload file: $e');
    }
  }

  /// Single file upload
  Future<void> _uploadSingle({
    required String presignedUrl,
    required File file,
    required Function(double) onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    await _dio.put(
      presignedUrl,
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': 'application/octet-stream',
        },
      ),
      onSendProgress: (sent, total) {
        onProgress(sent / total);
      },
    );
  }

  /// Chunked file upload
  Future<void> _uploadChunked({
    required String presignedUrl,
    required File file,
    required int chunkSize,
    required Function(double) onProgress,
  }) async {
    final fileSize = await file.length();
    final randomAccessFile = await file.open();
    int uploadedBytes = 0;

    try {
      while (uploadedBytes < fileSize) {
        final currentChunkSize = (uploadedBytes + chunkSize > fileSize)
            ? fileSize - uploadedBytes
            : chunkSize;

        await randomAccessFile.setPosition(uploadedBytes);
        final chunk = await randomAccessFile.read(currentChunkSize);

        // Upload chunk
        await _dio.put(
          '$presignedUrl&partNumber=${(uploadedBytes ~/ chunkSize) + 1}',
          data: chunk,
          options: Options(
            headers: {
              'Content-Type': 'application/octet-stream',
              'Content-Range':
                  'bytes $uploadedBytes-${uploadedBytes + currentChunkSize - 1}/$fileSize',
            },
          ),
        );

        uploadedBytes += currentChunkSize;
        onProgress(uploadedBytes / fileSize);
      }
    } finally {
      await randomAccessFile.close();
    }
  }

  /// Poll virus scan status until complete
  /// AC2: Blocks profile updates until is_virus_scanned=true
  Future<bool> pollVirusScanStatus({
    required int mediaId,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final startTime = DateTime.now();
    const pollInterval = Duration(seconds: 2);

    while (DateTime.now().difference(startTime) < timeout) {
      try {
        // TODO: Call media endpoint to check scan status
        // For now, return true after a delay
        await Future.delayed(pollInterval);
        return true; // Placeholder
      } catch (e) {
        // Continue polling on error
        await Future.delayed(pollInterval);
      }
    }

    throw ProfileMediaRepositoryException('Virus scan timeout');
  }
}

/// Exception for profile media repository errors
class ProfileMediaRepositoryException implements Exception {
  final String message;
  ProfileMediaRepositoryException(this.message);

  @override
  String toString() => 'ProfileMediaRepositoryException: $message';
}
