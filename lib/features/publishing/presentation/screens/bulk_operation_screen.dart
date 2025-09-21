import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/bulk_operation_bloc.dart';
import '../bloc/publishing_workflow_bloc.dart';
import '../../domain/entities/bulk_operation.dart';
import '../../domain/entities/publishing_workflow.dart';
import '../../domain/enums/publishing_status.dart';
import '../../domain/enums/bulk_operation_type.dart';
import '../../domain/enums/bulk_operation_status.dart';

class BulkOperationScreen extends StatefulWidget {
  final List<PublishingWorkflow> workflows;
  final String userId;

  const BulkOperationScreen({
    super.key,
    required this.workflows,
    required this.userId,
  });

  @override
  State<BulkOperationScreen> createState() => _BulkOperationScreenState();
}

class _BulkOperationScreenState extends State<BulkOperationScreen> {
  Set<String> _selectedWorkflowIds = {};
  BulkOperationType _selectedOperationType = BulkOperationType.publish;
  bool _isSelectAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Operations'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Operation type selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<BulkOperationType>(
              value: _selectedOperationType,
              items: const [
                DropdownMenuItem(
                  value: BulkOperationType.publish,
                  child: Text('Publish Content'),
                ),
                DropdownMenuItem(
                  value: BulkOperationType.schedule,
                  child: Text('Schedule Content'),
                ),
                DropdownMenuItem(
                  value: BulkOperationType.archive,
                  child: Text('Archive Content'),
                ),
                DropdownMenuItem(
                  value: BulkOperationType.delete,
                  child: Text('Delete Content'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedOperationType = value;
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Operation Type',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          
          // Select all checkbox
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Checkbox(
                  value: _isSelectAll,
                  onChanged: (value) {
                    setState(() {
                      _isSelectAll = value ?? false;
                      if (_isSelectAll) {
                        _selectedWorkflowIds = Set.from(widget.workflows.map((w) => w.id));
                      } else {
                        _selectedWorkflowIds.clear();
                      }
                    });
                  },
                ),
                Text('Select all (${widget.workflows.length} items)'),
              ],
            ),
          ),
          
          // Selected count
          if (_selectedWorkflowIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('${_selectedWorkflowIds.length} items selected'),
            ),
          
          // Workflow list
          Expanded(
            child: ListView.builder(
              itemCount: widget.workflows.length,
              itemBuilder: (context, index) {
                final workflow = widget.workflows[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text('Content ID: ${workflow.contentId}'),
                    subtitle: Text('Status: ${workflow.currentStatus.label}'),
                    trailing: Checkbox(
                      value: _selectedWorkflowIds.contains(workflow.id),
                      onChanged: (value) {
                        setState(() {
                          if (value ?? false) {
                            _selectedWorkflowIds.add(workflow.id);
                          } else {
                            _selectedWorkflowIds.remove(workflow.id);
                          }
                          _isSelectAll = _selectedWorkflowIds.length == widget.workflows.length;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Execute button
          if (_selectedWorkflowIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _executeBulkOperation,
                child: Text('Execute ${_selectedOperationType.name} on ${_selectedWorkflowIds.length} items'),
              ),
            ),
        ],
      ),
    );
  }

  void _executeBulkOperation() async {
    // Create bulk operation items
    final items = widget.workflows
        .where((workflow) => _selectedWorkflowIds.contains(workflow.id))
        .map((workflow) => BulkOperationItem(
              workflowId: workflow.id,
              status: BulkOperationStatus.pending,
              processedAt: DateTime.now(),
            ))
        .toList();

    // Create bulk operation
    final bulkOperation = BulkOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.userId,
      workflowIds: _selectedWorkflowIds.toList(),
      operationType: _selectedOperationType,
      status: BulkOperationStatus.pending,
      totalItems: _selectedWorkflowIds.length,
      processedItems: 0,
      failedItems: 0,
      createdAt: DateTime.now(),
      items: items,
    );

    // Dispatch event to bloc
    context.read<BulkOperationBloc>().add(CreateBulkOperation(bulkOperation));
    
    // Navigate to bulk operation progress screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BulkOperationProgressScreen(bulkOperationId: bulkOperation.id),
      ),
    );
  }
}

class BulkOperationProgressScreen extends StatelessWidget {
  final String bulkOperationId;

  const BulkOperationProgressScreen({super.key, required this.bulkOperationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Operation Progress'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocBuilder<BulkOperationBloc, BulkOperationState>(
        builder: (context, state) {
          if (state is BulkOperationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BulkOperationsLoaded) {
            // Find the bulk operation we're tracking
            final bulkOperation = state.bulkOperations.firstWhere(
              (op) => op.id == bulkOperationId,
              orElse: () => throw Exception('Bulk operation not found'),
            );