import 'package:flutter/foundation.dart';

import '../../domain/entities/template.dart';
import '../../domain/repositories/template_repository.dart';
import '../publishing_workflow_service.dart';

class TemplateService implements TemplateRepository {
  final PublishingWorkflowService _workflowService;
  
  // In-memory storage for templates
  final Map<String, Template> _templates = {};

  TemplateService({required PublishingWorkflowService workflowService})
      : _workflowService = workflowService;

  @override
  Future<Template?> getTemplate(String id) async {
    return _templates[id];
  }

  @override
  Future<List<Template>> getAllTemplates() async {
    return _templates.values.toList();
  }

  @override
  Future<List<Template>> getTemplatesByTag(String tag) async {
    return _templates.values
        .where((template) => template.tags.contains(tag))
        .toList();
  }

  @override
  Future<Template> createTemplate(Template template) async {
    _templates[template.id] = template;
    return template;
  }

  @override
  Future<Template> updateTemplate(Template template) async {
    _templates[template.id] = template;
    return template;
  }

  @override
  Future<bool> deleteTemplate(String id) async {
    return _templates.remove(id) != null;
  }

  @override
  Future<void> applyTemplateToWorkflow(String templateId, String workflowId) async {
    final template = _templates[templateId];
    final workflow = await _workflowService.getWorkflow(workflowId);

    if (template == null) {
      throw Exception('Template not found');
    }

    if (workflow == null) {
      throw Exception('Workflow not found');
    }

    // Apply template to workflow
    // In a real implementation, this would copy the template's workflow structure
    // to the target workflow, potentially overriding existing settings
    await _workflowService.updateWorkflow(workflow.copyWith(
      currentStatus: template.workflowStructure.currentStatus,
      statusHistory: template.workflowStructure.statusHistory,
      approvalSteps: template.workflowStructure.approvalSteps,
      notifications: template.workflowStructure.notifications,
    ));
  }
}