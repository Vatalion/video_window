import '../models/payment_model.dart';

enum AuditEventType {
  paymentInitiated,
  paymentProcessed,
  paymentFailed,
  paymentRefunded,
  paymentCancelled,
  cardAdded,
  cardRemoved,
  cardUpdated,
  tokenGenerated,
  tokenRevoked,
  fraudAlert,
  securityViolation,
  pciComplianceCheck,
  paymentGatewayConfigured,
  paymentGatewayFailure,
  recurringPaymentCreated,
  recurringPaymentCancelled,
  threeDSecureVerification,
}

class AuditEvent extends Equatable {
  final String id;
  final AuditEventType eventType;
  final String userId;
  final String? paymentId;
  final String? cardId;
  final String? transactionId;
  final String? ipAddress;
  final String? deviceId;
  final Map<String, dynamic> eventData;
  final DateTime timestamp;
  final String? sessionId;

  const AuditEvent({
    required this.id,
    required this.eventType,
    required this.userId,
    this.paymentId,
    this.cardId,
    this.transactionId,
    this.ipAddress,
    this.deviceId,
    required this.eventData,
    required this.timestamp,
    this.sessionId,
  });

  factory AuditEvent.fromJson(Map<String, dynamic> json) {
    return AuditEvent(
      id: json['id'] as String,
      eventType: AuditEventType.values.firstWhere(
        (e) => e.name == json['event_type'],
        orElse: () => AuditEventType.paymentInitiated,
      ),
      userId: json['user_id'] as String,
      paymentId: json['payment_id'] as String?,
      cardId: json['card_id'] as String?,
      transactionId: json['transaction_id'] as String?,
      ipAddress: json['ip_address'] as String?,
      deviceId: json['device_id'] as String?,
      eventData: Map<String, dynamic>.from(json['event_data'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      sessionId: json['session_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_type': eventType.name,
      'user_id': userId,
      'payment_id': paymentId,
      'card_id': cardId,
      'transaction_id': transactionId,
      'ip_address': ipAddress,
      'device_id': deviceId,
      'event_data': eventData,
      'timestamp': timestamp.toIso8601String(),
      'session_id': sessionId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        eventType,
        userId,
        paymentId,
        cardId,
        transactionId,
        ipAddress,
        deviceId,
        eventData,
        timestamp,
        sessionId,
      ];
}

abstract class PaymentAuditRepository {
  Future<AuditEvent> logEvent({
    required AuditEventType eventType,
    required String userId,
    String? paymentId,
    String? cardId,
    String? transactionId,
    String? ipAddress,
    String? deviceId,
    required Map<String, dynamic> eventData,
    String? sessionId,
  });

  Future<List<AuditEvent>> getEventsByUserId(String userId);
  Future<List<AuditEvent>> getEventsByPaymentId(String paymentId);
  Future<List<AuditEvent>> getEventsByCardId(String cardId);
  Future<List<AuditEvent>> getEventsByType(AuditEventType eventType);
  Future<List<AuditEvent>> getEventsByDateRange(DateTime start, DateTime end);
  Future<List<AuditEvent>> getSecurityEvents();

  Future<AuditEvent?> getEventById(String eventId);
  Future<bool> deleteEvent(String eventId);

  Future<Map<String, dynamic>> generateAuditReport({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    List<AuditEventType>? eventTypes,
  });

  Future<List<AuditEvent>> getFraudRelatedEvents();
  Future<List<AuditEvent>> getPaymentGatewayEvents();

  Future<bool> exportAuditLog({
    String? format,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  });

  Stream<AuditEvent> getAuditEventStream({
    String? userId,
    List<AuditEventType>? eventTypes,
  });

  Future<Map<String, dynamic>> getAuditStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<AuditEvent>> getComplianceEvents();
  Future<bool> verifyAuditLogIntegrity();
}