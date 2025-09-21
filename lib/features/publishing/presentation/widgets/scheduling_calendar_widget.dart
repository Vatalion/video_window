import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_window/features/publishing/domain/entities/scheduled_publish.dart';
import 'package:video_window/features/publishing/presentation/bloc/scheduling_bloc.dart';

class SchedulingCalendarWidget extends StatefulWidget {
  final List<ScheduledPublish> scheduledPublishes;
  final Function(ScheduledPublish) onScheduledPublishTap;

  const SchedulingCalendarWidget({
    super.key,
    required this.scheduledPublishes,
    required this.onScheduledPublishTap,
  });

  @override
  State<SchedulingCalendarWidget> createState() => _SchedulingCalendarWidgetState();
}

class _SchedulingCalendarWidgetState extends State<SchedulingCalendarWidget> {
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCalendarHeader(),
        const SizedBox(height: 16),
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
            });
          },
          icon: const Icon(Icons.arrow_left),
        ),
        Text(
          '${_currentDate.year}-${_currentDate.month.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
            });
          },
          icon: const Icon(Icons.arrow_right),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    return Column(
      children: [
        _buildWeekDays(),
        _buildCalendarDays(),
      ],
    );
  }

  Widget _buildWeekDays() {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      children: weekdays
          .map((day) => Expanded(
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(day),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarDays() {
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    
    // Calculate the first day of the calendar grid (Sunday of the week containing the first day of the month)
    final firstDayOfGrid = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));
    
    // Calculate the last day of the calendar grid (Saturday of the week containing the last day of the month)
    final lastDayOfGrid = lastDayOfMonth.add(Duration(days: (6 - lastDayOfMonth.weekday) % 7));
    
    // Generate a list of dates for the calendar grid
    final dates = List<DateTime>.generate(
      lastDayOfGrid.difference(firstDayOfGrid).inDays + 1,
      (index) => firstDayOfGrid.add(Duration(days: index)),
    );
    
    // Group dates by week
    final weeks = <List<DateTime>>[];
    for (int i = 0; i < dates.length; i += 7) {
      weeks.add(dates.sublist(i, i + 7 > dates.length ? dates.length : i + 7));
    }
    
    return Column(
      children: weeks
          .map((week) => Row(
                children: week
                    .map((date) => Expanded(
                          child: _buildCalendarDay(date),
                        ))
                    .toList(),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarDay(DateTime date) {
    // Check if this date has any scheduled publishes
    final scheduledPublishesForDay = widget.scheduledPublishes
        .where((scheduledPublish) =>
            scheduledPublish.scheduledTime.year == date.year &&
            scheduledPublish.scheduledTime.month == date.month &&
            scheduledPublish.scheduledTime.day == date.day)
        .toList();
    
    final isCurrentMonth = date.month == _currentDate.month;
    
    return DragTarget<ScheduledPublish>(
      onAcceptWithDetails: (details) {
        // When a scheduled publish is dropped on this date, update its scheduled time
        final scheduledPublish = details.data;
        final newScheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          scheduledPublish.scheduledTime.hour,
          scheduledPublish.scheduledTime.minute,
          scheduledPublish.scheduledTime.second,
          scheduledPublish.scheduledTime.millisecond,
          scheduledPublish.scheduledTime.microsecond,
        );
        
        // Dispatch move event to bloc
        context.read<SchedulingBloc>().add(MoveScheduledPublish(scheduledPublish, newScheduledTime));
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            // Highlight the drop target when a drag is in progress
            color: candidateData.isNotEmpty 
                ? Colors.blue.withOpacity(0.1) 
                : null,
          ),
          child: InkWell(
            onTap: scheduledPublishesForDay.isNotEmpty
                ? () {
                    // If there's only one scheduled publish, tap it directly
                    if (scheduledPublishesForDay.length == 1) {
                      widget.onScheduledPublishTap(scheduledPublishesForDay.first);
                    }
                    // If there are multiple, we might want to show a bottom sheet or dialog
                    // For simplicity, we'll just tap the first one
                    else if (scheduledPublishesForDay.isNotEmpty) {
                      widget.onScheduledPublishTap(scheduledPublishesForDay.first);
                    }
                  }
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    color: isCurrentMonth ? Colors.black : Colors.grey.withOpacity(0.3),
                    fontWeight: scheduledPublishesForDay.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (scheduledPublishesForDay.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  // Display draggable scheduled publishes
                  ...scheduledPublishesForDay.map((scheduledPublish) => Draggable<ScheduledPublish>(
                    data: scheduledPublish,
                    feedback: Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Publish ${scheduledPublish.id.substring(0, 4)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    childWhenDragging: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )).toList(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}