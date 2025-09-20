import 'dart:async';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../domain/models/checkout_session_model.dart';
import '../../domain/models/checkout_security_model.dart';
import '../datasources/checkout_local_data_source.dart';
import 'checkout_audit_service.dart';

class CheckoutAutoSaveService {
  final CheckoutLocalDataSource localDataSource;
  final CheckoutAuditService auditService;

  final Map<String, Timer> _autoSaveTimers = {};
  final Map<String, Map<String, dynamic>> _pendingSaves = {};
  final Map<String, DateTime> _lastAutoSave = {};
  final Map<String, int> _autoSaveVersions = {};
  final Duration _autoSaveInterval = const Duration(seconds: 30);
  final Duration _debounceDelay = const Duration(milliseconds: 500);

  CheckoutAutoSaveService({
    required this.localDataSource,
    required this.auditService,
  });

  // Auto-save management
  void startAutoSave(String sessionId, CheckoutSessionModel session) {
    _lastAutoSave[sessionId] = DateTime.now();
    _autoSaveVersions[sessionId] = 1;

    // Start periodic auto-save
    _startAutoSaveTimer(sessionId);

    // Log auto-save start
    auditService.logAutoSaveEvent(
      sessionId: sessionId,
      userId: session.userId,
      eventType: 'auto_save_started',
      details: {
        'interval': _autoSaveInterval.inSeconds,
        'version': _autoSaveVersions[sessionId],
      },
    );
  }

  void stopAutoSave(String sessionId) {
    _stopAutoSaveTimer(sessionId);
    _pendingSaves.remove(sessionId);
    _lastAutoSave.remove(sessionId);
    _autoSaveVersions.remove(sessionId);

    // Log auto-save stop
    auditService.logAutoSaveEvent(
      sessionId: sessionId,
      userId: 'unknown', // Would get from session if available
      eventType: 'auto_save_stopped',
      details: {},
    );
  }

  // Queue data for auto-save with debouncing
  void queueAutoSave(String sessionId, CheckoutStepType stepType, Map<String, dynamic> stepData, SecurityContextModel securityContext) {
    // Cancel any pending auto-save for this session
    _stopAutoSaveTimer(sessionId);

    // Store the pending save data
    _pendingSaves[sessionId] = {
      'stepType': stepType,
      'stepData': stepData,
      'securityContext': securityContext,
      'timestamp': DateTime.now(),
      'version': _autoSaveVersions[sessionId] ?? 1,
    };

    // Start debounced timer
    _startDebounceTimer(sessionId);
  }

  // Immediate auto-save (for critical data)
  Future<bool> immediateAutoSave(String sessionId, CheckoutStepType stepType, Map<String, dynamic> stepData, SecurityContextModel securityContext) async {
    try {
      final result = await _performAutoSave(
        sessionId: sessionId,
        stepType: stepType,
        stepData: stepData,
        securityContext: securityContext,
        version: _autoSaveVersions[sessionId] ?? 1,
      );

      if (result) {
        _autoSaveVersions[sessionId] = (_autoSaveVersions[sessionId] ?? 1) + 1;
        _lastAutoSave[sessionId] = DateTime.now();
      }

      return result;
    } catch (e) {
      print('Error in immediate auto-save: $e');
      return false;
    }
  }

  // Conflict resolution
  Future<bool> resolveConflict(String sessionId, Map<String, dynamic> serverData, Map<String, dynamic> localData) async {
    try {
      // Get the current session
      final currentSession = await localDataSource.getSession(sessionId);
      if (currentSession == null) {
        return false;
      }

      // Analyze the conflict
      final conflictResolution = _analyzeConflict(serverData, localData);

      // Apply resolution
      final resolvedData = await _applyConflictResolution(
        sessionId: sessionId,
        currentSession: currentSession,
        conflictResolution: conflictResolution,
      );

      if (resolvedData != null) {
        // Save the resolved session
        final success = await localDataSource.saveSession(resolvedData);

        // Log conflict resolution
        auditService.logAutoSaveEvent(
          sessionId: sessionId,
          userId: currentSession.userId,
          eventType: 'conflict_resolved',
          details: {
            'resolutionStrategy': conflictResolution['strategy'],
            'resolutionApplied': true,
            'newVersion': _autoSaveVersions[sessionId],
          },
        );

        return success;
      }

      return false;
    } catch (e) {
      print('Error resolving conflict: $e');
      return false;
    }
  }

  // Get auto-save status
  Map<String, dynamic> getAutoSaveStatus(String sessionId) {
    final lastSave = _lastAutoSave[sessionId];
    final isAutoSaving = _autoSaveTimers.containsKey(sessionId);
    final hasPendingSave = _pendingSaves.containsKey(sessionId);
    final version = _autoSaveVersions[sessionId] ?? 0;

    return {
      'isAutoSaving': isAutoSaving,
      'hasPendingSave': hasPendingSave,
      'lastAutoSave': lastSave?.toIso8601String(),
      'version': version,
      'nextAutoSaveIn': lastSave != null
          ? _autoSaveInterval.inSeconds - DateTime.now().difference(lastSave).inSeconds
          : _autoSaveInterval.inSeconds,
    };
  }

  // Auto-save timer management
  void _startAutoSaveTimer(String sessionId) {
    _autoSaveTimers[sessionId] = Timer.periodic(
      _autoSaveInterval,
      (timer) async {
        await _performPeriodicAutoSave(sessionId);
      },
    );
  }

  void _stopAutoSaveTimer(String sessionId) {
    _autoSaveTimers[sessionId]?.cancel();
    _autoSaveTimers.remove(sessionId);
  }

  void _startDebounceTimer(String sessionId) {
    _autoSaveTimers['debounce_$sessionId'] = Timer(
      _debounceDelay,
      () async {
        await _performDebouncedAutoSave(sessionId);
      },
    );
  }

  Future<void> _performPeriodicAutoSave(String sessionId) async {
    try {
      // Get the current session
      final session = await localDataSource.getSession(sessionId);
      if (session == null) {
        _stopAutoSaveTimer(sessionId);
        return;
      }

      // Check if session is still active
      if (session.isExpired || session.isAbandoned) {
        stopAutoSave(sessionId);
        return;
      }

      // Perform auto-save with current session data
      final success = await _performAutoSave(
        sessionId: sessionId,
        stepType: session.currentStep,
        stepData: session.stepData[session.currentStep] ?? {},
        securityContext: SecurityContextModel(
          sessionId: sessionId,
          userId: session.userId,
          ipAddress: 'auto-save',
          userAgent: 'auto-save-service',
          deviceFingerprint: 'auto-save',
          riskLevel: RiskLevel.low,
          validationTimestamp: DateTime.now(),
        ),
        version: _autoSaveVersions[sessionId] ?? 1,
      );

      if (success) {
        _autoSaveVersions[sessionId] = (_autoSaveVersions[sessionId] ?? 1) + 1;
        _lastAutoSave[sessionId] = DateTime.now();

        // Log successful auto-save
        auditService.logAutoSaveEvent(
          sessionId: sessionId,
          userId: session.userId,
          eventType: 'auto_save_completed',
          details: {
            'version': _autoSaveVersions[sessionId]! - 1,
            'interval': _autoSaveInterval.inSeconds,
          },
        );
      }
    } catch (e) {
      print('Error in periodic auto-save: $e');
    }
  }

  Future<void> _performDebouncedAutoSave(String sessionId) async {
    try {
      final pendingSave = _pendingSaves[sessionId];
      if (pendingSave == null) {
        return;
      }

      final success = await _performAutoSave(
        sessionId: sessionId,
        stepType: pendingSave['stepType'],
        stepData: pendingSave['stepData'],
        securityContext: pendingSave['securityContext'],
        version: pendingSave['version'],
      );

      if (success) {
        _autoSaveVersions[sessionId] = (_autoSaveVersions[sessionId] ?? 1) + 1;
        _lastAutoSave[sessionId] = DateTime.now();
      }

      // Clear pending save
      _pendingSaves.remove(sessionId);

      // Restart auto-save timer
      _startAutoSaveTimer(sessionId);

      // Log debounced auto-save
      auditService.logAutoSaveEvent(
        sessionId: sessionId,
        userId: pendingSave['securityContext'].userId,
        eventType: 'auto_save_debounced',
        details: {
          'success': success,
          'version': _autoSaveVersions[sessionId]! - 1,
        },
      );
    } catch (e) {
      print('Error in debounced auto-save: $e');
    }
  }

  Future<bool> _performAutoSave({
    required String sessionId,
    required CheckoutStepType stepType,
    required Map<String, dynamic> stepData,
    required SecurityContextModel securityContext,
    required int version,
  }) async {
    try {
      // Get existing session
      final existingSession = await localDataSource.getSession(sessionId);
      if (existingSession == null) {
        return false;
      }

      // Check for conflicts
      final conflictDetected = await _checkForConflicts(sessionId, version);
      if (conflictDetected) {
        // Attempt to resolve conflict
        final resolved = await resolveConflict(
          sessionId,
          existingSession.toJson(),
          {'stepType': stepType.name, 'stepData': stepData},
        );

        if (!resolved) {
          // Log conflict resolution failure
          auditService.logAutoSaveEvent(
            sessionId: sessionId,
            userId: securityContext.userId,
            eventType: 'conflict_resolution_failed',
            details: {
              'version': version,
              'stepType': stepType.name,
            },
          );
          return false;
        }
      }

      // Update session data
      final updatedStepData = Map<String, dynamic>.from(existingSession.stepData);
      updatedStepData[stepType] = stepData;

      final updatedSession = existingSession.copyWith(
        currentStep: stepType,
        stepData: updatedStepData,
        lastActivity: DateTime.now(),
      );

      // Save the updated session
      final success = await localDataSource.saveSession(updatedSession);

      if (success) {
        // Log successful auto-save
        auditService.logAutoSaveEvent(
          sessionId: sessionId,
          userId: securityContext.userId,
          eventType: 'auto_save_successful',
          details: {
            'stepType': stepType.name,
            'version': version,
            'dataSize': stepData.toString().length,
          },
        );
      }

      return success;
    } catch (e) {
      print('Error performing auto-save: $e');

      // Log auto-save failure
      auditService.logAutoSaveEvent(
        sessionId: sessionId,
        userId: securityContext.userId,
        eventType: 'auto_save_failed',
        details: {
          'stepType': stepType.name,
          'version': version,
          'error': e.toString(),
        },
      );

      return false;
    }
  }

  Future<bool> _checkForConflicts(String sessionId, int version) async {
    try {
      // This would check against server data or other conflicts
      // For now, we'll use a simple version check
      final currentVersion = _autoSaveVersions[sessionId] ?? 1;
      return currentVersion > version;
    } catch (e) {
      print('Error checking for conflicts: $e');
      return false;
    }
  }

  Map<String, dynamic> _analyzeConflict(Map<String, dynamic> serverData, Map<String, dynamic> localData) {
    // Analyze the differences between server and local data
    final serverStep = serverData['stepType'];
    final localStep = localData['stepType'];

    // Simple resolution strategy: prefer local changes for the current step
    if (serverStep == localStep) {
      return {
        'strategy': 'merge',
        'reason': 'same_step_changes',
        'confidence': 0.8,
      };
    } else {
      return {
        'strategy': 'local_wins',
        'reason': 'different_steps',
        'confidence': 0.9,
      };
    }
  }

  Future<CheckoutSessionModel?> _applyConflictResolution({
    required String sessionId,
    required CheckoutSessionModel currentSession,
    required Map<String, dynamic> conflictResolution,
  }) async {
    try {
      final strategy = conflictResolution['strategy'];

      switch (strategy) {
        case 'merge':
          // Merge server and local data
          return currentSession.copyWith(
            lastActivity: DateTime.now(),
          );

        case 'local_wins':
          // Keep local changes
          return currentSession.copyWith(
            lastActivity: DateTime.now(),
          );

        case 'server_wins':
          // Keep server changes (would fetch from server)
          return currentSession.copyWith(
            lastActivity: DateTime.now(),
          );

        default:
          return currentSession.copyWith(
            lastActivity: DateTime.now(),
          );
      }
    } catch (e) {
      print('Error applying conflict resolution: $e');
      return null;
    }
  }

  // Cleanup methods
  Future<void> cleanupOldAutoSaveData() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(days: 7));
      final sessions = await localDataSource.getAllSessions();

      for (final session in sessions) {
        if (session.createdAt.isBefore(cutoffTime)) {
          stopAutoSave(session.sessionId);
        }
      }
    } catch (e) {
      print('Error cleaning up old auto-save data: $e');
    }
  }

  // Get auto-save statistics
  Map<String, dynamic> getAutoSaveStats() {
    final activeSessions = _autoSaveTimers.keys.where((key) => !key.startsWith('debounce_')).length;
    final pendingSaves = _pendingSaves.length;
    final totalVersions = _autoSaveVersions.values.fold(0, (sum, version) => sum + version);

    return {
      'activeAutoSaveSessions': activeSessions,
      'pendingSaves': pendingSaves,
      'totalVersions': totalVersions,
      'averageVersion': activeSessions > 0 ? totalVersions / activeSessions : 0.0,
    };
  }

  // Force auto-save for testing
  Future<bool> forceAutoSave(String sessionId) async {
    try {
      final session = await localDataSource.getSession(sessionId);
      if (session == null) {
        return false;
      }

      return await immediateAutoSave(
        sessionId,
        session.currentStep,
        session.stepData[session.currentStep] ?? {},
        SecurityContextModel(
          sessionId: sessionId,
          userId: session.userId,
          ipAddress: 'forced-auto-save',
          userAgent: 'test',
          deviceFingerprint: 'test',
          riskLevel: RiskLevel.low,
          validationTimestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Error forcing auto-save: $e');
      return false;
    }
  }

  void dispose() {
    // Clean up all timers
    for (final timer in _autoSaveTimers.values) {
      timer.cancel();
    }
    _autoSaveTimers.clear();
    _pendingSaves.clear();
    _lastAutoSave.clear();
    _autoSaveVersions.clear();
  }
}