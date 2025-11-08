# Epic 11: Notifications & Activity Surfaces - Technical Specification

**Epic Goal:** Implement real-time push notifications and in-app activity feeds for critical marketplace events (offers, bids, wins, maker alerts) with user preference controls and delivery guarantees.

**Stories:**
- 11-1: Push Notification Infrastructure & Device Registration
- 11-2: In-App Activity Feed & Notification Center
- 11-3: Notification Preferences & Channel Management
- 11-4: Maker-Specific Alerts & SLA Notifications

## Architecture Overview

### Component Mapping
- **Flutter App:** Notification handlers, activity feed UI, preference management
- **Serverpod:** Notification service, event processing, delivery tracking
- **Database:** Notifications, user_preferences, delivery_receipts tables
- **External:** Firebase Cloud Messaging (FCM), APNs (via FCM), SendGrid (email fallback)

### Technology Stack
- **Flutter 3.19.6:** `firebase_messaging` 14.7.9, `flutter_local_notifications` 16.3.0
- **Serverpod 2.9.2:** Notification endpoints, event processors
- **Firebase Cloud Messaging:** Multi-platform push delivery
- **Redis 7.2.4:** Real-time event queue, delivery deduplication
- **PostgreSQL 15:** Notification history, preferences, analytics
- **SendGrid API v3:** Email fallback notifications via `sendgrid-dart` 7.12.0

## Data Models

### Notification Entity
```dart
class Notification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final String? actionUrl;
  final bool isRead;
}

enum NotificationType {
  offer_received,
  bid_placed,
  bid_outbid,
  auction_won,
  auction_ending_soon,
  payment_received,
  shipping_reminder,
  order_delivered,
  maker_approval,
  content_published,
  content_flagged,
  system_announcement
}

enum NotificationPriority {
  critical,  // Immediate delivery, bypass DND
  high,      // Standard push notification
  normal,    // Background delivery
  low        // In-app only
}
```

### User Notification Preferences
```dart
class NotificationPreferences {
  final String userId;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool inAppEnabled;
  final Map<NotificationType, ChannelPreference> typePreferences;
  final QuietHoursConfig? quietHours;
  final DateTime updatedAt;
}

class ChannelPreference {
  final bool push;
  final bool email;
  final bool inApp;
}

class QuietHoursConfig {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<int> daysOfWeek; // 1-7 (Monday-Sunday)
}
```

### Device Registration
```dart
class DeviceToken {
  final String id;
  final String userId;
  final String token;
  final DevicePlatform platform;
  final String? deviceName;
  final bool isActive;
  final DateTime registeredAt;
  final DateTime lastSeenAt;
}

enum DevicePlatform { ios, android, web }
```

## API Endpoints

### Notification Endpoints
```
POST /notifications/register-device
DELETE /notifications/unregister-device
GET /notifications/list
POST /notifications/{id}/mark-read
POST /notifications/mark-all-read
GET /notifications/preferences
PUT /notifications/preferences
POST /notifications/test  // Admin only
```

### Endpoint Specifications

#### Register Device
```dart
// Request
{
  "fcmToken": "device_fcm_token",
  "platform": "ios",
  "deviceName": "iPhone 15 Pro"
}

// Response
{
  "id": "device_uuid",
  "registered": true,
  "expiresAt": "2026-10-30T00:00:00Z"
}
```

#### Get Activity Feed
```dart
// Request
GET /notifications/list?limit=50&offset=0&type=offer_received&unreadOnly=true

// Response
{
  "notifications": [
    {
      "id": "notif_uuid",
      "type": "offer_received",
      "title": "New Offer on 'Handcrafted Vase'",
      "body": "Buyer offered $150",
      "data": {
        "offerId": "offer_uuid",
        "listingId": "listing_uuid",
        "amount": 150
      },
      "createdAt": "2025-10-30T14:30:00Z",
      "isRead": false,
      "actionUrl": "/offers/offer_uuid"
    }
  ],
  "total": 127,
  "unreadCount": 12
}
```

## Implementation Details

### Flutter Notification Module

#### Firebase Messaging Integration
```dart
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permissions (iOS)
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      await _registerDevice(token);

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_registerDevice);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification with custom sound
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'notification_sound.aiff',
        ),
      ),
      payload: jsonEncode(message.data),
    );

    // Update in-app feed
    _notificationBloc.add(NewNotificationReceived(message));
  }
}
```

#### Activity Feed UI
```dart
class ActivityFeedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => context.read<NotificationBloc>()
                .add(MarkAllAsRead()),
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationsLoaded) {
            return ListView.separated(
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return NotificationTile(
                  notification: notification,
                  onTap: () => _handleNotificationTap(context, notification),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final Notification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: notification.isRead ? null : Colors.blue.withOpacity(0.1),
        child: Row(
          children: [
            _buildIcon(notification.type),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: notification.isRead 
                          ? FontWeight.normal 
                          : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Serverpod Notification Service

#### Event Processing & Delivery
```dart
class NotificationService {
  final RedisClient _redis;
  final NotificationRepository _repository;
  final FcmService _fcmService;
  final EmailService _emailService;

  // Core notification dispatch
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    // Check user preferences
    final prefs = await _repository.getUserPreferences(userId);
    if (!_shouldSendNotification(type, prefs)) {
      return;
    }

    // Check quiet hours
    if (_isQuietHours(prefs.quietHours)) {
      if (priority != NotificationPriority.critical) {
        await _queueForLater(userId, type, title, body, data);
        return;
      }
    }

    // Create notification record
    final notification = Notification(
      id: _generateUuid(),
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data ?? {},
      priority: priority,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await _repository.createNotification(notification);

    // Deliver via enabled channels
    final deliveryTasks = <Future>[];

    if (prefs.pushEnabled && prefs.typePreferences[type]?.push == true) {
      deliveryTasks.add(_deliverPush(userId, notification));
    }

    if (prefs.emailEnabled && prefs.typePreferences[type]?.email == true) {
      deliveryTasks.add(_deliverEmail(userId, notification));
    }

    await Future.wait(deliveryTasks);

    // Track delivery
    await _trackDelivery(notification.id, deliveryTasks.length);
  }

  // Push notification delivery
  Future<void> _deliverPush(String userId, Notification notification) async {
    final devices = await _repository.getActiveDevices(userId);

    for (final device in devices) {
      try {
        await _fcmService.send(
          token: device.token,
          notification: FcmNotification(
            title: notification.title,
            body: notification.body,
          ),
          data: {
            ...notification.data,
            'notificationId': notification.id,
            'type': notification.type.name,
          },
          priority: _mapPriority(notification.priority),
        );

        await _repository.recordDelivery(
          notification.id,
          device.id,
          DeliveryChannel.push,
          success: true,
        );
      } catch (e) {
        await _repository.recordDelivery(
          notification.id,
          device.id,
          DeliveryChannel.push,
          success: false,
          error: e.toString(),
        );
      }
    }
  }

  // Batch notifications for efficiency
  Future<void> sendBatchNotifications(
    List<String> userIds,
    NotificationType type,
    String title,
    String body,
    {Map<String, dynamic>? data}
  ) async {
    final chunks = _chunkList(userIds, 100);

    for (final chunk in chunks) {
      await Future.wait(
        chunk.map((userId) => sendNotification(
          userId: userId,
          type: type,
          title: title,
          body: body,
          data: data,
        )),
      );
    }
  }
}
```

#### Notification Templates
```dart
class NotificationTemplates {
  static NotificationContent offerReceived(Offer offer, Listing listing) {
    return NotificationContent(
      type: NotificationType.offer_received,
      title: 'New Offer on "${listing.title}"',
      body: 'Buyer offered \$${offer.amount}',
      data: {
        'offerId': offer.id,
        'listingId': listing.id,
        'amount': offer.amount,
      },
      actionUrl: '/offers/${offer.id}',
      priority: NotificationPriority.high,
    );
  }

  static NotificationContent auctionWon(Auction auction, Listing listing) {
    return NotificationContent(
      type: NotificationType.auction_won,
      title: 'Congratulations! You won the auction',
      body: 'Your bid of \$${auction.winningBid} won "${listing.title}"',
      data: {
        'auctionId': auction.id,
        'listingId': listing.id,
        'amount': auction.winningBid,
      },
      actionUrl: '/checkout/${auction.id}',
      priority: NotificationPriority.critical,
    );
  }

  static NotificationContent auctionEndingSoon(Auction auction, Listing listing) {
    final minutesLeft = auction.endsAt.difference(DateTime.now()).inMinutes;
    return NotificationContent(
      type: NotificationType.auction_ending_soon,
      title: 'Auction ending in $minutesLeft minutes',
      body: 'Current bid: \$${auction.currentBid} for "${listing.title}"',
      data: {
        'auctionId': auction.id,
        'listingId': listing.id,
        'endsAt': auction.endsAt.toIso8601String(),
      },
      actionUrl: '/auctions/${auction.id}',
      priority: NotificationPriority.high,
    );
  }

  static NotificationContent shippingReminder(Order order) {
    final hoursRemaining = order.shippingSlaAt.difference(DateTime.now()).inHours;
    return NotificationContent(
      type: NotificationType.shipping_reminder,
      title: 'Shipping deadline approaching',
      body: 'Please add tracking for order #${order.id.substring(0, 8)} within $hoursRemaining hours',
      data: {
        'orderId': order.id,
        'slaAt': order.shippingSlaAt.toIso8601String(),
      },
      actionUrl: '/maker/orders/${order.id}',
      priority: NotificationPriority.high,
    );
  }
}
```

## Testing Strategy

### Unit Tests
- Notification service delivery logic
- Preference filtering and quiet hours
- Template generation and variable substitution
- Device registration and token management

### Integration Tests
- End-to-end push notification flow
- Multi-device delivery
- Preference persistence and filtering
- Email fallback when push fails

### Performance Tests
- Batch notification delivery (1000+ users)
- Real-time feed loading performance
- Redis queue throughput
- FCM API rate limiting

## Source Tree & File Directives

| Path | Action | Story | Notes |
| --- | --- | --- | --- |
| `video_window_flutter/packages/features/notifications/lib/presentation/pages/activity_feed_page.dart` | create | 11.2 | Main activity feed UI |
| `video_window_flutter/packages/features/notifications/lib/presentation/bloc/notification_bloc.dart` | create | 11.2 | Notification state management |
| `video_window_flutter/packages/features/notifications/lib/services/notification_service.dart` | create | 11.1 | FCM integration and local notifications |
| `video_window_flutter/packages/features/notifications/lib/presentation/pages/notification_preferences_page.dart` | create | 11.3 | User preference UI |
| `video_window_server/lib/src/services/notification_service.dart` | create | 11.1 | Core notification dispatch logic |
| `video_window_server/lib/src/services/fcm_service.dart` | create | 11.1 | Firebase Cloud Messaging client |
| `video_window_server/lib/src/endpoints/notifications/notification_endpoint.dart` | create | 11.1-11.4 | All notification APIs |
| `video_window_server/lib/src/repositories/notification_repository.dart` | create | 11.2 | Database access for notifications |
| `video_window_server/migrations/2025-10-30T01-notifications.sql` | create | 11.1-11.4 | Notifications, devices, preferences tables |

## Success Criteria

- ✅ Push notifications delivered within 5 seconds
- ✅ 99.5% delivery success rate
- ✅ User preferences respected 100% of the time
- ✅ Activity feed loads in <500ms
- ✅ Support for 10,000+ daily notifications
- ✅ Zero notification spam complaints

---

**Version:** v1.0 (Definitive)
**Date:** 2025-10-30
**Dependencies:** Epic 1 (Authentication), Epic 9 (Offers), Epic 10 (Auctions)
**Blocks:** User engagement and retention metrics
