import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/data/services/devices/device_trust_service.dart';
import 'device_management_event.dart';
import 'device_management_state.dart';

/// BLoC for device management
class DeviceManagementBloc
    extends Bloc<DeviceManagementEvent, DeviceManagementState> {
  final DeviceTrustService _deviceTrustService;
  final int userId;

  DeviceManagementBloc({
    required this.userId,
    DeviceTrustService? deviceTrustService,
  })  : _deviceTrustService = deviceTrustService ??
            DeviceTrustService(
              // TODO: Inject dependencies properly
              throw UnimplementedError('DeviceTrustService must be injected'),
              throw UnimplementedError('SecureTokenStorage must be injected'),
            ),
        super(const DeviceManagementInitial()) {
    on<DeviceManagementLoadRequested>(_onLoadRequested);
    on<DeviceManagementRevokeRequested>(_onRevokeRequested);
  }

  Future<void> _onLoadRequested(
    DeviceManagementLoadRequested event,
    Emitter<DeviceManagementState> emit,
  ) async {
    emit(const DeviceManagementLoading());

    try {
      final devices = await _deviceTrustService.getUserDevices(userId);
      // Convert devices to map format for UI
      final deviceMaps = devices.map((device) {
        // TODO: Convert device object to map when generated types are available
        return <String, dynamic>{
          'id': device['id'],
          'deviceId': device['deviceId'],
          'deviceType': device['deviceType'],
          'platform': device['platform'],
          'trustScore': device['trustScore'],
          'lastSeenAt': device['lastSeenAt'],
          'createdAt': device['createdAt'],
        };
      }).toList();

      emit(DeviceManagementLoaded(devices: deviceMaps));
    } catch (e) {
      emit(DeviceManagementError(message: e.toString()));
    }
  }

  Future<void> _onRevokeRequested(
    DeviceManagementRevokeRequested event,
    Emitter<DeviceManagementState> emit,
  ) async {
    try {
      await _deviceTrustService.revokeDevice(
        userId: userId,
        deviceId: event.deviceId,
        reason: event.reason,
      );

      // Reload devices after revocation
      add(const DeviceManagementLoadRequested());
    } catch (e) {
      emit(DeviceManagementError(message: 'Failed to revoke device: $e'));
    }
  }
}
