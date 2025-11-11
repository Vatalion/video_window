import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/design_system/tokens.dart';
import '../bloc/capability_center_bloc.dart';
import '../bloc/capability_center_event.dart';
import '../bloc/capability_center_state.dart';
import '../widgets/capability_card.dart';

/// Capability Center Page
///
/// AC1: Displays current capability status, blockers, and CTAs for publish,
/// collect_payments, and fulfill_orders capabilities
class CapabilityCenterPage extends StatelessWidget {
  final int userId;

  const CapabilityCenterPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Capabilities',
          style: AppTypography.headlineSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CapabilityCenterBloc>().add(
                    CapabilityCenterRefreshRequested(userId),
                  );
            },
          ),
        ],
      ),
      body: BlocBuilder<CapabilityCenterBloc, CapabilityCenterState>(
        builder: (context, state) {
          if (state is CapabilityCenterInitial ||
              state is CapabilityCenterLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is CapabilityCenterError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Failed to Load Capabilities',
                      style: AppTypography.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      state.message,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: () {
                        context.read<CapabilityCenterBloc>().add(
                              CapabilityCenterLoadRequested(userId),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is CapabilityCenterLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<CapabilityCenterBloc>().add(
                      CapabilityCenterRefreshRequested(userId),
                    );
              },
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Your Capabilities',
                          style: AppTypography.headlineMedium,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'Enable capabilities to unlock publishing, payments, and fulfillment features.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Publish Capability
                  CapabilityCard(
                    title: 'Publish Stories',
                    description: 'Share your video stories with the community',
                    status: _getCapabilityStatus(
                      state.canPublish,
                      state.reviewState,
                      state.blockers,
                    ),
                    blockers: _getBlockersForCapability(
                      'publish',
                      state.blockers,
                    ),
                    actionLabel:
                        state.canPublish ? 'Enabled' : 'Enable Publishing',
                    onActionPressed: state.canPublish
                        ? null
                        : () => _requestCapability(
                              context,
                              'publish',
                              'capability_center',
                            ),
                  ),

                  // Payment Collection Capability
                  CapabilityCard(
                    title: 'Collect Payments',
                    description:
                        'Accept payments from buyers through secure checkout',
                    status: _getCapabilityStatus(
                      state.canCollectPayments,
                      state.reviewState,
                      state.blockers,
                    ),
                    blockers: _getBlockersForCapability(
                      'collect_payments',
                      state.blockers,
                    ),
                    actionLabel: state.canCollectPayments
                        ? 'Enabled'
                        : 'Enable Payments',
                    onActionPressed: state.canCollectPayments
                        ? null
                        : () => _requestCapability(
                              context,
                              'collectPayments',
                              'capability_center',
                            ),
                  ),

                  // Order Fulfillment Capability
                  CapabilityCard(
                    title: 'Fulfill Orders',
                    description:
                        'Manage order fulfillment and shipping tracking',
                    status: _getCapabilityStatus(
                      state.canFulfillOrders,
                      state.reviewState,
                      state.blockers,
                    ),
                    blockers: _getBlockersForCapability(
                      'fulfill_orders',
                      state.blockers,
                    ),
                    actionLabel: state.canFulfillOrders
                        ? 'Enabled'
                        : 'Enable Fulfillment',
                    onActionPressed: state.canFulfillOrders
                        ? null
                        : () => _requestCapability(
                              context,
                              'fulfillOrders',
                              'capability_center',
                            ),
                  ),

                  // Polling indicator
                  if (state.isPolling) ...[
                    SizedBox(height: AppSpacing.md),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.info,
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'Checking for updates...',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  CapabilityStatus _getCapabilityStatus(
    bool isEnabled,
    String reviewState,
    Map<String, String> blockers,
  ) {
    if (isEnabled) {
      return CapabilityStatus.ready;
    }

    if (reviewState == 'pending' || reviewState == 'manualReview') {
      return CapabilityStatus.inReview;
    }

    if (blockers.isNotEmpty) {
      return CapabilityStatus.blocked;
    }

    return CapabilityStatus.inactive;
  }

  List<String> _getBlockersForCapability(
    String capability,
    Map<String, String> allBlockers,
  ) {
    return allBlockers.entries
        .where((entry) => entry.key.contains(capability))
        .map((entry) => entry.value)
        .toList();
  }

  void _requestCapability(
    BuildContext context,
    String capability,
    String entryPoint,
  ) {
    context.read<CapabilityCenterBloc>().add(
          CapabilityCenterRequestSubmitted(
            userId: userId,
            capability: capability,
            entryPoint: entryPoint,
          ),
        );

    // Start polling for status updates
    context.read<CapabilityCenterBloc>().add(
          CapabilityCenterPollingStarted(userId),
        );
  }
}
