import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../domain/entities/publishing_workflow.dart';
import '../../../domain/enums/publishing_status.dart';

class PublishingWorkflowWebSocketService {
  WebSocketChannel? _workflowChannel;
  bool _isConnected = false;
  final String _webSocketUrl = 'wss://api.example.com/publishing-workflow';
  
  // Callback for when workflow updates are received
  Function(PublishingWorkflow)? onWorkflowUpdate;
  
  // Callback for when connection status changes
  Function(bool)? onConnectionStatusChange;

  void connect() {
    try {
      _workflowChannel = WebSocketChannel.connect(
        Uri.parse(_webSocketUrl),
      );

      _isConnected = true;
      onConnectionStatusChange?.call(_isConnected);

      _workflowChannel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'workflow_update') {
              final workflow = _parseWorkflowUpdate(data);
              onWorkflowUpdate?.call(workflow);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing WebSocket message: $e');
            }
          }
        },
        onError: (error) {
          _isConnected = false;
          onConnectionStatusChange?.call(_isConnected);
          if (kDebugMode) {
            print('Publishing workflow WebSocket error: $error');
          }
        },
        onDone: () {
          _isConnected = false;
          onConnectionStatusChange?.call(_isConnected);
          _attemptReconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      onConnectionStatusChange?.call(_isConnected);
      if (kDebugMode) {
        print('Failed to connect publishing workflow WebSocket: $e');
      }
    }
  }

  void disconnect() {
    _workflowChannel?.sink.close();
    _isConnected = false;
    onConnectionStatusChange?.call(_isConnected);
  }

  bool get isConnected => _isConnected;

  PublishingWorkflow _parseWorkflowUpdate(Map<String, dynamic> data) {
    final statusHistory = (data['statusHistory'] as List)
        .map((item) => {
              'fromStatus': PublishingStatus.values.firstWhere(
                (status) => status.name == item['fromStatus'],
                orElse: () => PublishingStatus.draft,
              ),
              'toStatus': PublishingStatus.values.firstWhere(
                (status) => status.name == item['toStatus'],
                orElse: () => PublishingStatus.draft,
              ),
              'timestamp': DateTime.parse(item['timestamp']),
              'userId': item['userId'],
              'notes': item['notes'] ?? '',
            })
        .map((item) => StatusChange(
              fromStatus: item['fromStatus'],
              toStatus: item['toStatus'],
              timestamp: item['timestamp'],
              userId: item['userId'],
              notes: item['notes'],
            ))
        .toList();

    return PublishingWorkflow(
      id: data['id'],
      contentId: data['contentId'],
      currentStatus: PublishingStatus.values.firstWhere(
        (status) => status.name == data['currentStatus'],
        orElse: () => PublishingStatus.draft,
      ),
      statusHistory: statusHistory,
      scheduledPublishTime: data['scheduledPublishTime'] != null
          ? DateTime.parse(data['scheduledPublishTime'])
          : null,
      approvalRequired: data['approvalRequired'] ?? false,
      approvers: List<String>.from(data['approvers'] ?? []),
      isTemplate: data['isTemplate'] ?? false,
      distributionChannels: List<String>.from(data['distributionChannels'] ?? []),
      distributionErrors: Map<String, String>.from(data['distributionErrors'] ?? {}),
    );
  }

  void _attemptReconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connect();
      }
    });
  }
}