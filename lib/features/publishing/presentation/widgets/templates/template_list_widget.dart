import 'package:flutter/material.dart';

import '../../../domain/entities/template.dart';

class TemplateListWidget extends StatelessWidget {
  final List<Template> templates;
  final Function(Template) onTemplateSelected;
  final Function(Template) onTemplateDeleted;
  final Function() onTemplateCreated;

  const TemplateListWidget({
    super.key,
    required this.templates,
    required this.onTemplateSelected,
    required this.onTemplateDeleted,
    required this.onTemplateCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Publishing Templates',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onTemplateCreated,
            ),
          ],
        ),
        if (templates.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No templates found. Create your first template!'),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _TemplateListItem(
                  template: template,
                  onTap: () => onTemplateSelected(template),
                  onDelete: () => onTemplateDeleted(template),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TemplateListItem extends StatelessWidget {
  final Template template;
  final Function() onTap;
  final Function() onDelete;

  const _TemplateListItem({
    required this.template,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(template.name),
        subtitle: Text(template.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (template.isSystemTemplate)
              const Icon(Icons.lock, size: 16, color: Colors.grey)
            else
              const Icon(Icons.edit, size: 16, color: Colors.grey),
            IconButton(
              icon: const Icon(Icons.delete, size: 16),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}