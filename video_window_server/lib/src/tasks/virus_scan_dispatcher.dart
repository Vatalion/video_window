import 'package:serverpod/serverpod.dart';
import 'dart:io';
import 'dart:convert';
import 'package:aws_lambda_api/lambda-2015-03-31.dart';
import 'package:shared_aws_api/shared.dart';
import '../generated/profile/media_file.dart';

/// Virus scan dispatcher for invoking AWS Lambda and handling callbacks
/// Implements Story 3-2: Avatar & Media Upload System
/// AC2: Virus scanning pipeline dispatches uploads to AWS Lambda
class VirusScanDispatcher {
  // SNS topic ARN for Lambda callbacks (from environment)
  static const String _snsTopicArn =
      'arn:aws:sns:us-east-1:4815162342:video-window-virus-scan-callback';
  // Lambda function name
  static const String _lambdaFunctionName = 'video-window-virus-scan';
  static const String _lambdaRegion = 'us-east-1';

  late final Lambda _lambda;

  VirusScanDispatcher() {
    // Initialize Lambda client with credentials from environment
    final accessKey = Platform.environment['AWS_ACCESS_KEY_ID'];
    final secretKey = Platform.environment['AWS_SECRET_ACCESS_KEY'];

    if (accessKey == null || secretKey == null) {
      throw Exception(
          'AWS credentials not configured: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY required');
    }

    _lambda = Lambda(
      region: _lambdaRegion,
      credentials: AwsClientCredentials(
        accessKey: accessKey,
        secretKey: secretKey,
      ),
    );
  }

  /// Dispatch media file to virus scanning Lambda
  /// AC2: Dispatches uploads to AWS Lambda
  Future<void> dispatchVirusScan({
    required Session session,
    required int mediaFileId,
    required String s3Key,
    required String bucketName,
  }) async {
    try {
      final mediaFile = await MediaFile.db.findById(session, mediaFileId);
      if (mediaFile == null) {
        throw Exception('Media file not found: $mediaFileId');
      }

      // Update media file status to processing
      final updatedMediaFile = mediaFile.copyWith(
        status: 'processing',
        updatedAt: DateTime.now(),
      );
      await MediaFile.db.updateRow(session, updatedMediaFile);

      // Invoke AWS Lambda function with S3 key and bucket
      // Lambda will scan file using ClamAV and publish result to SNS topic
      final payload = {
        'mediaId': mediaFileId,
        's3Key': s3Key,
        'bucketName': bucketName,
        'callbackTopicArn': _snsTopicArn,
      };

      final invokeResponse = await _lambda.invoke(
        functionName: _lambdaFunctionName,
        invocationType: InvocationType.event,
        payload: utf8.encode(jsonEncode(payload)),
      );

      if (invokeResponse.statusCode != 202 &&
          invokeResponse.statusCode != 200) {
        throw Exception(
            'Lambda invocation failed with status: ${invokeResponse.statusCode}');
      }

      session.log(
        'Dispatched virus scan for media file $mediaFileId (S3: $s3Key)',
        level: LogLevel.info,
      );
    } catch (e, stackTrace) {
      session.log(
        'Failed to dispatch virus scan for media file $mediaFileId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );

      // Update media file status to failed
      try {
        final mediaFile = await MediaFile.db.findById(session, mediaFileId);
        if (mediaFile != null) {
          final failedMediaFile = mediaFile.copyWith(
            status: 'failed',
            updatedAt: DateTime.now(),
          );
          await MediaFile.db.updateRow(session, failedMediaFile);
        }
      } catch (_) {
        // Ignore errors updating failed status
      }

      rethrow;
    }
  }

  /// Handle SNS callback from Lambda
  /// AC2: Receives scan results via SNS callback
  Future<void> handleScanCallback({
    required Session session,
    required Map<String, dynamic> snsMessage,
  }) async {
    try {
      // Parse SNS message
      final messageBody = snsMessage['Message'] as String?;
      if (messageBody == null) {
        throw Exception('Invalid SNS message: missing Message');
      }

      // Parse JSON message body
      final messageData = jsonDecode(messageBody) as Map<String, dynamic>;
      final mediaId = messageData['mediaId'] as int?;
      final scanResult =
          messageData['scanResult'] as String?; // 'clean' or 'infected'

      if (mediaId == null || scanResult == null) {
        throw Exception(
            'Invalid callback data: mediaId and scanResult required');
      }

      // Forward to media endpoint's handleVirusScanCallback method
      // This will be called by the SNS webhook handler
      // For now, we just log the result
      session.log(
        'Virus scan callback received: mediaId=$mediaId, result=$scanResult',
        level: LogLevel.info,
      );
    } catch (e, stackTrace) {
      session.log(
        'Failed to handle virus scan callback: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
