import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/enums/publishing_status.dart';
import '../../domain/entities/publishing_workflow.dart';
import '../../data/services/websocket/publishing_workflow_websocket_service.dart';
import '../bloc/publishing_workflow_bloc.dart';
import '../widgets/workflow_status_card.dart';
import '../widgets/content_filter_widget.dart';
import '../widgets/workflow_pipeline_visualization.dart';

class PublishingDashboardScreen extends StatefulWidget {
  const PublishingDashboardScreen({super.key});

  @override
  State<PublishingDashboardScreen> createState() => _PublishingDashboardScreenState();
}

class _PublishingDashboardScreenState extends State<PublishingDashboardScreen> {
  PublishingStatus _selectedStatus = PublishingStatus.draft;
  String _searchQuery = '';
  late PublishingWorkflowWebSocketService _webSocketService;
  List<PublishingWorkflow> _filteredWorkflows = [];

  @override
  void initState() {
    super.initState();
    _webSocketService = PublishingWorkflowWebSocketService();
    _initWebSocket();
  }

  void _initWebSocket() {
    _webSocketService.onWorkflowUpdate = (workflow) {
      // Update the specific workflow in the list
      setState(() {
        final index = _filteredWorkflows.indexWhere((w) => w.id == workflow.id);
        if (index >= 0) {
          _filteredWorkflows[index] = workflow;
        } else {
          // Add new workflow if it matches the current filter
          if (_selectedStatus == workflow.currentStatus) {
            _filteredWorkflows.add(workflow);
          }
        }
      });
    };

    _webSocketService.onConnectionStatusChange = (isConnected) {
      if (isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to real-time updates'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disconnected from real-time updates'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    };

    _webSocketService.connect();
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }

  void _filterWorkflows(List<PublishingWorkflow> workflows) {
    setState(() {
      _filteredWorkflows = workflows.where((workflow) {
        // Filter by status
        if (workflow.currentStatus != _selectedStatus) {
          return false;
        }
        
        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          return workflow.contentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 workflow.id.toLowerCase().contains(_searchQuery.toLowerCase());
        }
        
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publishing Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportStatusReport(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ContentFilterWidget(
              selectedStatus: _selectedStatus,
              onStatusChanged: (status) {
                setState(() {
                  _selectedStatus = status;
                });
                context.read<PublishingWorkflowBloc>().add(
                      LoadWorkflowsByStatus(status),
                    );
              },
              searchQuery: _searchQuery,
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
                // Re-filter the workflows when search query changes
                if (_filteredWorkflows.isNotEmpty) {
                  _filterWorkflows(_filteredWorkflows);
                }
              },
            ),
          ),
          
          // Workflow list
          Expanded(
            child: BlocBuilder<PublishingWorkflowBloc, PublishingWorkflowState>(
              builder: (context, state) {
                if (state is PublishingWorkflowLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is PublishingWorkflowsLoaded) {
                  // Filter workflows based on current status and search query
                  _filterWorkflows(state.workflows);
                  
                  if (_filteredWorkflows.isEmpty) {
                    return const Center(
                      child: Text('No content found for the selected status'),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: _filteredWorkflows.length,
                    itemBuilder: (context, index) {
                      final workflow = _filteredWorkflows[index];
                      return Column(
                        children: [
                          WorkflowStatusCard(
                            workflow: workflow,
                            onTap: () {
                              // Navigate to workflow details screen
                              // This would be implemented in a real app
                            },
                          ),
                          WorkflowPipelineVisualization(
                            workflow: workflow,
                            onStageTap: (stage) {
                              // Handle stage tap
                              // This would be implemented in a real app
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else if (state is PublishingWorkflowUpdated) {
                  // Handle real-time workflow updates
                  // In a real implementation, we would update the specific workflow in the list
                  return _buildWorkflowList(context);
                } else if (state is PublishingWorkflowError) {
                  return Center(
                    child: Text('Error: ${state.message}'),
                  );
                }
                
                // Load initial data
                context.read<PublishingWorkflowBloc>().add(
                      LoadWorkflowsByStatus(_selectedStatus),
                    );
                
                return const Center(
                  child: Text('Loading publishing workflows...'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowList(BuildContext context) {
    return BlocBuilder<PublishingWorkflowBloc, PublishingWorkflowState>(
      builder: (context, state) {
        if (state is PublishingWorkflowsLoaded) {
          _filterWorkflows(state.workflows);
          
          return ListView.builder(
            itemCount: _filteredWorkflows.length,
            itemBuilder: (context, index) {
              final workflow = _filteredWorkflows[index];
              return Column(
                children: [
                  WorkflowStatusCard(
                    workflow: workflow,
                    onTap: () {
                      // Navigate to workflow details screen
                      // This would be implemented in a real app
                    },
                  ),
                  WorkflowPipelineVisualization(
                    workflow: workflow,
                    onStageTap: (stage) {
                      // Handle stage tap
                      // This would be implemented in a real app
                    },
                  ),
                ],
              );
            },
          );
        } else {
          return const Center(child: Text('No workflows available'));
        }
      },
    );
  }

  void _exportStatusReport(BuildContext context) async {
    try {
      // Get the current filtered workflows
      final workflows = _filteredWorkflows;
      
      // Create CSV data
      final csvData = [
        ['Content ID', 'Workflow ID', 'Status', 'Created At', 'Scheduled Time', 'Approval Required'],
        ...workflows.map((workflow) => [
              workflow.contentId,
              workflow.id,
              workflow.currentStatus.label,
              workflow.statusHistory.first.timestamp.toString(),
              workflow.scheduledPublishTime?.toString() ?? 'Not scheduled',
              workflow.approvalRequired.toString(),
            ])
      ];

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(csvData);

      // Get directory for saving files
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/publishing_status_report.csv';

      // Write CSV to file
      final file = File(filePath);
      await file.writeAsString(csvString);

      // Show success message with file path
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status report exported to: $filePath'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export status report: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}