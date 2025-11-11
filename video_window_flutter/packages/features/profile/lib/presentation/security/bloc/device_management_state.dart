import 'package:equatable/equatable.dart';

/// States for device management
abstract class DeviceManagementState extends Equatable {
  const DeviceManagementState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DeviceManagementInitial extends DeviceManagementState {
  const DeviceManagementInitial();
}

/// Loading state
class DeviceManagementLoading extends DeviceManagementState {
  const DeviceManagementLoading();
}

/// Loaded state with devices
class DeviceManagementLoaded extends DeviceManagementState {
  final List<Map<String, dynamic>> devices;

  const DeviceManagementLoaded({required this.devices});

  @override
  List<Object?> get props => [devices];
}

/// Error state
class DeviceManagementError extends DeviceManagementState {
  final String message;

  const DeviceManagementError({required this.message});

  @override
  List<Object?> get props => [message];
}
