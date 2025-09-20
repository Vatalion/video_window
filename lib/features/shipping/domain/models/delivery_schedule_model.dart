import 'package:equatable/equatable.dart';

/// Delivery time slot model
class DeliveryTimeSlotModel extends Equatable {
  final String id;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAvailable;
  final int capacity;
  int bookedCount;
  final double priceMultiplier;
  final String type; // 'standard', 'priority', 'evening', 'weekend'
  final Map<String, dynamic> restrictions;

  const DeliveryTimeSlotModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.capacity,
    required this.bookedCount,
    required this.priceMultiplier,
    required this.type,
    required this.restrictions,
  });

  /// Get availability status
  bool get isFullyBooked => bookedCount >= capacity;

  /// Get availability percentage
  double get availabilityPercentage => (capacity - bookedCount) / capacity;

  /// Get formatted time range
  String get formattedTimeRange => '${_formatTime(startTime)} - ${_formatTime(endTime)}';

  /// Get formatted date
  String get formattedDate => '${date.month}/${date.day}/${date.year}';

  /// Get day of week
  String get dayOfWeek => _getDayOfWeek(date.weekday);

  /// Check if this is a weekend slot
  bool get isWeekend => date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  /// Check if this is an evening slot
  bool get isEvening => startTime.hour >= 17;

  /// Calculate slot price
  double calculateSlotPrice(double basePrice) {
    double price = basePrice * priceMultiplier;

    // Add weekend surcharge
    if (isWeekend) {
      price *= 1.25;
    }

    // Add evening surcharge
    if (isEvening) {
      price *= 1.15;
    }

    return price;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'isAvailable': isAvailable,
      'capacity': capacity,
      'bookedCount': bookedCount,
      'priceMultiplier': priceMultiplier,
      'type': type,
      'restrictions': restrictions,
    };
  }

  /// Create from JSON
  factory DeliveryTimeSlotModel.fromJson(Map<String, dynamic> json) {
    final startTimeParts = json['startTime'].toString().split(':');
    final endTimeParts = json['endTime'].toString().split(':');

    return DeliveryTimeSlotModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      startTime: TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      ),
      isAvailable: json['isAvailable'],
      capacity: json['capacity'],
      bookedCount: json['bookedCount'],
      priceMultiplier: json['priceMultiplier'].toDouble(),
      type: json['type'],
      restrictions: Map<String, dynamic>.from(json['restrictions']),
    );
  }

  @override
  List<Object> get props {
    return [
      id,
      date,
      startTime,
      endTime,
      isAvailable,
      capacity,
      bookedCount,
      priceMultiplier,
      type,
    ];
  }
}

/// Delivery schedule model
class DeliveryScheduleModel extends Equatable {
  final String id;
  final String orderId;
  final DeliveryTimeSlotModel timeSlot;
  final String deliveryInstructions;
  final String contactPerson;
  final String contactPhone;
  final bool requiresSignature;
  final bool leaveAtDoor;
  final bool requireAdultSignature;
  final List<String> specialInstructions;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // 'scheduled', 'confirmed', 'in_transit', 'delivered', 'cancelled'

  const DeliveryScheduleModel({
    required this.id,
    required this.orderId,
    required this.timeSlot,
    required this.deliveryInstructions,
    required this.contactPerson,
    required this.contactPhone,
    required this.requiresSignature,
    required this.leaveAtDoor,
    required this.requireAdultSignature,
    required this.specialInstructions,
    required this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  /// Get delivery status
  String get statusDisplay {
    switch (status) {
      case 'scheduled':
        return 'Scheduled';
      case 'confirmed':
        return 'Confirmed';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  /// Get status color
  Color get statusColor {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'confirmed':
        return Colors.green;
      case 'in_transit':
        return Colors.orange;
      case 'delivered':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get formatted delivery date and time
  String get formattedDeliveryDateTime =>
      '${timeSlot.formattedDate} at ${timeSlot.formattedTimeRange}';

  /// Check if delivery can be modified
  bool get canModify {
    return status == 'scheduled' &&
           scheduledAt.isAfter(DateTime.now().add(const Duration(hours: 2)));
  }

  /// Check if delivery can be cancelled
  bool get canCancel {
    return status == 'scheduled' &&
           scheduledAt.isAfter(DateTime.now().add(const Duration(hours: 1)));
  }

  /// Get delivery preparation status
  String get preparationStatus {
    final now = DateTime.now();
    final hoursUntilDelivery = scheduledAt.difference(now).inHours;

    if (hoursUntilDelivery > 24) {
      return 'Preparing for delivery';
    } else if (hoursUntilDelivery > 2) {
      return 'Finalizing delivery';
    } else {
      return 'Ready for delivery';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'timeSlot': timeSlot.toJson(),
      'deliveryInstructions': deliveryInstructions,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'requiresSignature': requiresSignature,
      'leaveAtDoor': leaveAtDoor,
      'requireAdultSignature': requireAdultSignature,
      'specialInstructions': specialInstructions,
      'scheduledAt': scheduledAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
    };
  }

  /// Create from JSON
  factory DeliveryScheduleModel.fromJson(Map<String, dynamic> json) {
    return DeliveryScheduleModel(
      id: json['id'],
      orderId: json['orderId'],
      timeSlot: DeliveryTimeSlotModel.fromJson(json['timeSlot']),
      deliveryInstructions: json['deliveryInstructions'],
      contactPerson: json['contactPerson'],
      contactPhone: json['contactPhone'],
      requiresSignature: json['requiresSignature'],
      leaveAtDoor: json['leaveAtDoor'],
      requireAdultSignature: json['requireAdultSignature'],
      specialInstructions: List<String>.from(json['specialInstructions']),
      scheduledAt: DateTime.parse(json['scheduledAt']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: json['status'],
    );
  }

  @override
  List<Object> get props {
    return [
      id,
      orderId,
      timeSlot,
      deliveryInstructions,
      contactPerson,
      contactPhone,
      requiresSignature,
      leaveAtDoor,
      requireAdultSignature,
      specialInstructions,
      scheduledAt,
      createdAt,
      updatedAt,
      status,
    ];
  }
}