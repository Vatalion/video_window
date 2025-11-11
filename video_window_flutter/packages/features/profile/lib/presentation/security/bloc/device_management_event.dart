import 'package:equatable/equatable.dart';

/// Events for device management
abstract class DeviceManagementEvent extends Equatable {
  const DeviceManagementEvent();

  @override
  List<Object?> get props => [];
}

/// Request to load devices
class DeviceManagementLoadRequested extends DeviceManagementEvent {
  const DeviceManagementLoadRequested();
}

/// Request to revoke a device
class DeviceManagementRevokeRequested extends DeviceManagementEvent {
  final int deviceId;
  final String? reason;

  const DeviceManagementRevokeRequested({
    required this.deviceId,
    this.reason,
  });

  @override
  List<Object?> get props => [deviceId, reason];
}
