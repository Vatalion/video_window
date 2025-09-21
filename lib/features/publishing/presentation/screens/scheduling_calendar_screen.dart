import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_window/features/publishing/presentation/bloc/scheduling_bloc.dart';
import 'package:video_window/features/publishing/presentation/widgets/scheduling_calendar_widget.dart';
import 'package:video_window/features/publishing/domain/entities/scheduled_publish.dart';

class SchedulingCalendarScreen extends StatefulWidget {
  const SchedulingCalendarScreen({super.key});

  @override
  State<SchedulingCalendarScreen> createState() => _SchedulingCalendarScreenState();
}

class _SchedulingCalendarScreenState extends State<SchedulingCalendarScreen> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().subtract(const Duration(days: 15));
    _endDate = DateTime.now().add(const Duration(days: 30));
    
    // Load scheduled publishes for the current date range
    context.read<SchedulingBloc>().add(LoadScheduledPublishes(_startDate, _endDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publishing Calendar'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocBuilder<SchedulingBloc, SchedulingState>(
        builder: (context, state) {
          if (state is SchedulingLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SchedulingLoaded) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SchedulingCalendarWidget(
                  scheduledPublishes: state.scheduledPublishes,
                  onScheduledPublishTap: _onScheduledPublishTap,
                ),
              ),
            );
          } else if (state is SchedulingError) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          }
          
          return const Center(
            child: Text('Loading scheduling calendar...'),
          );
        },
      ),
    );
  }

  void _onScheduledPublishTap(ScheduledPublish scheduledPublish) {
    // Show details about the scheduled publish
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scheduled Publish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Workflow ID: ${scheduledPublish.workflowId}'),
            Text('Scheduled Time: ${scheduledPublish.scheduledTime}'),
            Text('Timezone: ${scheduledPublish.timezone}'),
            if (scheduledPublish.isRecurring) ...[
              const SizedBox(height: 8),
              Text('Recurring: Yes'),
              if (scheduledPublish.recurrencePattern != null) ...[
                Text('Recurrence Type: ${scheduledPublish.recurrencePattern!.type.label}'),
                Text('Interval: ${scheduledPublish.recurrencePattern!.interval}'),
              ],
            ] else
              const Text('Recurring: No'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}