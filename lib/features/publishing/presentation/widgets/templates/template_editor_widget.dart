import 'package:flutter/material.dart';

import '../../../domain/entities/template.dart';
import '../../../domain/entities/publishing_workflow.dart';
import '../../../domain/enums/publishing_status.dart';
import '../../screens/scheduling_screen.dart';

class TemplateEditorWidget extends StatefulWidget {
  final Template? template;
  final Function(Template) onSave;

  const TemplateEditorWidget({
    super.key,
    this.template,
    required this.onSave,
  });

  @override
  State<TemplateEditorWidget> createState() => _TemplateEditorWidgetState();
}

class _TemplateEditorWidgetState extends State<TemplateEditorWidget> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late bool _isSystemTemplate;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _descriptionController = TextEditingController(text: widget.template?.description ?? '');
    _isSystemTemplate = widget.template?.isSystemTemplate ?? false;
    _tags = widget.template?.tags ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Template Name',
            hintText: 'Enter template name',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Enter template description',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _isSystemTemplate,
              onChanged: (value) {
                setState(() {
                  _isSystemTemplate = value ?? false;
                });
              },
            ),
            const Text('System Template'),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _tags
              .map((tag) => Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _saveTemplate,
          child: Text(widget.template == null ? 'Create Template' : 'Update Template'),
        ),
      ],
    );
  }

  void _saveTemplate() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template name cannot be empty')),
      );
      return;
    }

    // Create a default workflow structure for the template
    final workflowStructure = PublishingWorkflow(
      id: 'workflow_${DateTime.now().millisecondsSinceEpoch}',
      contentId: 'template_content',
      currentStatus: PublishingStatus.draft,
      statusHistory: [],
      approvalRequired: false,
      approvers: [],
      isTemplate: true,
    );

    final template = Template(
      id: widget.template?.id ?? 'template_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      workflowStructure: workflowStructure,
      createdAt: widget.template?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isSystemTemplate: _isSystemTemplate,
      tags: _tags,
    );

    widget.onSave(template);
  }
}