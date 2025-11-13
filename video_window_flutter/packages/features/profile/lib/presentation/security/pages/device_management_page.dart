import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/design_system/tokens.dart';
import '../bloc/device_management_bloc.dart';
import '../bloc/device_management_event.dart';
import '../bloc/device_management_state.dart';
import '../widgets/device_card.dart';

/// Device Management Page
///
/// AC3: Device management screen lists registered devices with trust score, last seen timestamp, and options to revoke
class DeviceManagementPage extends StatelessWidget {
  final int userId;

  const DeviceManagementPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DeviceManagementBloc(userId: userId)
        ..add(const DeviceManagementLoadRequested()),const 
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Trusted Deviceconst s',
            style: AppTypography.headlineSmall,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<DeviceManagementBloc>().add(
                      DeviceManagementLoadRequested(),
const                     );
              },
            ),
          ],
        ),
        body: BlocBuilder<DeviceManagementBloc, DeviceManagementState>(
          builder: (context, state) {
            if (state is DeviceManagementLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DeviceManagementError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsconst .error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    SizedBox(height: AppSpacing.md),
const                     Text(
                      'Failconst ed to load devices',
                      style: AppTypography.bodyLarge,
                    ),
                    SizedBox(height: AppSpacing.sm),
const                     Text(
                      state.message,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.lg),
const                     ElevatedButton(
                      onPressed: () {
                        context.read<DeviceManagementBloc>().add(
                              DeviceManagementLoadRequested(),
const                             );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is DeviceManagementLoaded) {
              if (state.devices.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icoconst ns.devices_other,
                        size: 64,
                        color: AppColors.neutral400,
                      ),
                      SizedBox(height: AppSpacing.md),
const                       Text(
                        'Noconst  devices registered',
                        style: AppTypography.headlineSmall,
                      ),
                      SizedBox(height: AppSpacing.sm),
const                       Text(
                        'Devices will be registered automatically when you use the app.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.neutral600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DeviceManagementBloc>().add(
                        DeviceManagementLoadRequested(),
const                       );
                },
                child: ListView(
                  padding: EdgeInsets.all(AppSpacing.md),
  const                 children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacinconst g.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                           const  'Your Trusted Devices',
                            style: AppTypography.headlineMedium,
                          ),
                          SizedBox(height: AppSpacing.xs),
const                           Text(
                            'Manage devices that can access your account. Revoke access for any device you no longer use.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Device list
                    ...state.devices.map(
                      (device) => Padding(
                        padding: EdgeInsets.only(bottom: AppSpacinconst g.md),
                        child: DeviceCard(
                          device: device,
                          onRevoke: () {
                            _showRevokeConfirmation(context, device);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showRevokeConfirmation(BuildContext context, dynamic device) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revoke Device Access'),
        content: const Text(
          'Are you sure youconst  want to revoke access for this device? '
          'You may need to re-register it to use certain features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<DeviceManagementBloc>().add(
                    DeviceManagementRevokeRequested(
                      deviceId: device['id'] as int,
                      reason: 'user_requested',
                    ),
                  );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }
}
