# Epic 13: Shipping & Tracking Management - Technical Specification

**Epic Goal:** Collect shipping addresses, manage tracking updates, enforce SLA timers, and provide status visibility for buyers and makers throughout the fulfillment lifecycle.

**Stories:**
- 13.1: Shipping Address Collection & Validation
- 13.2: Tracking Number Management & Carrier Integration
- 13.3: Shipping SLA Timers & Reminders
- 13.4: Order Status Visibility & Notifications

## Architecture Overview

### Technology Stack
- **Flutter 3.19.6** for address forms and order tracking UI
- **Serverpod 2.9.2** for order management
- **EasyPost API v2** for address validation and carrier integration
- **PostgreSQL 15** for order and shipping data
- **Redis 7.2.4** for SLA timer tracking

## Data Models

### Shipping Address
```dart
class ShippingAddress {
  final String id;
  final String orderId;
  final String recipientName;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? phone;
  final bool isValidated;
  final DateTime createdAt;
}
```

### Tracking Info
```dart
class TrackingInfo {
  final String id;
  final String orderId;
  final String trackingNumber;
  final ShippingCarrier carrier;
  final TrackingStatus status;
  final DateTime shippedAt;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final List<TrackingEvent> events;
}

enum ShippingCarrier { usps, ups, fedex, dhl, other }

enum TrackingStatus {
  pre_transit,
  in_transit,
  out_for_delivery,
  delivered,
  exception,
  returned
}
```

## Shipping Workflow

### Address Validation
```dart
class ShippingService {
  Future<ValidationResult> validateAddress(ShippingAddress address) async {
    final easyPostAddress = await _easyPostClient.verifyAddress(
      street1: address.addressLine1,
      street2: address.addressLine2,
      city: address.city,
      state: address.state,
      zip: address.postalCode,
      country: address.country,
    );
    
    return ValidationResult(
      isValid: easyPostAddress.verifications.delivery.success,
      suggestedAddress: easyPostAddress.verifications.delivery.success
          ? ShippingAddress.fromEasyPost(easyPostAddress)
          : null,
      errors: easyPostAddress.verifications.delivery.errors,
    );
  }
}
```

### Tracking Management
```dart
class TrackingService {
  Future<void> addTracking({
    required String orderId,
    required String trackingNumber,
    required ShippingCarrier carrier,
  }) async {
    // Validate tracking number format
    if (!_isValidTrackingNumber(trackingNumber, carrier)) {
      throw InvalidTrackingNumberException();
    }
    
    // Create tracking record
    final tracking = TrackingInfo(
      id: _generateUuid(),
      orderId: orderId,
      trackingNumber: trackingNumber,
      carrier: carrier,
      status: TrackingStatus.pre_transit,
      shippedAt: DateTime.now(),
    );
    
    await _repository.createTracking(tracking);
    
    // Register webhook with carrier (via EasyPost)
    await _easyPostClient.createTracker(trackingNumber, carrier.code);
    
    // Update order status
    await _orderService.updateStatus(orderId, OrderStatus.shipped);
    
    // Notify buyer
    await _notificationService.sendNotification(
      userId: order.buyerId,
      type: NotificationType.order_shipped,
      title: 'Your order has shipped!',
      body: 'Tracking #$trackingNumber',
    );
  }
  
  Future<void> updateTrackingStatus(String trackingId, TrackingEvent event) async {
    await _repository.addTrackingEvent(trackingId, event);
    
    final tracking = await _repository.getTracking(trackingId);
    
    if (event.status == TrackingStatus.delivered) {
      await _handleDelivery(tracking);
    } else if (event.status == TrackingStatus.exception) {
      await _handleException(tracking, event);
    }
  }
  
  Future<void> _handleDelivery(TrackingInfo tracking) async {
    await _orderService.updateStatus(
      tracking.orderId,
      OrderStatus.delivered,
    );
    
    // Start 7-day auto-complete timer
    await _scheduleAutoComplete(tracking.orderId, days: 7);
    
    // Notify both parties
    await _notificationService.sendDeliveryNotifications(tracking.orderId);
  }
}
```

## SLA Timer Management

### Shipping SLA Enforcement
```dart
class ShippingSLAService {
  static const Duration TRACKING_SLA = Duration(hours: 72);
  static const Duration DELIVERY_TIMEOUT = Duration(days: 14);
  
  Future<void> startShippingSLA(String orderId) async {
    final slaTime = DateTime.now().add(TRACKING_SLA);
    
    await _repository.setShippingSLA(orderId, slaTime);
    
    // Schedule reminder notifications
    await _scheduleReminder(
      orderId,
      when: DateTime.now().add(Duration(hours: 48)),
      message: '24 hours left to add tracking',
    );
    
    await _scheduleReminder(
      orderId,
      when: DateTime.now().add(Duration(hours: 71)),
      message: '1 hour left to add tracking',
    );
    
    // Schedule SLA breach handler
    await _eventBridge.schedule(
      name: 'shipping-sla-$orderId',
      expression: 'at(${slaTime.toIso8601String()})',
      target: 'handle-sla-breach',
      input: {'orderId': orderId},
    );
  }
  
  Future<void> handleSLABreach(String orderId) async {
    final order = await _orderRepository.getOrder(orderId);
    
    if (order.status == OrderStatus.awaiting_shipment) {
      // Auto-cancel and refund
      await _orderService.cancelOrder(
        orderId,
        reason: 'Maker did not ship within 72 hours',
        refund: true,
      );
      
      // Notify both parties
      await _notificationService.sendSLABreachNotifications(orderId);
      
      // Record maker violation
      await _complianceService.recordViolation(
        order.makerId,
        ViolationType.shipping_sla_breach,
      );
    }
  }
}
```

## Order Status Visibility

### Buyer Tracking UI
```dart
class OrderTrackingPage extends StatelessWidget {
  final String orderId;
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoaded) {
          final order = state.order;
          final tracking = state.tracking;
          
          return Column(
            children: [
              OrderStatusTimeline(order: order),
              if (tracking != null) ...[
                TrackingNumberCard(tracking: tracking),
                TrackingEventsTimeline(events: tracking.events),
                EstimatedDeliveryCard(tracking: tracking),
              ],
              ShippingAddressCard(address: order.shippingAddress),
            ],
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
```

## Source Tree & File Directives

| Path | Action | Story | Notes |
| --- | --- | --- | --- |
| `video_window_flutter/packages/features/orders/lib/presentation/pages/shipping_address_page.dart` | create | 13.1 | Address collection form |
| `video_window_flutter/packages/features/orders/lib/presentation/pages/order_tracking_page.dart` | create | 13.4 | Buyer order tracking |
| `video_window_flutter/packages/features/orders/lib/presentation/pages/maker_shipping_page.dart` | create | 13.2 | Maker tracking input |
| `video_window_server/lib/src/services/shipping_service.dart` | create | 13.1-13.2 | Shipping workflow logic |
| `video_window_server/lib/src/services/shipping_sla_service.dart` | create | 13.3 | SLA timer management |
| `video_window_server/lib/src/integrations/easypost_client.dart` | create | 13.1-13.2 | EasyPost API integration |

## Success Criteria

- ✅ Address validation prevents 95%+ shipping errors
- ✅ Tracking added within 72 hours or auto-cancel
- ✅ Real-time tracking updates via webhooks
- ✅ Orders auto-complete 7 days after delivery
- ✅ SLA reminders sent 48h and 1h before deadline
- ✅ 99%+ on-time tracking submission rate

---

**Version:** v1.0 (Definitive)
**Date:** 2025-10-30
**Dependencies:** Epic 12 (Checkout), Epic 11 (Notifications)
**Blocks:** Order fulfillment completion
