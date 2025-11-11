import 'package:serverpod/serverpod.dart';
import 'dart:convert';
import '../generated/capabilities/trusted_device.dart';
import '../generated/capabilities/capability_audit_event.dart';
import '../generated/capabilities/user_capabilities.dart';
import '../generated/capabilities/capability_type.dart';
import 'capabilities/capability_service.dart';

/// Service for managing device trust and risk scoring
/// Implements Epic 2 Story 2-4: Device Trust & Risk Monitoring
class DeviceTrustService {
  final Session _session;
  static const double baseTrustScore = 0.8;
  static const double minDeviceTrustThreshold =
      0.7; // Configurable via capability.minDeviceTrust

  DeviceTrustService(this._session);

  /// Register or update device telemetry
  /// AC1: Device registration occurs on app launch, capturing device ID, platform, attestation result, and telemetry
  Future<TrustedDevice> registerDevice({
    required int userId,
    required String deviceId,
    required String deviceType,
    required String platform,
    required Map<String, dynamic> telemetry,
  }) async {
    try {
      final now = DateTime.now().toUtc();

      // Calculate trust score from telemetry
      final trustScore = _calculateTrustScore(telemetry);

      // Check if device already exists
      final existing = await TrustedDevice.db.findFirstRow(
        _session,
        where: (t) => t.userId.equals(userId) & t.deviceId.equals(deviceId),
      );

      TrustedDevice device;
      if (existing != null && existing.revokedAt == null) {
        // Update existing device
        existing.trustScore = trustScore;
        existing.telemetry = jsonEncode(_redactTelemetry(telemetry));
        existing.lastSeenAt = now;
        existing.deviceType = deviceType;
        existing.platform = platform;
        await TrustedDevice.db.updateRow(_session, existing);
        device = existing;
      } else {
        // Create new device
        device = TrustedDevice(
          userId: userId,
          deviceId: deviceId,
          deviceType: deviceType,
          platform: platform,
          trustScore: trustScore,
          telemetry: jsonEncode(_redactTelemetry(telemetry)),
          lastSeenAt: now,
          createdAt: now,
          revokedAt: null,
        );
        await TrustedDevice.db.insertRow(_session, device);
      }

      // Emit audit event
      await _emitAuditEvent(
        userId: userId,
        eventType: 'device.trust_scored',
        deviceId: deviceId,
        trustScore: trustScore,
        metadata: {
          'deviceType': deviceType,
          'platform': platform,
        },
      );

      // Check for low-trust spike (AC4: Alerts trigger when multiple low-trust devices register)
      await _checkLowTrustSpike(userId);

      // Update capability blockers if needed (AC2)
      await _updateCapabilityBlockers(userId);

      _session.log(
        'Device registered for user $userId: $deviceId (trust score: $trustScore)',
        level: LogLevel.info,
      );

      return device;
    } catch (e, stackTrace) {
      _session.log(
        'Failed to register device for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Calculate trust score from telemetry
  /// Base 0.8 minus risk penalties
  double _calculateTrustScore(Map<String, dynamic> telemetry) {
    double score = baseTrustScore;

    // Check for jailbreak/rooted device
    final isJailbroken = telemetry['isJailbroken'] == true ||
        telemetry['isRooted'] == true ||
        telemetry['isEmulator'] == true;
    if (isJailbroken) {
      score -= 0.5; // Significant penalty
    }

    // Check for outdated OS
    final osVersion = telemetry['osVersion'] as String?;
    if (osVersion != null) {
      // Simple check: if OS version is very old, penalize
      // In production, this would check against minimum supported versions
      final versionParts = osVersion.split('.');
      if (versionParts.isNotEmpty) {
        final majorVersion = int.tryParse(versionParts[0]) ?? 0;
        // Example: iOS < 14 or Android < 10
        if ((telemetry['platform'] == 'ios' && majorVersion < 14) ||
            (telemetry['platform'] == 'android' && majorVersion < 10)) {
          score -= 0.2;
        }
      }
    }

    // Check attestation result
    final attestationResult = telemetry['attestationResult'] as String?;
    if (attestationResult == 'failed' || attestationResult == 'invalid') {
      score -= 0.3;
    } else if (attestationResult == 'passed') {
      score += 0.1; // Bonus for passing attestation
    }

    // Ensure score is between 0.0 and 1.0
    return score.clamp(0.0, 1.0);
  }

  /// Redact sensitive telemetry before logging/storage
  Map<String, dynamic> _redactTelemetry(Map<String, dynamic> telemetry) {
    final redacted = Map<String, dynamic>.from(telemetry);
    // Remove or hash sensitive fields
    redacted.remove('deviceFingerprint');
    redacted.remove('ipAddress');
    return redacted;
  }

  /// Get all active devices for a user
  Future<List<TrustedDevice>> getUserDevices(int userId) async {
    try {
      final allDevices = await TrustedDevice.db.find(
        _session,
        where: (t) => t.userId.equals(userId),
      );
      // Filter out revoked devices and sort by last seen
      final activeDevices = allDevices
          .where((d) => d.revokedAt == null)
          .toList()
        ..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));
      return activeDevices;
    } catch (e, stackTrace) {
      _session.log(
        'Failed to get devices for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Revoke device trust
  /// AC3: Revocation lowers capability state appropriately
  Future<void> revokeDevice({
    required int userId,
    required int deviceId,
    String? reason,
  }) async {
    try {
      final device = await TrustedDevice.db.findById(_session, deviceId);
      if (device == null || device.userId != userId) {
        throw ArgumentError('Device not found or access denied');
      }

      if (device.revokedAt != null) {
        // Already revoked
        return;
      }

      device.revokedAt = DateTime.now().toUtc();
      await TrustedDevice.db.updateRow(_session, device);

      // Emit audit event
      await _emitAuditEvent(
        userId: userId,
        eventType: 'device.trust_revoked',
        deviceId: device.deviceId,
        metadata: {
          'reason': reason ?? 'user_requested',
        },
      );

      // Emit analytics event
      _session.log(
        'Device trust revoked for user $userId: ${device.deviceId} (reason: ${reason ?? "user_requested"})',
        level: LogLevel.info,
      );

      // Update capability blockers (AC5: Capability downgrade when all devices revoked)
      await _updateCapabilityBlockers(userId);
    } catch (e, stackTrace) {
      _session.log(
        'Failed to revoke device for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check if user has at least one trusted device above threshold
  /// AC2: Capabilities requiring trusted devices remain blocked until at least one device exceeds threshold
  Future<bool> hasTrustedDevice(int userId) async {
    try {
      final allDevices = await TrustedDevice.db.find(
        _session,
        where: (t) => t.userId.equals(userId),
      );
      // Filter for active devices with trust score above threshold
      final trustedDevices = allDevices.where(
          (d) => d.revokedAt == null && d.trustScore > minDeviceTrustThreshold);
      return trustedDevices.isNotEmpty;
    } catch (e, stackTrace) {
      _session.log(
        'Failed to check trusted device for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Update capability blockers based on device trust
  Future<void> _updateCapabilityBlockers(int userId) async {
    try {
      final hasTrusted = await hasTrustedDevice(userId);
      final capabilityService = CapabilityService(_session);
      final capabilities = await capabilityService.getUserCapabilities(userId);

      // Parse blockers
      final blockers =
          jsonDecode(capabilities.blockers) as Map<String, dynamic>? ?? {};

      if (!hasTrusted) {
        // Block fulfill_orders if no trusted device
        blockers['device_trust'] =
            'No trusted device found. Please register a device and ensure it meets security requirements.';
      } else {
        // Remove device trust blocker if trusted device exists
        blockers.remove('device_trust');
      }

      // Update capabilities
      capabilities.blockers = jsonEncode(blockers);
      capabilities.updatedAt = DateTime.now().toUtc();
      await UserCapabilities.db.updateRow(_session, capabilities);

      // If capability was downgraded, emit event (AC5)
      if (!hasTrusted && capabilities.canFulfillOrders) {
        await capabilityService.updateCapability(
          userId: userId,
          capability: CapabilityType.fulfillOrders,
          enabled: false,
        );

        // Emit capability downgrade event
        await _emitAuditEvent(
          userId: userId,
          eventType: 'capability.downgraded',
          metadata: {
            'capability': 'fulfill_orders',
            'reason': 'no_trusted_device',
          },
        );

        _session.log(
          'Capability downgraded for user $userId: fulfill_orders (no trusted device)',
          level: LogLevel.warning,
        );
      }
    } catch (e, stackTrace) {
      _session.log(
        'Failed to update capability blockers for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check for low-trust spike (AC4)
  /// Alerts trigger when multiple low-trust devices register for the same user within 24 hours
  Future<void> _checkLowTrustSpike(int userId) async {
    try {
      final oneDayAgo =
          DateTime.now().toUtc().subtract(const Duration(days: 1));
      final allDevices = await TrustedDevice.db.find(
        _session,
        where: (t) => t.userId.equals(userId),
      );
      // Filter for low-trust devices created in last 24 hours
      final lowTrustDevices = allDevices.where((d) =>
          d.revokedAt == null &&
          d.createdAt.isAfter(oneDayAgo) &&
          d.trustScore < minDeviceTrustThreshold);

      if (lowTrustDevices.length > 3) {
        // Alert condition met
        _session.log(
          'LOW TRUST SPIKE ALERT: User $userId has ${lowTrustDevices.length} low-trust devices registered in last 24 hours',
          level: LogLevel.warning,
        );

        // In production, this would trigger PagerDuty alert or similar
        // For now, we log it as a warning
      }
    } catch (e, stackTrace) {
      _session.log(
        'Failed to check low trust spike for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Emit audit event
  Future<void> _emitAuditEvent({
    required int userId,
    required String eventType,
    String? deviceId,
    double? trustScore,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final event = CapabilityAuditEvent(
        userId: userId,
        eventType: eventType,
        capability: null, // Device events don't map to specific capability
        entryPoint: null,
        deviceFingerprint: deviceId,
        metadata: jsonEncode({
          ...metadata,
          if (trustScore != null) 'trustScore': trustScore,
        }),
        createdAt: DateTime.now().toUtc(),
      );

      await CapabilityAuditEvent.db.insertRow(_session, event);
    } catch (e, stackTrace) {
      // Log but don't throw - audit failures shouldn't break the flow
      _session.log(
        'Failed to emit audit event: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }
}
