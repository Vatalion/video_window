import 'package:equatable/equatable.dart';

import '../enums/publishing_status.dart';
import 'publishing_workflow.dart';

class Template extends Equatable {
  final String id;
  final String name;
  final String description;
  final PublishingWorkflow workflowStructure;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSystemTemplate;
  final List<String> tags;

  const Template({
    required this.id,
    required this.name,
    required this.description,
    required this.workflowStructure,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isSystemTemplate,
    required this.tags,
  });

  Template copyWith({
    String? id,
    String? name,
    String? description,
    PublishingWorkflow? workflowStructure,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSystemTemplate,
    List<String>? tags,
  }) {
    return Template(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      workflowStructure: workflowStructure ?? this.workflowStructure,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        workflowStructure,
        createdBy,
        createdAt,
        updatedAt,
        isSystemTemplate,
        tags,
      ];
}