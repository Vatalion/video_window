import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_window/features/auth/presentation/bloc/mfa_bloc.dart';
import 'package:video_window/features/auth/presentation/bloc/mfa_event.dart';
import 'package:video_window/features/auth/presentation/bloc/mfa_state.dart';

class MfaBackupCodesWidget extends StatefulWidget {
  final String userId;
  final MfaBloc mfaBloc;

  const MfaBackupCodesWidget({
    super.key,
    required this.userId,
    required this.mfaBloc,
  });

  @override
  State<MfaBackupCodesWidget> createState() => _MfaBackupCodesWidgetState();
}

class _MfaBackupCodesWidgetState extends State<MfaBackupCodesWidget> {
  List<String>? _backupCodes;
  List<String>? _remainingCodes;
  bool _isGenerating = false;
  bool _showExisting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingCodes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Codes'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: BlocListener<MfaBloc, MfaState>(
        listener: (context, state) {
          if (state is MfaBackupCodesGeneratedState) {
            setState(() {
              _backupCodes = state.codes;
              _isGenerating = false;
            });
          } else if (state is MfaRemainingBackupCodesLoadedState) {
            setState(() {
              _remainingCodes = state.codes;
            });
          } else if (state is MfaErrorState) {
            setState(() => _isGenerating = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              if (_showExisting && _remainingCodes != null) ...[
                _buildExistingCodes(),
                const SizedBox(height: 32),
              ],
              if (_backupCodes != null) ...[
                _buildGeneratedCodes(),
                const SizedBox(height: 32),
              ],
              _buildInstructions(),
              const SizedBox(height: 32),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.key, color: Colors.blue, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup Codes',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Use these codes to access your account if you lose your MFA device',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_remainingCodes != null && _remainingCodes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have ${_remainingCodes!.length} backup codes remaining',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.green[700],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _showExisting = !_showExisting),
                  child: Text(_showExisting ? 'Hide' : 'Show'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExistingCodes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Remaining Backup Codes',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _remainingCodes!
                .map(
                  (code) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      code,
                      style: GoogleFonts.monospace(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratedCodes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your New Backup Codes',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.yellow[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.yellow[200]!),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _backupCodes!
                    .map(
                      (code) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          code,
                          style: GoogleFonts.monospace(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'These codes are only shown once. Save them securely before closing this dialog!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Important Instructions',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...[
          {
            'icon': Icons.save,
            'color': Colors.blue,
            'title': 'Save Securely',
            'description':
                'Store these codes in a secure location like a password manager or safe.',
          },
          {
            'icon': Icons.print,
            'color': Colors.green,
            'title': 'Print or Write Down',
            'description':
                'Consider printing or writing down the codes and storing them offline.',
          },
          {
            'icon': Icons.security,
            'color': Colors.orange,
            'title': 'Don\'t Share',
            'description':
                'Never share your backup codes with anyone. They provide full access to your account.',
          },
          {
            'icon': Icons.refresh,
            'color': Colors.purple,
            'title': 'Single Use',
            'description':
                'Each backup code can only be used once. Generate new codes after using them.',
          },
        ].map(
          (instruction) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: instruction.color[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    instruction['icon'] as IconData,
                    color: instruction.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instruction['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        instruction['description'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        if (_backupCodes == null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateNewCodes,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Generating...'),
                      ],
                    )
                  : const Text('Generate New Backup Codes'),
            ),
          ),
        if (_backupCodes != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _backupCodes = null;
                });
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('I\'ve Saved My Codes'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  void _loadExistingCodes() {
    widget.mfaBloc.add(MfaGetRemainingBackupCodesEvent(userId: widget.userId));
  }

  void _generateNewCodes() {
    setState(() => _isGenerating = true);
    widget.mfaBloc.add(MfaGenerateBackupCodesEvent(userId: widget.userId));
  }
}
