import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/delivery_schedule_model.dart';
import '../../domain/models/shipping_rate_model.dart';

/// Widget for scheduling delivery
class DeliveryScheduler extends StatefulWidget {
  final ShippingRateModel selectedShippingRate;
  final String orderId;
  final Function(DeliveryScheduleModel)? onDeliveryScheduled;

  const DeliveryScheduler({
    super.key,
    required this.selectedShippingRate,
    required this.orderId,
    this.onDeliveryScheduled,
  });

  @override
  State<DeliveryScheduler> createState() => _DeliverySchedulerState();
}

class _DeliverySchedulerState extends State<DeliveryScheduler> {
  DeliveryTimeSlotModel? _selectedTimeSlot;
  final _instructionsController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  bool _requiresSignature = false;
  bool _leaveAtDoor = false;
  bool _requireAdultSignature = false;
  List<String> _specialInstructions = [];
  bool _isLoading = false;

  List<DeliveryTimeSlotModel> _availableTimeSlots = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _generateMockTimeSlots();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  void _generateMockTimeSlots() {
    final slots = <DeliveryTimeSlotModel>[];
    final now = DateTime.now();

    // Generate slots for the next 7 days
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));

      // Skip past dates
      if (date.isBefore(now) && i > 0) continue;

      // Morning slots
      slots.add(DeliveryTimeSlotModel(
        id: 'slot-${date.year}-${date.month}-${date.day}-morning',
        date: date,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        isAvailable: true,
        capacity: 10,
        bookedCount: _getRandomBookedCount(),
        priceMultiplier: 1.0,
        type: 'standard',
        restrictions: {},
      ));

      // Afternoon slots
      slots.add(DeliveryTimeSlotModel(
        id: 'slot-${date.year}-${date.month}-${date.day}-afternoon',
        date: date,
        startTime: const TimeOfDay(hour: 12, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        isAvailable: true,
        capacity: 10,
        bookedCount: _getRandomBookedCount(),
        priceMultiplier: 1.0,
        type: 'standard',
        restrictions: {},
      ));

      // Evening slots
      slots.add(DeliveryTimeSlotModel(
        id: 'slot-${date.year}-${date.month}-${date.day}-evening',
        date: date,
        startTime: const TimeOfDay(hour: 17, minute: 0),
        endTime: const TimeOfDay(hour: 21, minute: 0),
        isAvailable: true,
        capacity: 8,
        bookedCount: _getRandomBookedCount(),
        priceMultiplier: 1.15,
        type: 'evening',
        restrictions: {},
      ));
    }

    setState(() {
      _availableTimeSlots = slots;
    });
  }

  int _getRandomBookedCount() {
    return (DateTime.now().millisecondsSinceEpoch % 8).toInt();
  }

  List<DeliveryTimeSlotModel> _getTimeSlotsForDate(DateTime date) {
    return _availableTimeSlots.where((slot) =>
      slot.date.year == date.year &&
      slot.date.month == date.month &&
      slot.date.day == date.day
    ).toList();
  }

  void _selectTimeSlot(DeliveryTimeSlotModel slot) {
    setState(() {
      _selectedTimeSlot = slot;
    });
  }

  void _addSpecialInstruction(String instruction) {
    if (instruction.isNotEmpty && !_specialInstructions.contains(instruction)) {
      setState(() {
        _specialInstructions.add(instruction);
      });
    }
  }

  void _removeSpecialInstruction(String instruction) {
    setState(() {
      _specialInstructions.remove(instruction);
    });
  }

  Future<void> _scheduleDelivery() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery time slot')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      final deliverySchedule = DeliveryScheduleModel(
        id: 'schedule-${DateTime.now().millisecondsSinceEpoch}',
        orderId: widget.orderId,
        timeSlot: _selectedTimeSlot!,
        deliveryInstructions: _instructionsController.text,
        contactPerson: _contactPersonController.text,
        contactPhone: _contactPhoneController.text,
        requiresSignature: _requiresSignature,
        leaveAtDoor: _leaveAtDoor,
        requireAdultSignature: _requireAdultSignature,
        specialInstructions: _specialInstructions,
        scheduledAt: DateTime(
          _selectedTimeSlot!.date.year,
          _selectedTimeSlot!.date.month,
          _selectedTimeSlot!.date.day,
          _selectedTimeSlot!.startTime.hour,
          _selectedTimeSlot!.startTime.minute,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'scheduled',
      );

      widget.onDeliveryScheduled?.call(deliverySchedule);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery scheduled successfully!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule delivery: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Delivery'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildShippingInfo(),
            const SizedBox(height: 24),
            _buildDatePicker(),
            const SizedBox(height: 24),
            _buildTimeSlots(),
            const SizedBox(height: 24),
            _buildDeliveryInstructions(),
            const SizedBox(height: 24),
            _buildContactInfo(),
            const SizedBox(height: 24),
            _buildDeliveryOptions(),
            const SizedBox(height: 24),
            _buildSpecialInstructions(),
            const SizedBox(height: 32),
            _buildScheduleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipping Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Method: ${widget.selectedShippingRate.shippingMethod.name}'),
          Text('Cost: ${widget.selectedShippingRate.formattedTotalCost}'),
          Text('Delivery: ${widget.selectedShippingRate.shippingMethod.deliveryEstimate}'),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Delivery Date',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = _selectedDate.year == date.year &&
                                 _selectedDate.month == date.month &&
                                 _selectedDate.day == date.day;

              final slotsForDate = _getTimeSlotsForDate(date);
              final hasAvailableSlots = slotsForDate.any((slot) => slot.isAvailable);

              return GestureDetector(
                onTap: hasAvailableSlots
                    ? () => setState(() => _selectedDate = date)
                    : null,
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.white,
                    border: Border.all(
                      color: hasAvailableSlots ? Colors.grey : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayOfWeek(date.weekday),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        _getMonthAbbreviation(date.month),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    final timeSlots = _getTimeSlotsForDate(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Time Slots',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (timeSlots.isEmpty)
          const Text('No time slots available for selected date')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: timeSlots.map((slot) => _buildTimeSlotChip(slot)).toList(),
          ),
      ],
    );
  }

  Widget _buildTimeSlotChip(DeliveryTimeSlotModel slot) {
    final isSelected = _selectedTimeSlot?.id == slot.id;

    return GestureDetector(
      onTap: slot.isAvailable ? () => _selectTimeSlot(slot) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : (slot.isAvailable ? Colors.white : Colors.grey.shade200),
          border: Border.all(
            color: isSelected ? Colors.blue : (slot.isAvailable ? Colors.grey.shade300 : Colors.grey.shade400),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              slot.formattedTimeRange,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : (slot.isAvailable ? Colors.black : Colors.grey),
              ),
            ),
            Text(
              '${slot.type} • ${((slot.availabilityPercentage) * 100).toInt()}% available',
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : (slot.isAvailable ? Colors.grey.shade600 : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Instructions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _instructionsController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Special instructions for delivery (e.g., "Leave at front door", "Ring bell")',
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contactPersonController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Contact Person',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contactPhoneController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Contact Phone',
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Options',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Require Signature'),
          value: _requiresSignature,
          onChanged: (value) {
            setState(() {
              _requiresSignature = value ?? false;
              if (_requiresSignature) {
                _leaveAtDoor = false;
              }
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Leave at Door'),
          value: _leaveAtDoor,
          onChanged: (value) {
            setState(() {
              _leaveAtDoor = value ?? false;
              if (_leaveAtDoor) {
                _requiresSignature = false;
                _requireAdultSignature = false;
              }
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Require Adult Signature'),
          value: _requireAdultSignature,
          onChanged: (value) {
            setState(() {
              _requireAdultSignature = value ?? false;
              if (_requireAdultSignature) {
                _requiresSignature = true;
                _leaveAtDoor = false;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildSpecialInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Instructions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            'Fragile Items',
            'Perishable Goods',
            'Heavy Package',
            'Call Before Delivery',
            'Avoid Weekends',
            'Morning Delivery Only',
          ].map((instruction) => FilterChip(
            label: Text(instruction),
            selected: _specialInstructions.contains(instruction),
            onSelected: (selected) {
              if (selected) {
                _addSpecialInstruction(instruction);
              } else {
                _removeSpecialInstruction(instruction);
              }
            },
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _scheduleDelivery,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Schedule Delivery',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  String _getMonthAbbreviation(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }
}