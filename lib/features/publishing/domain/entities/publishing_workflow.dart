import 'package:equatable/equatable.dart';

import 'publishing_status.dart';

class PublishingWorkflow extends Equatable {
  const PublishingWorkflow({
    required this.id,
    required this.contentId,
    required this.currentStatus,
    required this.statusHistory,
    this.scheduledPublishTime,
    this.approvalRequired = false,
    this.approvers = const [],
    this.isTemplate = false,
    this.distributionChannels = const [],
    this.distributionErrors = const {},
  });

  final String id;
  final String contentId;
  final PublishingStatus currentStatus;
  final List<StatusChange> statusHistory;
  final DateTime? scheduledPublishTime;
  final bool approvalRequired;
  final List<String> approvers;
  final bool isTemplate;
  final List<String> distributionChannels;
  final Map<String, String> distributionErrors;

  PublishingWorkflow copyWith({
    String? id,
    String? contentId,
    PublishingStatus? currentStatus,
    List<StatusChange>? statusHistory,
    DateTime? scheduledPublishTime,
    bool? approvalRequired,
    List<String>? approvers,
    bool? isTemplate,
    List<String>? distributionChannels,
    Map<String, String>? distributionErrors,
  }) {
    return PublishingWorkflow(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      currentStatus: currentStatus ?? this.currentStatus,
      statusHistory: statusHistory ?? this.statusHistory,
      scheduledPublishTime: scheduledPublishTime ?? this.scheduledPublishTime,
      approvalRequired: approvalRequired ?? this.approvalRequired,
      approvers: approvers ?? this.approvers,
      isTemplate: isTemplate ?? this.isTemplate,
      distributionChannels: distributionChannels ?? this.distributionChannels,
      distributionErrors: distributionErrors ?? this.distributionErrors,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contentId,
        currentStatus,
        statusHistory,
        scheduledPublishTime,
        approvalRequired,
        approvers,
        isTemplate,
        distributionChannels,
        distributionErrors,
      ];
}