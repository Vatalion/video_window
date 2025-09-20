import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/shipping_tracking_model.dart';
import '../../domain/models/shipping_rate_model.dart';

/// Widget for tracking shipments
class TrackingWidget extends StatefulWidget {
  final String trackingNumber;
  final String? carrier;
  final String? orderId;
  final ShipmentTrackingModel? initialTrackingData;
  final Function(ShipmentTrackingModel)? onTrackingUpdated;

  const TrackingWidget({
    super.key,
    required this.trackingNumber,
    this.carrier,
    this.orderId,
    this.initialTrackingData,
    this.onTrackingUpdated,
  });

  @override
  State<TrackingWidget> createState() => _TrackingWidgetState();
}

class _TrackingWidgetState extends State<TrackingWidget> {
  ShipmentTrackingModel? _trackingData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _trackingData = widget.initialTrackingData;
    if (_trackingData == null) {
      _loadTrackingData();
    }
  }

  Future<void> _loadTrackingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      final mockTrackingData = _generateMockTrackingData();
      setState(() {
        _trackingData = mockTrackingData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load tracking information: ${e.toString()}';
      });
    }
  }

  ShipmentTrackingModel _generateMockTrackingData() {
    final now = DateTime.now();
    final events = <TrackingEventModel>[];

    // Generate mock events based on tracking number
    final trackingHash = widget.trackingNumber.hashCode.abs();
    final isDelivered = trackingHash % 4 == 0; // 25% chance of being delivered
    final hasExceptions = trackingHash % 10 == 0; // 10% chance of exceptions

    // Label created
    events.add(TrackingEventModel(
      id: 'event-1',
      trackingNumber: widget.trackingNumber,
      status: 'Label Created',
      description: 'Shipping label created',
      timestamp: now.subtract(const Duration(days: 3)),
      location: 'Warehouse',
      details: {'labelId': 'LBL-${widget.trackingNumber}'},
      carrier: widget.carrier ?? 'FedEx',
    ));

    // Picked up
    events.add(TrackingEventModel(
      id: 'event-2',
      trackingNumber: widget.trackingNumber,
      status: 'Picked Up',
      description: 'Package picked up from sender',
      timestamp: now.subtract(const Duration(days: 2)),
      location: 'Sender Location',
      details: {'driver': 'John D.', 'vehicle': 'Van-123'},
      carrier: widget.carrier ?? 'FedEx',
    ));

    // In transit
    events.add(TrackingEventModel(
      id: 'event-3',
      trackingNumber: widget.trackingNumber,
      status: 'In Transit',
      description: 'Package in transit to destination',
      timestamp: now.subtract(const Duration(days: 1)),
      location: 'Distribution Center',
      details: {'facility': 'Main Hub', 'nextStop': 'Local Office'},
      carrier: widget.carrier ?? 'FedEx',
    ));

    if (isDelivered) {
      // Out for delivery
      events.add(TrackingEventModel(
        id: 'event-4',
        trackingNumber: widget.trackingNumber,
        status: 'Out for Delivery',
        description: 'Package out for delivery',
        timestamp: now.subtract(const Duration(hours: 4)),
        location: 'Local Office',
        details: {'driver': 'Mike S.', 'estimatedDelivery': '2-4 PM'},
        carrier: widget.carrier ?? 'FedEx',
      ));

      // Delivered
      events.add(TrackingEventModel(
        id: 'event-5',
        trackingNumber: widget.trackingNumber,
        status: 'Delivered',
        description: 'Package delivered successfully',
        timestamp: now.subtract(const Duration(hours: 1)),
        location: 'Destination Address',
        details: {
          'signedBy': 'Resident',
          'deliveryMethod': 'Front Door',
          'photoProof': 'DEL-PHOTO-123'
        },
        carrier: widget.carrier ?? 'FedEx',
      ));
    } else if (hasExceptions) {
      // Exception
      events.add(TrackingEventModel(
        id: 'event-4',
        trackingNumber: widget.trackingNumber,
        status: 'Exception',
        description: 'Delivery exception - address not found',
        timestamp: now.subtract(const Duration(hours: 2)),
        location: 'Destination Area',
        details: {
          'exceptionType': 'Address Issue',
          'resolutionRequired': 'Contact customer',
          'retryDate': now.add(const Duration(days: 1)).toIso8601String()
        },
        carrier: widget.carrier ?? 'FedEx',
      ));
    } else {
      // In transit
      events.add(TrackingEventModel(
        id: 'event-4',
        trackingNumber: widget.trackingNumber,
        status: 'In Transit',
        description: 'Package arrived at local facility',
        timestamp: now.subtract(const Duration(hours: 6)),
        location: 'Local Facility',
        details: {'facility': 'Downtown Hub', 'nextScan': 'Out for Delivery'},
        carrier: widget.carrier ?? 'FedEx',
      ));
    }

    return ShipmentTrackingModel(
      id: 'tracking-${widget.trackingNumber}',
      trackingNumber: widget.trackingNumber,
      carrier: widget.carrier ?? 'FedEx',
      orderId: widget.orderId ?? 'ORDER-${widget.trackingNumber}',
      status: isDelivered ? 'Delivered' : (hasExceptions ? 'Exception' : 'In Transit'),
      estimatedDeliveryDate: isDelivered
          ? now.subtract(const Duration(hours: 1)).toIso8601String()
          : now.add(const Duration(days: 1)).toIso8601String(),
      actualDeliveryDate: isDelivered
          ? now.subtract(const Duration(hours: 1)).toIso8601String()
          : '',
      origin: 'Sender City, State',
      destination: 'Receiver City, State',
      events: events,
      carrierInfo: {
        'service': 'Ground Shipping',
        'trackingUrl': 'https://www.fedex.com/fedextrack/?trknbr=${widget.trackingNumber}',
        'customerService': '1-800-FEDEX',
      },
      lastUpdated: now,
      isDelivered: isDelivered,
      hasExceptions: hasExceptions,
      isDelayed: !isDelivered && !hasExceptions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          _buildErrorState()
        else if (_trackingData != null)
          _buildTrackingContent()
        else
          const Center(child: Text('No tracking information available')),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tracking: ${widget.trackingNumber}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (widget.carrier != null)
                Text(
                  'Carrier: ${widget.carrier}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (widget.orderId != null)
                Text(
                  'Order: ${widget.orderId}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadTrackingData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Tracking',
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTrackingData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingContent() {
    return Column(
      children: [
        _buildStatusCard(),
        const SizedBox(height: 16),
        _buildProgressIndicator(),
        const SizedBox(height: 16),
        _buildTrackingEvents(),
        const SizedBox(height: 16),
        _buildActions(),
      ],
    );
  }

  Widget _buildStatusCard() {
    final trackingData = _trackingData!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: trackingData.isDelivered
            ? Colors.green.shade50
            : trackingData.hasExceptions
                ? Colors.red.shade50
                : trackingData.isDelayed
                    ? Colors.orange.shade50
                    : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: trackingData.isDelivered
              ? Colors.green
              : trackingData.hasExceptions
                  ? Colors.red
                  : trackingData.isDelayed
                      ? Colors.orange
                      : Colors.blue,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                trackingData.statusDisplay,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                trackingData.latestEvent?.statusIcon ?? '📦',
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            trackingData.statusMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          if (trackingData.estimatedDeliveryDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Estimated Delivery: ${trackingData.formattedEstimatedDelivery}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (trackingData.actualDeliveryDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Delivered: ${trackingData.formattedActualDelivery}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final trackingData = _trackingData!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Delivery Progress',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${trackingData.deliveryProgress}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: trackingData.deliveryProgress / 100,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            trackingData.isDelivered
                ? Colors.green
                : trackingData.hasExceptions
                    ? Colors.red
                    : trackingData.isDelayed
                        ? Colors.orange
                        : Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingEvents() {
    final trackingData = _trackingData!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tracking History',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: trackingData.events.length,
          itemBuilder: (context, index) {
            final event = trackingData.events[index];
            return _buildEventCard(event);
          },
        ),
      ],
    );
  }

  Widget _buildEventCard(TrackingEventModel event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              event.statusIcon,
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
        title: Text(
          event.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${event.location} • ${event.formattedDate} at ${event.formattedTime}'),
        trailing: Text(
          event.carrier,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final trackingData = _trackingData!;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final url = trackingData.trackingUrl;
              if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            },
            child: const Text('View on Carrier Site'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Share tracking information
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tracking link copied to clipboard')),
              );
            },
            child: const Text('Share Tracking'),
          ),
        ),
      ],
    );
  }
}