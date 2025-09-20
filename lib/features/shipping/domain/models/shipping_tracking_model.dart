import 'package:equatable/equatable.dart';

/// Tracking event model
class TrackingEventModel extends Equatable {
  final String id;
  final String trackingNumber;
  final String status;
  final String description;
  final DateTime timestamp;
  final String location;
  final Map<String, dynamic> details;
  final String carrier;

  const TrackingEventModel({
    required this.id,
    required this.trackingNumber,
    required this.status,
    required this.description,
    required this.timestamp,
    required this.location,
    required this.details,
    required this.carrier,
  });

  /// Get status icon
  String get statusIcon {
    switch (status.toLowerCase()) {
      case 'picked_up':
      case 'in_transit':
        return '📦';
      case 'out_for_delivery':
        return '🚚';
      case 'delivered':
        return '✅';
      case 'exception':
        return '⚠️';
      case 'delayed':
        return '⏰';
      default:
        return '📍';
    }
  }

  /// Get status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'picked_up':
        return 'blue';
      case 'in_transit':
        return 'orange';
      case 'out_for_delivery':
        return 'green';
      case 'delivered':
        return 'green';
      case 'exception':
        return 'red';
      case 'delayed':
        return 'orange';
      default:
        return 'grey';
    }
  }

  /// Get formatted date
  String get formattedDate => '${timestamp.month}/${timestamp.day}/${timestamp.year}';

  /// Get formatted time
  String get formattedTime => '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'status': status,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'details': details,
      'carrier': carrier,
    };
  }

  /// Create from JSON
  factory TrackingEventModel.fromJson(Map<String, dynamic> json) {
    return TrackingEventModel(
      id: json['id'],
      trackingNumber: json['trackingNumber'],
      status: json['status'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'],
      details: Map<String, dynamic>.from(json['details']),
      carrier: json['carrier'],
    );
  }

  @override
  List<Object> get props {
    return [
      id,
      trackingNumber,
      status,
      description,
      timestamp,
      location,
      details,
      carrier,
    ];
  }
}

/// Shipment tracking model
class ShipmentTrackingModel extends Equatable {
  final String id;
  final String trackingNumber;
  final String carrier;
  final String orderId;
  final String status;
  final String estimatedDeliveryDate;
  final String actualDeliveryDate;
  final String origin;
  final String destination;
  final List<TrackingEventModel> events;
  final Map<String, dynamic> carrierInfo;
  final DateTime lastUpdated;
  final bool isDelivered;
  final bool hasExceptions;
  final bool isDelayed;

  const ShipmentTrackingModel({
    required this.id,
    required this.trackingNumber,
    required this.carrier,
    required this.orderId,
    required this.status,
    required this.estimatedDeliveryDate,
    required this.actualDeliveryDate,
    required this.origin,
    required this.destination,
    required this.events,
    required this.carrierInfo,
    required this.lastUpdated,
    required this.isDelivered,
    required this.hasExceptions,
    required this.isDelayed,
  });

  /// Get most recent event
  TrackingEventModel? get latestEvent => events.isNotEmpty ? events.first : null;

  /// Get formatted estimated delivery date
  String get formattedEstimatedDelivery {
    if (estimatedDeliveryDate.isEmpty) return 'Not available';
    try {
      final date = DateTime.parse(estimatedDeliveryDate);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return estimatedDeliveryDate;
    }
  }

  /// Get formatted actual delivery date
  String get formattedActualDelivery {
    if (actualDeliveryDate.isEmpty) return 'Not delivered';
    try {
      final date = DateTime.parse(actualDeliveryDate);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return actualDeliveryDate;
    }
  }

  /// Get delivery progress percentage
  int get deliveryProgress {
    if (isDelivered) return 100;
    if (events.isEmpty) return 0;

    final deliveredEvents = events.where((e) =>
      e.status.toLowerCase() == 'out_for_delivery' ||
      e.status.toLowerCase() == 'delivered'
    ).length;

    return ((deliveredEvents / events.length) * 100).toInt();
  }

  /// Get tracking status display
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'label_created':
        return 'Label Created';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'exception':
        return 'Exception';
      case 'delayed':
        return 'Delayed';
      default:
        return status;
    }
  }

  /// Get status message
  String get statusMessage {
    if (isDelivered) return 'Package delivered successfully!';
    if (hasExceptions) return 'There is an issue with your shipment';
    if (isDelayed) return 'Your shipment is delayed';
    if (events.isNotEmpty) return latestEvent?.description ?? 'Tracking information available';
    return 'Tracking information will be available soon';
  }

  /// Get tracking URL
  String get trackingUrl {
    switch (carrier.toLowerCase()) {
      case 'fedex':
        return 'https://www.fedex.com/fedextrack/?trknbr=$trackingNumber';
      case 'ups':
        return 'https://www.ups.com/track?tracknum=$trackingNumber';
      case 'usps':
        return 'https://tools.usps.com/go/TrackConfirmAction?tLabels=$trackingNumber';
      case 'dhl':
        return 'https://www.dhl.com/us-en/home/tracking/tracking-express.html?submit=1&tracking-id=$trackingNumber';
      default:
        return '';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'carrier': carrier,
      'orderId': orderId,
      'status': status,
      'estimatedDeliveryDate': estimatedDeliveryDate,
      'actualDeliveryDate': actualDeliveryDate,
      'origin': origin,
      'destination': destination,
      'events': events.map((e) => e.toJson()).toList(),
      'carrierInfo': carrierInfo,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isDelivered': isDelivered,
      'hasExceptions': hasExceptions,
      'isDelayed': isDelayed,
    };
  }

  /// Create from JSON
  factory ShipmentTrackingModel.fromJson(Map<String, dynamic> json) {
    return ShipmentTrackingModel(
      id: json['id'],
      trackingNumber: json['trackingNumber'],
      carrier: json['carrier'],
      orderId: json['orderId'],
      status: json['status'],
      estimatedDeliveryDate: json['estimatedDeliveryDate'],
      actualDeliveryDate: json['actualDeliveryDate'],
      origin: json['origin'],
      destination: json['destination'],
      events: (json['events'] as List)
          .map((e) => TrackingEventModel.fromJson(e))
          .toList(),
      carrierInfo: Map<String, dynamic>.from(json['carrierInfo']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      isDelivered: json['isDelivered'],
      hasExceptions: json['hasExceptions'],
      isDelayed: json['isDelayed'],
    );
  }

  @override
  List<Object> get props {
    return [
      id,
      trackingNumber,
      carrier,
      orderId,
      status,
      estimatedDeliveryDate,
      actualDeliveryDate,
      origin,
      destination,
      events,
      carrierInfo,
      lastUpdated,
      isDelivered,
      hasExceptions,
      isDelayed,
    ];
  }
}