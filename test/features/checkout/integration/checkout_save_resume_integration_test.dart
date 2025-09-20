import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:video_window/features/checkout/domain/usecases/save_checkout_session_usecase.dart';
import 'package:video_window/features/checkout/domain/usecases/resume_checkout_session_usecase.dart';
import 'package:video_window/features/checkout/data/services/checkout_auto_save_service.dart';
import 'package:video_window/features/checkout/data/services/checkout_abandonment_service.dart';
import 'package:video_window/features/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:video_window/features/checkout/data/datasources/checkout_local_data_source.dart';
import 'package:video_window/features/checkout/data/datasources/checkout_remote_data_source.dart';
import 'package:video_window/features/checkout/data/services/checkout_audit_service.dart';
import 'package:video_window/features/checkout/domain/models/checkout_session_model.dart';
import 'package:video_window/features/checkout/domain/models/checkout_security_model.dart';
import 'package:video_window/core/error/failure.dart';

class MockCheckoutLocalDataSource extends Mock implements CheckoutLocalDataSource {}
class MockCheckoutRemoteDataSource extends Mock implements CheckoutRemoteDataSource {}
class MockCheckoutAuditService extends Mock implements CheckoutAuditService {}

void main() {
  group('Checkout Save/Resume Integration Tests', () {
    late CheckoutRepositoryImpl repository;
    late SaveCheckoutSessionUseCase saveUseCase;
    late ResumeCheckoutSessionUseCase resumeUseCase;
    late CheckoutAutoSaveService autoSaveService;
    late CheckoutAbandonmentService abandonmentService;
    late MockCheckoutLocalDataSource mockLocalDataSource;
    late MockCheckoutRemoteDataSource mockRemoteDataSource;
    late MockCheckoutAuditService mockAuditService;

    setUp(() {
      mockLocalDataSource = MockCheckoutLocalDataSource();
      mockRemoteDataSource = MockCheckoutRemoteDataSource();
      mockAuditService = MockCheckoutAuditService();

      repository = CheckoutRepositoryImpl(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource,
      );

      saveUseCase = SaveCheckoutSessionUseCase(repository);
      resumeUseCase = ResumeCheckoutSessionUseCase(repository);

      autoSaveService = CheckoutAutoSaveService(
        localDataSource: mockLocalDataSource,
        auditService: mockAuditService,
      );

      abandonmentService = CheckoutAbandonmentService(
        remoteDataSource: mockRemoteDataSource,
        localDataSource: mockLocalDataSource,
        auditService: mockAuditService,
      );
    });

    tearDown(() {
      autoSaveService.dispose();
      abandonmentService.dispose();
    });

    test('should save session and resume successfully', () async {
      // Arrange
      final sessionId = 'test-session-id';
      final session = CheckoutSessionModel(
        sessionId: sessionId,
        userId: 'user123',
        currentStep: CheckoutStepType.shipping,
        stepData: {
          CheckoutStepType.shipping: {'address': '123 Test St'},
        },
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      final securityContext = SecurityContextModel(
        sessionId: sessionId,
        userId: 'user123',
        ipAddress: '192.168.1.1',
        userAgent: 'Test Browser',
        deviceFingerprint: 'test-fingerprint',
        riskLevel: RiskLevel.low,
        validationTimestamp: DateTime.now(),
      );

      // Setup mocks
      when(() => mockLocalDataSource.saveSession(any()))
          .thenAnswer((_) async => true);
      when(() => mockLocalDataSource.getSession(sessionId))
          .thenAnswer((_) async => session);
      when(() => mockRemoteDataSource.validateSecurity(securityContext))
          .thenAnswer((_) async => SecurityValidationResult(
            isValid: true,
            violations: [],
            recommendedLevel: SecurityLevel.standard,
            recommendations: {},
            validatedAt: DateTime.now(),
          ));
      when(() => mockRemoteDataSource.validateSessionResumption(sessionId))
          .thenAnswer((_) async => true);

      // Act - Save session
      final saveResult = await saveUseCase.call(
        sessionId: sessionId,
        stepData: session.stepData,
        securityContext: securityContext,
      );

      // Assert - Save successful
      expect(saveResult, equals(const Right(true)));
      verify(() => mockLocalDataSource.saveSession(any())).called(1);

      // Act - Resume session
      final resumeResult = await resumeUseCase(sessionId);

      // Assert - Resume successful
      expect(resumeResult, equals(Right(session)));
      verify(() => mockLocalDataSource.getSession(sessionId)).called(1);
      verify(() => mockRemoteDataSource.validateSessionResumption(sessionId)).called(1);
    });

    test('should handle session with auto-save enabled', () async {
      // Arrange
      final sessionId = 'auto-save-session';
      final session = CheckoutSessionModel(
        sessionId: sessionId,
        userId: 'user123',
        currentStep: CheckoutStepType.shipping,
        stepData: {
          CheckoutStepType.shipping: {'address': '123 Test St'},
        },
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      final securityContext = SecurityContextModel(
        sessionId: sessionId,
        userId: 'user123',
        ipAddress: '192.168.1.1',
        userAgent: 'Test Browser',
        deviceFingerprint: 'test-fingerprint',
        riskLevel: RiskLevel.low,
        validationTimestamp: DateTime.now(),
      );

      // Setup mocks
      when(() => mockLocalDataSource.saveSession(any()))
          .thenAnswer((_) async => true);
      when(() => mockLocalDataSource.getSession(sessionId))
          .thenAnswer((_) async => session);
      when(() => mockRemoteDataSource.validateSecurity(securityContext))
          .thenAnswer((_) async => SecurityValidationResult(
            isValid: true,
            violations: [],
            recommendedLevel: SecurityLevel.standard,
            recommendations: {},
            validatedAt: DateTime.now(),
          ));
      when(() => mockRemoteDataSource.validateSessionResumption(sessionId))
          .thenAnswer((_) async => true);

      // Act - Start auto-save
      autoSaveService.startAutoSave(sessionId, session);

      // Assert - Auto-save started
      final status = autoSaveService.getAutoSaveStatus(sessionId);
      expect(status['isAutoSaving'], isTrue);
      expect(status['version'], equals(1));

      // Act - Queue auto-save
      autoSaveService.queueAutoSave(
        sessionId,
        CheckoutStepType.shipping,
        {'address': '456 Updated St'},
        securityContext,
      );

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 600));

      // Assert - Auto-save should have attempted
      verify(() => mockLocalDataSource.saveSession(any())).called(greaterThanOrEqualTo(1));

      // Act - Stop auto-save
      autoSaveService.stopAutoSave(sessionId);

      // Assert - Auto-save stopped
      final finalStatus = autoSaveService.getAutoSaveStatus(sessionId);
      expect(finalStatus['isAutoSaving'], isFalse);
    });

    test('should handle session abandonment and recovery', () async {
      // Arrange
      final sessionId = 'abandonment-session';
      final session = CheckoutSessionModel(
        sessionId: sessionId,
        userId: 'user123',
        currentStep: CheckoutStepType.payment,
        stepData: {
          CheckoutStepType.shipping: {'address': '123 Test St'},
        },
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        lastActivity: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      // Setup mocks
      when(() => mockLocalDataSource.getSession(sessionId))
          .thenAnswer((_) async => session);
      when(() => mockRemoteDataSource.validateSessionResumption(sessionId))
          .thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.trackAbandonment(
        sessionId: sessionId,
        reason: any(named: 'reason'),
      )).thenAnswer((_) async => true);

      // Act - Start abandonment monitoring
      abandonmentService.startSessionMonitoring(sessionId, session);

      // Simulate abandonment by updating activity
      abandonmentService.updateSessionActivity(sessionId);
      abandonmentService.updateStepProgress(
        sessionId,
        CheckoutStepType.payment,
        {'method': 'credit_card'},
      );

      // Wait for potential abandonment detection
      await Future.delayed(const Duration(milliseconds: 100));

      // Act - Stop monitoring
      abandonmentService.stopSessionMonitoring(sessionId);

      // Assert - Monitoring stopped
      final stats = abandonmentService.getAbandonmentStats();
      expect(stats['activeSessions'], equals(0));
    });

    test('should handle session conflict resolution', () async {
      // Arrange
      final sessionId = 'conflict-session';
      final session = CheckoutSessionModel(
        sessionId: sessionId,
        userId: 'user123',
        currentStep: CheckoutStepType.shipping,
        stepData: {
          CheckoutStepType.shipping: {'address': 'Local Address'},
        },
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      final serverData = {
        'stepType': 'shipping',
        'address': 'Server Address',
        'lastModified': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      };

      final localData = {
        'stepType': 'shipping',
        'address': 'Local Address',
        'lastModified': DateTime.now().toIso8601String(),
      };

      // Setup mocks
      when(() => mockLocalDataSource.getSession(sessionId))
          .thenAnswer((_) async => session);
      when(() => mockLocalDataSource.saveSession(any()))
          .thenAnswer((_) async => true);

      // Act - Resolve conflict
      final resolved = await autoSaveService.resolveConflict(sessionId, serverData, localData);

      // Assert - Conflict resolved
      expect(resolved, isTrue);
      verify(() => mockLocalDataSource.saveSession(any())).called(1);
    });

    test('should handle save/resume failure scenarios', () async {
      // Arrange
      final sessionId = 'failure-session';
      final securityContext = SecurityContextModel(
        sessionId: sessionId,
        userId: 'user123',
        ipAddress: '192.168.1.1',
        userAgent: 'Test Browser',
        deviceFingerprint: 'test-fingerprint',
        riskLevel: RiskLevel.high,
        validationTimestamp: DateTime.now(),
      );

      // Setup mocks for security failure
      when(() => mockRemoteDataSource.validateSecurity(securityContext))
          .thenAnswer((_) async => SecurityValidationResult(
            isValid: false,
            violations: ['High risk detected'],
            recommendedLevel: SecurityLevel.enhanced,
            recommendations: {},
            validatedAt: DateTime.now(),
          ));

      // Act - Attempt save with security failure
      final saveResult = await saveUseCase.call(
        sessionId: sessionId,
        stepData: {CheckoutStepType.shipping: {'address': '123 Test St'}},
        securityContext: securityContext,
      );

      // Assert - Save should fail due to security
      expect(saveResult, isA<Left<Failure, bool>>());
      final failure = saveResult.fold((l) => l, (r) => null);
      expect(failure, isA<SecurityFailure>());

      // Setup mocks for session not found
      when(() => mockLocalDataSource.getSession(sessionId))
          .thenAnswer((_) async => null);

      // Act - Attempt to resume non-existent session
      final resumeResult = await resumeUseCase(sessionId);

      // Assert - Resume should fail
      expect(resumeResult, isA<Left<Failure, CheckoutSessionModel>>());
    });

    test('should handle auto-save failure gracefully', () async {
      // Arrange
      final sessionId = 'auto-save-failure-session';
      final session = CheckoutSessionModel(
        sessionId: sessionId,
        userId: 'user123',
        currentStep: CheckoutStepType.shipping,
        stepData: {},
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      final securityContext = SecurityContextModel(
        sessionId: sessionId,
        userId: 'user123',
        ipAddress: '192.168.1.1',
        userAgent: 'Test Browser',
        deviceFingerprint: 'test-fingerprint',
        riskLevel: RiskLevel.low,
        validationTimestamp: DateTime.now(),
      );

      // Setup mocks for auto-save failure
      when(() => mockLocalDataSource.getSession(sessionId))
          .thenAnswer((_) async => session);
      when(() => mockLocalDataSource.saveSession(any()))
          .thenAnswer((_) async => false);

      // Act - Start auto-save and attempt immediate save
      autoSaveService.startAutoSave(sessionId, session);
      final result = await autoSaveService.immediateAutoSave(
        sessionId,
        CheckoutStepType.shipping,
        {'address': '123 Test St'},
        securityContext,
      );

      // Assert - Auto-save should handle failure gracefully
      expect(result, isFalse);
      verify(() => mockLocalDataSource.saveSession(any())).called(1);
    });

    test('should cleanup old sessions properly', () async {
      // Arrange
      final oldSession = CheckoutSessionModel(
        sessionId: 'old-session',
        userId: 'user123',
        currentStep: CheckoutStepType.shipping,
        stepData: {},
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        expiresAt: DateTime.now().subtract(const Duration(days: 7)),
      );

      final recentSession = CheckoutSessionModel(
        sessionId: 'recent-session',
        userId: 'user123',
        currentStep: CheckoutStepType.shipping,
        stepData: {},
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      // Setup mocks
      when(() => mockLocalDataSource.getAllSessions())
          .thenAnswer((_) async => [oldSession, recentSession]);

      // Act - Start auto-save for both sessions
      autoSaveService.startAutoSave('old-session', oldSession);
      autoSaveService.startAutoSave('recent-session', recentSession);

      // Cleanup old sessions
      await autoSaveService.cleanupOldAutoSaveData();

      // Assert - Old session should be stopped, recent session should continue
      final oldStatus = autoSaveService.getAutoSaveStatus('old-session');
      final recentStatus = autoSaveService.getAutoSaveStatus('recent-session');

      expect(oldStatus['isAutoSaving'], isFalse);
      expect(recentStatus['isAutoSaving'], isTrue);
    });
  });
}