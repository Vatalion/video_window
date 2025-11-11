import 'package:serverpod/serverpod.dart';
import '../../generated/profile/dsar_request.dart';
import '../../generated/profile/user_profile.dart';
import '../../generated/profile/privacy_settings.dart';
import '../../generated/profile/notification_preferences.dart';
import '../../generated/auth/user.dart';
import 'dart:convert';
import 'dart:io';

/// Profile DSAR Service for orchestrating export packaging, storage, and retention policy
/// Story 3-5: Account Settings Management
/// AC2: DSAR export generates downloadable package within 24 hours
class ProfileDSARService {
  final Session _session;

  ProfileDSARService(this._session);

  /// Initiate DSAR export
  /// Creates export request and queues background job for packaging
  Future<Map<String, dynamic>> initiateExport(int userId) async {
    try {
      final now = DateTime.now().toUtc();
      final exportId = _generateExportId();

      // Create DSAR request record
      final dsarRequest = DsarRequest(
        userId: userId,
        requestType: 'export',
        status: 'processing',
        requestedAt: now,
        requestData: json.encode({
          'exportId': exportId,
          'requestedBy': userId.toString(),
          'requestedAt': now.toIso8601String(),
        }),
        auditLog: json.encode({
          'exportRequestedAt': now.toIso8601String(),
          'exportRequestedBy': userId.toString(),
        }),
        createdAt: now,
        updatedAt: now,
      );

      await DsarRequest.db.insertRow(_session, dsarRequest);

      // Queue background job for export packaging
      // TODO: Implement background job queue
      // await BackgroundJobService.enqueue(
      //   jobType: 'dsar_export',
      //   userId: userId,
      //   exportId: exportId,
      // );

      // For now, process synchronously (should be async in production)
      _processExportAsync(userId, exportId);

      return {
        'exportId': exportId,
        'status': 'processing',
        'createdAt': now.toIso8601String(),
        'estimatedCompletionAt':
            now.add(const Duration(hours: 24)).toIso8601String(),
      };
    } catch (e, stackTrace) {
      _session.log(
        'Failed to initiate DSAR export for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get export status
  /// AC2: Surfaces status/progress in UI with polling
  Future<Map<String, dynamic>> getExportStatus(
    int userId,
    String exportId,
  ) async {
    try {
      final request = await DsarRequest.db.findFirstRow(
        _session,
        where: (t) =>
            t.userId.equals(userId) &
            t.requestData.like('%$exportId%') &
            t.requestType.equals('export'),
      );

      if (request == null) {
        throw Exception('Export request not found');
      }

      // Parse requestData for downloadUrl and expiresAt
      String? downloadUrl;
      DateTime? expiresAt;
      if (request.requestData != null) {
        try {
          final requestDataMap =
              json.decode(request.requestData!) as Map<String, dynamic>;
          downloadUrl = requestDataMap['downloadUrl'] as String?;
          final expiresAtStr = requestDataMap['expiresAt'] as String?;
          if (expiresAtStr != null) {
            expiresAt = DateTime.parse(expiresAtStr);
          }
        } catch (e) {
          // If parsing fails, continue without downloadUrl/expiresAt
        }
      }

      return {
        'exportId': exportId,
        'status': request.status,
        'downloadUrl': downloadUrl,
        'expiresAt': expiresAt?.toIso8601String(),
        'createdAt': request.createdAt.toIso8601String(),
        'completedAt': request.completedAt?.toIso8601String(),
      };
    } catch (e, stackTrace) {
      _session.log(
        'Failed to get export status for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Process export asynchronously
  /// AC2: Generates downloadable package within 24 hours
  Future<void> _processExportAsync(int userId, String exportId) async {
    try {
      // Collect all user data
      final user = await User.db.findById(_session, userId);
      final profile = await UserProfile.db.findFirstRow(
        _session,
        where: (t) => t.userId.equals(userId),
      );
      final privacy = await PrivacySettings.db.findFirstRow(
        _session,
        where: (t) => t.userId.equals(userId),
      );
      final notifications = await NotificationPreferences.db.findFirstRow(
        _session,
        where: (t) => t.userId.equals(userId),
      );

      // Compile export data
      final exportData = <String, dynamic>{
        'userId': userId,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'account': user != null
            ? {
                'email': user.email,
                'phone': user.phone,
                'role': user.role,
                'createdAt': user.createdAt.toIso8601String(),
                'lastLoginAt': user.lastLoginAt?.toIso8601String(),
              }
            : null,
        'profile': profile != null
            ? {
                'username': profile.username,
                'fullName': profile.fullName,
                'bio': profile.bio,
                'avatarUrl': profile.avatarUrl,
                'visibility': profile.visibility,
                'isVerified': profile.isVerified,
                'createdAt': profile.createdAt.toIso8601String(),
                'updatedAt': profile.updatedAt.toIso8601String(),
              }
            : null,
        'privacy': privacy != null
            ? {
                'profileVisibility': privacy.profileVisibility,
                'showEmailToPublic': privacy.showEmailToPublic,
                'showPhoneToFriends': privacy.showPhoneToFriends,
                'allowTagging': privacy.allowTagging,
                'allowSearchByPhone': privacy.allowSearchByPhone,
                'allowDataAnalytics': privacy.allowDataAnalytics,
                'allowMarketingEmails': privacy.allowMarketingEmails,
                'allowPushNotifications': privacy.allowPushNotifications,
                'shareProfileWithPartners': privacy.shareProfileWithPartners,
              }
            : null,
        'notifications': notifications != null
            ? {
                'emailNotifications': notifications.emailNotifications,
                'pushNotifications': notifications.pushNotifications,
                'inAppNotifications': notifications.inAppNotifications,
                'settings': notifications.settings != null
                    ? json.decode(notifications.settings!)
                    : null,
                'quietHours': notifications.quietHours != null
                    ? json.decode(notifications.quietHours!)
                    : null,
              }
            : null,
      };

      // Create export file (JSON format - machine-readable per GDPR/CCPA)
      await _createExportFile(exportData, exportId);

      // TODO: Upload to S3 and generate signed URL
      // For now, store file path in downloadUrl (should be S3 signed URL in production)
      // In production: await s3Service.uploadFile(exportFile.path, 'exports/$exportId.json');
      // final downloadUrl = await s3Service.generatePresignedDownloadUrl('exports/$exportId.json', Duration(days: 7));
      final downloadUrl =
          'https://secure-cdn.example.com/exports/$exportId.json';
      final expiresAt = DateTime.now().add(const Duration(days: 7));

      // Update DSAR request
      final request = await DsarRequest.db.findFirstRow(
        _session,
        where: (t) =>
            t.userId.equals(userId) &
            t.requestData.like('%$exportId%') &
            t.requestType.equals('export'),
      );

      if (request != null) {
        // Parse existing requestData or create new map
        Map<String, dynamic> requestDataMap = {};
        if (request.requestData != null) {
          try {
            requestDataMap = json.decode(request.requestData!);
          } catch (e) {
            // If parsing fails, start with empty map
          }
        }

        // Add downloadUrl and expiresAt to requestData
        requestDataMap['downloadUrl'] = downloadUrl;
        requestDataMap['expiresAt'] = expiresAt.toIso8601String();

        final updated = request.copyWith(
          status: 'completed',
          requestData: json.encode(requestDataMap),
          completedAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        await DsarRequest.db.updateRow(_session, updated);
      }

      // AC5: Log audit event
      await _logAuditEvent(userId, 'dsar_export', exportId);
    } catch (e, stackTrace) {
      _session.log(
        'Failed to process export for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );

      // Update request status to failed
      final request = await DsarRequest.db.findFirstRow(
        _session,
        where: (t) =>
            t.userId.equals(userId) &
            t.requestData.like('%$exportId%') &
            t.requestType.equals('export'),
      );

      if (request != null) {
        final updated = request.copyWith(
          status: 'failed',
          updatedAt: DateTime.now().toUtc(),
        );
        await DsarRequest.db.updateRow(_session, updated);
      }
    }
  }

  /// Create export file
  /// AC2: DSAR export generates downloadable package
  /// Creates JSON file (machine-readable format per GDPR/CCPA requirements)
  /// TODO: Add ZIP compression when archive package is available
  Future<File> _createExportFile(
    Map<String, dynamic> data,
    String exportId,
  ) async {
    try {
      // Create temporary directory for exports
      final tempDir = Directory.systemTemp.createTempSync('dsar_exports_');
      final exportFile = File('${tempDir.path}/$exportId.json');

      // Write JSON data to file
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      await exportFile.writeAsString(jsonString);

      _session.log(
        'Export file created: ${exportFile.path} (${await exportFile.length()} bytes)',
        level: LogLevel.info,
      );

      return exportFile;
    } catch (e, stackTrace) {
      _session.log(
        'Failed to create export file: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Generate unique export ID
  String _generateExportId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'export_${timestamp}_$random';
  }

  /// Log audit event
  /// AC5: Audit events recorded for DSAR export/deletion and account closure
  Future<void> _logAuditEvent(
    int userId,
    String eventType,
    String exportId,
  ) async {
    try {
      // TODO: Publish to audit stream
      // await EventBridge.publish(
      //   stream: 'audit.profile',
      //   event: {
      //     'type': eventType,
      //     'userId': userId,
      //     'exportId': exportId,
      //     'timestamp': DateTime.now().toUtc().toIso8601String(),
      //   },
      // );

      _session.log(
        'DSAR audit event: $eventType for user $userId',
        level: LogLevel.info,
      );
    } catch (e) {
      _session.log(
        'Failed to log audit event: $e',
        level: LogLevel.warning,
      );
    }
  }
}
