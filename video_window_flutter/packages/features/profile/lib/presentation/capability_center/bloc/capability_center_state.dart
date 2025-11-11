import 'package:equatable/equatable.dart';

/// States for CapabilityCenterBloc
abstract class CapabilityCenterState extends Equatable {
  const CapabilityCenterState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CapabilityCenterInitial extends CapabilityCenterState {
  const CapabilityCenterInitial();
}

/// Loading state
class CapabilityCenterLoading extends CapabilityCenterState {
  const CapabilityCenterLoading();
}

/// Loaded state with capability data
class CapabilityCenterLoaded extends CapabilityCenterState {
  final int userId;
  final bool canPublish;
  final bool canCollectPayments;
  final bool canFulfillOrders;
  final DateTime? identityVerifiedAt;
  final DateTime? payoutConfiguredAt;
  final DateTime? fulfillmentEnabledAt;
  final String reviewState;
  final Map<String, String> blockers;
  final bool isPolling;

  const CapabilityCenterLoaded({
    required this.userId,
    required this.canPublish,
    required this.canCollectPayments,
    required this.canFulfillOrders,
    this.identityVerifiedAt,
    this.payoutConfiguredAt,
    this.fulfillmentEnabledAt,
    required this.reviewState,
    required this.blockers,
    this.isPolling = false,
  });

  @override
  List<Object?> get props => [
        userId,
        canPublish,
        canCollectPayments,
        canFulfillOrders,
        identityVerifiedAt,
        payoutConfiguredAt,
        fulfillmentEnabledAt,
        reviewState,
        blockers,
        isPolling,
      ];

  /// Copy with method for state updates
  CapabilityCenterLoaded copyWith({
    int? userId,
    bool? canPublish,
    bool? canCollectPayments,
    bool? canFulfillOrders,
    DateTime? identityVerifiedAt,
    DateTime? payoutConfiguredAt,
    DateTime? fulfillmentEnabledAt,
    String? reviewState,
    Map<String, String>? blockers,
    bool? isPolling,
  }) {
    return CapabilityCenterLoaded(
      userId: userId ?? this.userId,
      canPublish: canPublish ?? this.canPublish,
      canCollectPayments: canCollectPayments ?? this.canCollectPayments,
      canFulfillOrders: canFulfillOrders ?? this.canFulfillOrders,
      identityVerifiedAt: identityVerifiedAt ?? this.identityVerifiedAt,
      payoutConfiguredAt: payoutConfiguredAt ?? this.payoutConfiguredAt,
      fulfillmentEnabledAt: fulfillmentEnabledAt ?? this.fulfillmentEnabledAt,
      reviewState: reviewState ?? this.reviewState,
      blockers: blockers ?? this.blockers,
      isPolling: isPolling ?? this.isPolling,
    );
  }

  /// Check if any capability is blocked
  bool get hasBlockers => blockers.isNotEmpty;

  /// Check if under review
  bool get isUnderReview =>
      reviewState == 'pending' || reviewState == 'manualReview';
}

/// Request in progress state
class CapabilityCenterRequesting extends CapabilityCenterState {
  final String capability;

  const CapabilityCenterRequesting(this.capability);

  @override
  List<Object?> get props => [capability];
}

/// Error state
class CapabilityCenterError extends CapabilityCenterState {
  final String message;
  final String? errorCode;

  const CapabilityCenterError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
