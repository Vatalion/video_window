import 'package:flutter/foundation.dart';

import '../entities/template.dart';

abstract class TemplateRepository {
  /// Get a template by ID
  Future<Template?> getTemplate(String id);

  /// Get all templates
  Future<List<Template>> getAllTemplates();

  /// Get templates by tag
  Future<List<Template>> getTemplatesByTag(String tag);

  /// Create a new template
  Future<Template> createTemplate(Template template);

  /// Update an existing template
  Future<Template> updateTemplate(Template template);

  /// Delete a template
  Future<bool> deleteTemplate(String id);

  /// Apply a template to a workflow
  Future<void> applyTemplateToWorkflow(String templateId, String workflowId);
}