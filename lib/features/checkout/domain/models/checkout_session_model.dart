import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'checkout_session_model.g.dart';

@JsonSerializable()
class CheckoutSessionModel extends Equatable {
  final String sessionId;
  final String userId;
  final bool isGuest;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;
  final CheckoutStepType currentStep;
  final Map<CheckoutStepType, Map<String, dynamic>> stepData;
  final List<CheckoutStepType> completedSteps;
  final String? savedPaymentMethodId;
  final String? shippingAddressId;
  final String? billingAddressId;
  final String? couponCode;
  final bool isAbandoned;
  final DateTime? abandonedAt;
  final Map<String, dynamic> securityContext;
  final String sessionToken;
  final int version;

  const CheckoutSessionModel({
    required this.sessionId,
    required this.userId,
    required this.isGuest,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    required this.currentStep,
    required this.stepData,
    required this.completedSteps,
    this.savedPaymentMethodId,
    this.shippingAddressId,
    this.billingAddressId,
    this.couponCode,
    this.isAbandoned = false,
    this.abandonedAt,
    required this.securityContext,
    required this.sessionToken,
    required this.version,
  });

  factory CheckoutSessionModel.create({
    required String userId,
    bool isGuest = false,
    Duration sessionDuration = const Duration(hours: 2),
  }) {
    final now = DateTime.now();
    return CheckoutSessionModel(
      sessionId: const Uuid().v4(),
      userId: userId,
      isGuest: isGuest,
      createdAt: now,
      updatedAt: now,
      expiresAt: now.add(sessionDuration),
      currentStep: CheckoutStepType.cartReview,
      stepData: {},
      completedSteps: [],
      securityContext: {
        'deviceFingerprint': const Uuid().v4(),
        'ipAddress': 'unknown',
        'userAgent': 'Flutter App',
        'lastActivity': now.toIso8601String(),
        'securityLevel': 'standard',
      },
      sessionToken: const Uuid().v4(),
      version: 1,
    );
  }

  factory CheckoutSessionModel.fromJson(Map<String, dynamic> json) =>
      _$CheckoutSessionModelFromJson(json);

  Map<String, dynamic> toJson() => _$CheckoutSessionModelToJson(this);

  CheckoutSessionModel copyWith({
    String? sessionId,
    String? userId,
    bool? isGuest,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    CheckoutStepType? currentStep,
    Map<CheckoutStepType, Map<String, dynamic>>? stepData,
    List<CheckoutStepType>? completedSteps,
    String? savedPaymentMethodId,
    String? shippingAddressId,
    String? billingAddressId,
    String? couponCode,
    bool? isAbandoned,
    DateTime? abandonedAt,
    Map<String, dynamic>? securityContext,
    String? sessionToken,
    int? version,
  }) {
    return CheckoutSessionModel(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      expiresAt: expiresAt ?? this.expiresAt,
      currentStep: currentStep ?? this.currentStep,
      stepData: stepData ?? this.stepData,
      completedSteps: completedSteps ?? this.completedSteps,
      savedPaymentMethodId: savedPaymentMethodId ?? this.savedPaymentMethodId,
      shippingAddressId: shippingAddressId ?? this.shippingAddressId,
      billingAddressId: billingAddressId ?? this.billingAddressId,
      couponCode: couponCode ?? this.couponCode,
      isAbandoned: isAbandoned ?? this.isAbandoned,
      abandonedAt: abandonedAt ?? this.abandonedAt,
      securityContext: securityContext ?? this.securityContext,
      sessionToken: sessionToken ?? this.sessionToken,
      version: (version ?? this.version) + 1,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isValid => !isExpired && !isAbandoned;

  double get completionProgress {
    if (completedSteps.isEmpty) return 0.0;
    return completedSteps.length / CheckoutStepDefinition.getStandardSteps().length;
  }

  void updateSecurityContext(Map<String, dynamic> updates) {
    securityContext.addAll(updates);
    securityContext['lastActivity'] = DateTime.now().toIso8601String();
  }

  @override
  List<Object?> get props => [
        sessionId,
        userId,
        isGuest,
        createdAt,
        updatedAt,
        expiresAt,
        currentStep,
        stepData,
        completedSteps,
        savedPaymentMethodId,
        shippingAddressId,
        billingAddressId,
        couponCode,
        isAbandoned,
        abandonedAt,
        securityContext,
        sessionToken,
        version,
      ];
}