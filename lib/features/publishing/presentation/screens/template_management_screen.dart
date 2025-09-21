import 'package:flutter/material.dart';

import '../../domain/entities/template.dart';
import '../widgets/templates/template_list_widget.dart';
import '../widgets/templates/template_editor_widget.dart';

class TemplateManagementScreen extends StatefulWidget {
  const TemplateManagementScreen({super.key});

  @override
  State<TemplateManagementScreen> createState() => _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends State<TemplateManagementScreen> {
  // In a real implementation, these would come from a service
  List<Template> _templates = [];
  Template? _selectedTemplate;
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isEditing
            ? _buildEditor()
            : TemplateListWidget(
                templates: _templates,
                onTemplateSelected: _onTemplateSelected,
                onTemplateDeleted: _onTemplateDeleted,
                onTemplateCreated: _onTemplateCreated,
              ),
      ),
    );
  }

  Widget _buildEditor() {
    return TemplateEditorWidget(
      template: _selectedTemplate,
      onSave: _onTemplateSaved,
    );
  }

  void _onTemplateSelected(Template template) {
    setState(() {
      _selectedTemplate = template;
      _isEditing = true;
    });
  }

  void _onTemplateDeleted(Template template) {
    setState(() {
      _templates.remove(template);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template deleted')),
    );
  }

  void _onTemplateCreated() {
    setState(() {
      _selectedTemplate = null;
      _isEditing = true;
    });
  }

  void _onTemplateSaved(Template template) {
    setState(() {
      final index = _templates.indexWhere((t) => t.id == template.id);
      if (index >= 0) {
        _templates[index] = template;
      } else {
        _templates.add(template);
      }
      _isEditing = false;
      _selectedTemplate = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template saved')),
    );
  }
}