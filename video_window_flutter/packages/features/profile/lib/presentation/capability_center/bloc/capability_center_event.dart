import 'package:equatable/equatable.dart';

/// Events for CapabilityCenterBloc
abstract class CapabilityCenterEvent extends Equatable {
  const CapabilityCenterEvent();

  @override
  List<Object?> get props => [];
}

/// Load capability status
class CapabilityCenterLoadRequested extends CapabilityCenterEvent {
  final int userId;

  const CapabilityCenterLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Request a capability
class CapabilityCenterRequestSubmitted extends CapabilityCenterEvent {
  final int userId;
  final String capability;
  final String entryPoint;
  final Map<String, String>? context;

  const CapabilityCenterRequestSubmitted({
    required this.userId,
    required this.capability,
    required this.entryPoint,
    this.context,
  });

  @override
  List<Object?> get props => [userId, capability, entryPoint, context];
}

/// Refresh capability status
class CapabilityCenterRefreshRequested extends CapabilityCenterEvent {
  final int userId;

  const CapabilityCenterRefreshRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Start polling for status updates
class CapabilityCenterPollingStarted extends CapabilityCenterEvent {
  final int userId;

  const CapabilityCenterPollingStarted(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Stop polling
class CapabilityCenterPollingStopped extends CapabilityCenterEvent {
  const CapabilityCenterPollingStopped();
}
