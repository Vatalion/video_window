import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import '../../../domain/models/two_factor_config_model.dart';
import '../../bloc/two_factor/two_factor_bloc.dart';
import '../../bloc/two_factor/two_factor_event.dart';
import '../../bloc/two_factor/two_factor_state.dart';

class TwoFactorTotpSetupWidget extends StatefulWidget {
  final String userId;
  final String appName;
  final void Function(TwoFactorConfig)? onSetupComplete;

  const TwoFactorTotpSetupWidget({
    super.key,
    required this.userId,
    required this.appName,
    this.onSetupComplete,
  });

  @override
  State<TwoFactorTotpSetupWidget> createState() =>
      _TwoFactorTotpSetupWidgetState();
}

class _TwoFactorTotpSetupWidgetState extends State<TwoFactorTotpSetupWidget> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  String _totpSecret = '';
  String _qrCodeUrl = '';
  bool _showQrCode = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _generateTotpSecret();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generateTotpSecret() async {
    setState(() => _isSubmitting = true);

    final bloc = context.read<TwoFactorBloc>();
    bloc.add(
      TwoFactorTotpSetupInitiated(
        userId: widget.userId,
        totpSecret: '', // This will be generated in the repository
      ),
    );

    // For demo purposes, generate a mock secret
    setState(() {
      _totpSecret = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
      _qrCodeUrl =
          'otpauth://totp/${widget.appName}:${widget.userId}?secret=$_totpSecret&issuer=${widget.appName}&algorithm=SHA1&digits=6&period=30';
      _isSubmitting = false;
    });
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final code = _codeController.text.trim();
    context.read<TwoFactorBloc>().add(
      TwoFactorTotpCodeVerified(
        userId: widget.userId,
        sessionId: 'temp_session_${DateTime.now().millisecondsSinceEpoch}',
        code: code,
      ),
    );

    setState(() => _isSubmitting = false);
  }

  Future<void> _shareSecret() async {
    await Share.share(
      'TOTP Secret: $_totpSecret\n\n'
      'Manual setup:\n'
      '1. Open your authenticator app\n'
      '2. Select "Enter a setup key"\n'
      '3. Enter the secret above\n'
      '4. Set time-based verification\n'
      '5. Use 6-digit codes',
      subject: 'TOTP Setup for ${widget.appName}',
    );
  }

  void _toggleQrCode() {
    setState(() => _showQrCode = !_showQrCode);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TwoFactorBloc, TwoFactorState>(
      listener: (context, state) {
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state.hasSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ),
          );

          if (state.successMessage!.contains('verified successfully') &&
              widget.onSetupComplete != null) {
            widget.onSetupComplete!(state.config!);
          }
        }
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildQrCodeSection(),
                const SizedBox(height: 24),
                _buildManualSetupSection(),
                const SizedBox(height: 32),
                _buildVerificationSection(),
              ],
            ),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.mobile_friendly,
                color: Colors.purple,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authenticator App',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Set up 2FA with an authenticator app for enhanced security',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Recommended authenticator apps:',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildAppChip('Google Authenticator', 'Google'),
            _buildAppChip('Microsoft Authenticator', 'Microsoft'),
            _buildAppChip('Authy', 'Authy'),
            _buildAppChip('LastPass Authenticator', 'LastPass'),
          ],
        ),
      ],
    );
  }

  Widget _buildAppChip(String name, String icon) {
    return Chip(
      label: Text(name),
      avatar: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Text(
          icon[0],
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildQrCodeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scan QR Code',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: _toggleQrCode,
                child: Text(
                  _showQrCode ? 'Show Manual' : 'Show QR',
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_showQrCode) ...[
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _qrCodeUrl.isNotEmpty
                    ? QrImageView(
                        data: _qrCodeUrl,
                        version: QrVersions.auto,
                        size: 180,
                        gapless: false,
                        embeddedImageStyle: QrEmbeddedImageStyle(
                          size: const Size(30, 30),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan this QR code with your authenticator app',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            _buildManualSetup(),
          ],
        ],
      ),
    );
  }

  Widget _buildManualSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manual Setup',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Account Name:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.appName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Secret Key:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _totpSecret,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareSecret,
                icon: const Icon(Icons.share),
                label: const Text('Share Secret'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManualSetupSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Setup Instructions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep('1', 'Open your authenticator app'),
          _buildInstructionStep('2', 'Tap "+" or "Add Account"'),
          _buildInstructionStep(
            '3',
            'Select "Scan QR Code" or "Enter setup key"',
          ),
          _buildInstructionStep('4', 'Follow the on-screen instructions'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String step, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$step. ',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              instruction,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Setup',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code from your authenticator app to verify the setup:',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: '123456',
            prefixIcon: const Icon(Icons.password),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the verification code';
            }
            if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
              return 'Please enter a valid 6-digit code';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Verify and Complete Setup'),
          ),
        ),
      ],
    );
  }
}
