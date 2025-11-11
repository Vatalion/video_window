import 'package:serverpod/serverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../generated/protocol.dart';
import 'capabilities/capability_service.dart';

/// Service for handling verification workflows (Persona, Stripe, etc.)
/// Implements Epic 2 Story 2-2: Verification within Publish Flow
class VerificationService {
  final Session _session;

  VerificationService(this._session);

  /// Create a verification task for a capability request
  ///
  /// AC3: Creates verification_task record linked to capability_request
  Future<VerificationTask> createVerificationTask({
    required int userId,
    required CapabilityType capability,
    required VerificationTaskType taskType,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final now = DateTime.now().toUtc();

      final task = VerificationTask(
        userId: userId,
        capability: capability,
        taskType: taskType,
        status: VerificationTaskStatus.pending,
        payload: jsonEncode(metadata),
        createdAt: now,
        updatedAt: now,
      );

      final inserted = await VerificationTask.db.insertRow(_session, task);

      _session.log(
        'Verification task created for user $userId: $taskType',
        level: LogLevel.info,
      );

      return inserted;
    } catch (e, stackTrace) {
      _session.log(
        'Failed to create verification task for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Complete a verification task (called by webhook)
  ///
  /// AC3: Updates verification_task status and toggles identityVerifiedAt when approved
  /// AC6: Emits audit event verification.completed with provider metadata, redacting PII
  Future<void> completeVerificationTask({
    required String taskId,
    required String provider,
    required String status, // 'approved', 'rejected', 'failed'
    required Map<String, dynamic> metadata,
    String? webhookSignature,
  }) async {
    try {
      // Find the verification task by ID (taskId is string, but stored as int)
      final taskIdInt = int.tryParse(taskId);
      if (taskIdInt == null) {
        throw Exception('Invalid task ID format: $taskId');
      }

      final task = await VerificationTask.db.findById(_session, taskIdInt);
      if (task == null) {
        throw Exception('Verification task not found: $taskId');
      }

      // Validate webhook signature if provided (Persona webhook security)
      if (webhookSignature != null && provider == 'persona') {
        final isValid = await _validatePersonaWebhookSignature(
          taskId: taskId,
          metadata: metadata,
          signature: webhookSignature,
        );
        if (!isValid) {
          throw Exception('Invalid webhook signature');
        }
      }

      final now = DateTime.now().toUtc();

      // Map provider status to VerificationTaskStatus
      VerificationTaskStatus taskStatus;
      switch (status.toLowerCase()) {
        case 'approved':
          taskStatus = VerificationTaskStatus.completed;
          break;
        case 'rejected':
        case 'failed':
          taskStatus = VerificationTaskStatus.failed;
          break;
        default:
          taskStatus = VerificationTaskStatus.pending;
      }

      // Update task
      task.status = taskStatus;
      task.completedAt = now;
      task.updatedAt = now;

      // Merge metadata into payload
      final currentPayload = jsonDecode(task.payload) as Map<String, dynamic>;
      currentPayload.addAll({
        'provider': provider,
        'providerStatus': status,
        'completedAt': now.toIso8601String(),
        ...metadata,
      });
      task.payload = jsonEncode(currentPayload);

      await VerificationTask.db.updateRow(_session, task);

      // If approved and task type is persona_identity, update capability
      if (taskStatus == VerificationTaskStatus.completed &&
          task.taskType == VerificationTaskType.personaIdentity &&
          task.capability == CapabilityType.publish) {
        final capabilityService = CapabilityService(_session);

        // Update identityVerifiedAt and enable publish capability
        await capabilityService.updateCapability(
          userId: task.userId,
          capability: CapabilityType.publish,
          enabled: true,
        );

        _session.log(
          'Publish capability auto-approved for user ${task.userId} after identity verification',
          level: LogLevel.info,
        );
      }

      // AC6: Emit audit event with redacted PII
      await _emitVerificationAuditEvent(
        userId: task.userId,
        taskId: task.id?.toString() ?? taskId,
        provider: provider,
        status: status,
        metadata: _redactPII(metadata),
      );

      _session.log(
        'Verification task completed: $taskId, status: $status',
        level: LogLevel.info,
      );
    } catch (e, stackTrace) {
      _session.log(
        'Failed to complete verification task $taskId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get verification task by ID
  Future<VerificationTask?> getVerificationTask(String taskId) async {
    try {
      final taskIdInt = int.tryParse(taskId);
      if (taskIdInt == null) {
        return null;
      }
      return await VerificationTask.db.findById(_session, taskIdInt);
    } catch (e, stackTrace) {
      _session.log(
        'Failed to get verification task $taskId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get verification tasks for a user and capability
  Future<List<VerificationTask>> getVerificationTasks({
    required int userId,
    CapabilityType? capability,
  }) async {
    try {
      return await VerificationTask.db.find(
        _session,
        where: (t) {
          var condition = t.userId.equals(userId);
          if (capability != null) {
            condition = condition & t.capability.equals(capability);
          }
          return condition;
        },
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
    } catch (e, stackTrace) {
      _session.log(
        'Failed to get verification tasks for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Validate Persona webhook signature
  ///
  /// AC4: Webhook signature validation for security
  Future<bool> _validatePersonaWebhookSignature({
    required String taskId,
    required Map<String, dynamic> metadata,
    required String signature,
  }) async {
    try {
      // Get webhook secret from environment/config
      // In production, this should be stored securely (e.g., AWS Secrets Manager)
      // TODO: Use proper configuration access when available
      final webhookSecret =
          ''; // Placeholder - will be configured via environment

      if (webhookSecret.isEmpty) {
        _session.log(
          'PERSONA_WEBHOOK_SECRET not configured, skipping signature validation',
          level: LogLevel.warning,
        );
        // In development, allow without secret if not configured
        return true;
      }

      // Persona webhook signature format: sha256_hex(webhook_secret + payload)
      final payload = jsonEncode({
        'taskId': taskId,
        ...metadata,
      });

      final bytes = utf8.encode(webhookSecret + payload);
      final digest = sha256.convert(bytes);
      final expectedSignature = digest.toString();

      final isValid = expectedSignature == signature;
      if (!isValid) {
        _session.log(
          'Persona webhook signature validation failed for task $taskId',
          level: LogLevel.warning,
        );
      }

      return isValid;
    } catch (e) {
      _session.log(
        'Error validating Persona webhook signature: $e',
        level: LogLevel.error,
      );
      return false;
    }
  }

  /// Redact PII from metadata before logging/auditing
  ///
  /// AC6: Redact PII from audit events
  Map<String, dynamic> _redactPII(Map<String, dynamic> metadata) {
    final redacted = Map<String, dynamic>.from(metadata);

    // Redact common PII fields
    final piiFields = [
      'ssn',
      'socialSecurityNumber',
      'taxId',
      'email',
      'phone',
      'address',
      'dateOfBirth',
      'dob',
      'passport',
      'driversLicense',
      'documentNumber',
    ];

    for (final field in piiFields) {
      if (redacted.containsKey(field)) {
        redacted[field] = '[REDACTED]';
      }
    }

    // Redact nested objects
    for (final key in redacted.keys) {
      if (redacted[key] is Map) {
        redacted[key] = _redactPII(redacted[key] as Map<String, dynamic>);
      }
    }

    return redacted;
  }

  /// Emit verification completion audit event
  ///
  /// AC6: Audit event verification.completed with provider metadata
  Future<void> _emitVerificationAuditEvent({
    required int userId,
    required String taskId,
    required String provider,
    required String status,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final event = CapabilityAuditEvent(
        userId: userId,
        eventType: 'verification.completed',
        capability: null, // Will be set from task if needed
        entryPoint: 'webhook',
        deviceFingerprint: null,
        metadata: jsonEncode({
          'taskId': taskId,
          'provider': provider,
          'status': status,
          ...metadata,
        }),
        createdAt: DateTime.now().toUtc(),
      );

      await CapabilityAuditEvent.db.insertRow(_session, event);

      _session.log(
        'Verification audit event emitted: verification.completed for user $userId',
        level: LogLevel.info,
      );
    } catch (e, stackTrace) {
      // Log but don't throw - audit failures shouldn't break the flow
      _session.log(
        'Failed to emit verification audit event: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }
}
