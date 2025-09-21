import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_window/features/publishing/presentation/bloc/scheduling_bloc.dart';
import 'package:video_window/features/publishing/domain/entities/scheduled_publish.dart';
import 'package:video_window/features/publishing/domain/enums/recurrence_type.dart';

class SchedulingScreen extends StatefulWidget {
  final String workflowId;

  const SchedulingScreen({super.key, required this.workflowId});

  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _timezone = 'UTC';
  bool _isRecurring = false;
  RecurrenceType _recurrenceType = RecurrenceType.daily;
  int _interval = 1;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedTime = TimeOfDay.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Content'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date and Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(
                  '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('Time'),
              subtitle: Text('${_selectedTime.hour}:${_selectedTime.minute}'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Timezone',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _timezone,
              items: const [
                DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                DropdownMenuItem(value: 'EST', child: Text('EST')),
                DropdownMenuItem(value: 'PST', child: Text('PST')),
                DropdownMenuItem(value: 'GMT', child: Text('GMT')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _timezone = value;
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Select Timezone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Recurring Publish'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                });
              },
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 16),
              const Text(
                'Recurrence Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<RecurrenceType>(
                value: _recurrenceType,
                items: const [
                  DropdownMenuItem(
                      value: RecurrenceType.daily, child: Text('Daily')),
                  DropdownMenuItem(
                      value: RecurrenceType.weekly, child: Text('Weekly')),
                  DropdownMenuItem(
                      value: RecurrenceType.monthly, child: Text('Monthly')),
                  DropdownMenuItem(
                      value: RecurrenceType.yearly, child: Text('Yearly')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _recurrenceType = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Recurrence Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _interval.toString(),
                decoration: const InputDecoration(
                  labelText: 'Interval',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      _interval = int.tryParse(value) ?? 1;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('End Date (Optional)'),
                subtitle: Text(_endDate?.toString() ?? 'No end date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _scheduleContent,
                child: const Text('Schedule Content'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleContent() {
    // Combine date and time
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Create scheduled publish object
    final scheduledPublish = ScheduledPublish(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workflowId: widget.workflowId,
      scheduledTime: scheduledDateTime,
      timezone: _timezone,
      isRecurring: _isRecurring,
      recurrencePattern: _isRecurring
          ? RecurrencePattern(
              type: _recurrenceType,
              interval: _interval,
              endDate: _endDate,
            )
          : null,
    );

    // Dispatch event to bloc
    context.read<SchedulingBloc>().add(CreateScheduledPublish(scheduledPublish));

    // Show success message and close screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Content scheduled successfully')),
    );
    Navigator.of(context).pop();
  }
}