import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/repositories/profile_repository.dart';

class AccountDataManager extends StatefulWidget {
  final String userId;
  final Function()? onAccountDeleted;

  const AccountDataManager({
    super.key,
    required this.userId,
    this.onAccountDeleted,
  });

  @override
  State<AccountDataManager> createState() => _AccountDataManagerState();
}

class _AccountDataManagerState extends State<AccountDataManager> {
  final ProfileRepository _repository = ProfileRepository();
  bool _isExporting = false;
  bool _isDeleting = false;
  bool _showDeleteConfirmation = false;

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final exportData = await _repository.exportUserData(widget.userId);
      final jsonData = _formatJson(exportData);

      await Share.share(
        jsonData,
        subject: 'My Account Data Export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  String _formatJson(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('Account Data Export');
    buffer.writeln('====================');
    buffer.writeln('');
    buffer.writeln('Export Date: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    data.forEach((key, value) {
      if (value is Map) {
        buffer.writeln('$key:');
        value.forEach((subKey, subValue) {
          buffer.writeln('  $subKey: $subValue');
        });
      } else if (value is List) {
        buffer.writeln('$key:');
        value.forEach((item) {
          buffer.writeln('  - $item');
        });
      } else {
        buffer.writeln('$key: $value');
      }
      buffer.writeln('');
    });

    return buffer.toString();
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final success = await _repository.deleteAccount(widget.userId);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
        }

        widget.onAccountDeleted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _showDeleteConfirmation = false;
        });
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _showDeleteConfirmation = true;
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Data Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Manage your account data and privacy settings',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Export Data Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.download, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Export Your Data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Download a copy of all your account data in JSON format',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isExporting ? null : _exportData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: _isExporting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Exporting...'),
                            ],
                          )
                        : const Text('Export Data'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Delete Account Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Delete Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Permanently delete your account and all associated data',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),

                if (_showDeleteConfirmation) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'This action cannot be undone. Are you absolutely sure?',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showDeleteConfirmation = false;
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isDeleting ? null : _deleteAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: _isDeleting
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Deleting...'),
                                  ],
                                )
                              : const Text('Delete Account'),
                        ),
                      ),
                    ],
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showDeleteDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete Account'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}