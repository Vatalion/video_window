import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_state.dart';
import '../cubit/dsar_export_polling_cubit.dart';

/// DSAR export status banner with polling
/// AC2: DSAR export generates downloadable package within 24 hours and surfaces status/progress in UI with polling
class DSARExportStatusBanner extends StatelessWidget {
  const DSARExportStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        // Check if there's an active DSAR export
        if (state is DSARExportInProgress) {
          return BlocProvider(
            create: (context) => DSARExportPollingCubit(
              context.read<ProfileBloc>(),
            )..startPolling(state.exportId),
            child: BlocBuilder<DSARExportPollingCubit, DSARExportPollingState>(
              builder: (context, pollingState) {
                return _buildStatusBanner(context, pollingState);
              },
            ),
          );
        }

        if (state is DSARExportCompleted) {
          return _buildCompletedBanner(context, state.downloadUrl);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatusBanner(
    BuildContext context,
    DSARExportPollingState state,
  ) {
    if (state is DSARExportPollingInProgress) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data Export in Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.statusMessage ?? 'Preparing your data export...',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (state is DSARExportPollingCompleted) {
      return _buildCompletedBanner(context, state.downloadUrl);
    }

    if (state is DSARExportPollingError) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Export failed: ${state.errorMessage}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCompletedBanner(BuildContext context, String? downloadUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Export Ready',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your data export is ready for download.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (downloadUrl != null)
            ElevatedButton(
              onPressed: () {
                // TODO: Implement download functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Download functionality coming soon'),
                  ),
                );
              },
              child: const Text('Download'),
            ),
        ],
      ),
    );
  }
}
