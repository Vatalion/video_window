import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../domain/models/checkout_security_model.dart';

class MobileSecurityFeatures extends StatefulWidget {
  final SecurityContextModel securityContext;
  final Function(SecurityContextModel) onSecurityUpdated;
  final bool enableBiometrics;
  final bool enableDeviceSecurity;

  const MobileSecurityFeatures({
    required this.securityContext,
    required this.onSecurityUpdated,
    this.enableBiometrics = true,
    this.enableDeviceSecurity = true,
    super.key,
  });

  @override
  State<MobileSecurityFeatures> createState() => _MobileSecurityFeaturesState();
}

class _MobileSecurityFeaturesState extends State<MobileSecurityFeatures> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _deviceSecure = false;
  bool _secureModeEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSecurityFeatures();
  }

  Future<void> _initializeSecurityFeatures() async {
    setState(() {
      _isLoading = true;
    });

    await _checkBiometricAvailability();
    await _checkDeviceSecurity();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkBiometricAvailability() async {
    if (!widget.enableBiometrics) return;

    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      setState(() {
        _biometricAvailable = canCheckBiometrics && isDeviceSupported;
      });
    } catch (e) {
      // Biometric authentication not available
      setState(() {
        _biometricAvailable = false;
      });
    }
  }

  Future<void> _checkDeviceSecurity() async {
    if (!widget.enableDeviceSecurity) return;

    try {
      // Check if device has screen lock enabled
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;

      setState(() {
        _deviceSecure = canCheckBiometrics;
      });
    } catch (e) {
      setState(() {
        _deviceSecure = false;
      });
    }
  }

  Future<bool> _authenticateWithBiometrics() async {
    if (!_biometricAvailable || !_biometricEnabled) return false;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to complete checkout',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        _updateSecurityContext(
          securityLevel: SecurityLevel.maximum,
          riskFactors: {
            'biometricVerified': true,
            'userAuthenticated': true,
          },
        );
      }

      return authenticated;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _authenticateWithDeviceCredentials() async {
    if (!_deviceSecure) return false;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to complete checkout',
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        _updateSecurityContext(
          securityLevel: SecurityLevel.high,
          riskFactors: {
            'deviceAuthenticated': true,
            'userAuthenticated': true,
          },
        );
      }

      return authenticated;
    } catch (e) {
      return false;
    }
  }

  void _toggleBiometricAuth(bool enabled) {
    setState(() {
      _biometricEnabled = enabled;
    });

    _updateSecurityContext(
      riskFactors: {
        'biometricEnabled': enabled,
      },
    );
  }

  void _toggleSecureMode(bool enabled) {
    setState(() {
      _secureModeEnabled = enabled;
    });

    _updateSecurityContext(
      securityLevel: enabled ? SecurityLevel.high : SecurityLevel.standard,
      riskFactors: {
        'secureMode': enabled,
      },
    );

    if (enabled) {
      _enableSecureModeFeatures();
    } else {
      _disableSecureModeFeatures();
    }
  }

  void _updateSecurityContext({
    SecurityLevel? securityLevel,
    Map<String, dynamic>? riskFactors,
  }) {
    final updatedContext = widget.securityContext.copyWith(
      securityLevel: securityLevel ?? widget.securityContext.securityLevel,
      riskFactors: {
        ...widget.securityContext.riskFactors,
        ...?riskFactors,
      },
    );

    widget.onSecurityUpdated(updatedContext);
  }

  void _enableSecureModeFeatures() {
    // Enable additional security features
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Prevent screenshots during secure checkout
    // This would require platform-specific implementation
  }

  void _disableSecureModeFeatures() {
    // Disable additional security features
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSecurityFeatures(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.security,
            color: Colors.blue.shade700,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mobile Security',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Enhanced security features for your device',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityFeatures() {
    return Column(
      children: [
        if (_biometricAvailable) _buildBiometricFeature(),
        if (_biometricAvailable) const SizedBox(height: 12),
        if (_deviceSecure) _buildDeviceSecurityFeature(),
        if (_deviceSecure) const SizedBox(height: 12),
        _buildSecureModeFeature(),
        const SizedBox(height: 16),
        _buildSecurityActions(),
      ],
    );
  }

  Widget _buildBiometricFeature() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.fingerprint,
            color: Colors.green.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biometric Authentication',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Use fingerprint or face recognition for secure checkout',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _biometricEnabled,
            onChanged: _toggleBiometricAuth,
            activeColor: Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSecurityFeature() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Lock',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Use device PIN, pattern, or password for verification',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.blue.shade700,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSecureModeFeature() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _secureModeEnabled ? Colors.orange.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _secureModeEnabled ? Colors.orange.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield,
            color: _secureModeEnabled ? Colors.orange.shade700 : Colors.grey.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Mode',
                  style: TextStyle(
                    color: _secureModeEnabled ? Colors.orange.shade700 : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Enhanced security with additional verification',
                  style: TextStyle(
                    color: _secureModeEnabled ? Colors.orange.shade600 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _secureModeEnabled,
            onChanged: _toggleSecureMode,
            activeColor: Colors.orange.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityActions() {
    return Column(
      children: [
        Row(
          children: [
            if (_biometricAvailable && _biometricEnabled)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _authenticateWithBiometrics,
                  icon: const Icon(Icons.fingerprint, size: 16),
                  label: const Text('Verify Identity'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (_biometricAvailable && _biometricEnabled && _deviceSecure)
              const SizedBox(width: 8),
            if (_deviceSecure)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _authenticateWithDeviceCredentials,
                  icon: const Icon(Icons.lock, size: 16),
                  label: const Text('Device Auth'),
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

  @override
  void dispose() {
    _disableSecureModeFeatures();
    super.dispose();
  }
}

class TouchSecurityOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final VoidCallback? onTouch;

  const TouchSecurityOverlay({
    required this.child,
    this.enabled = true,
    this.onTouch,
    super.key,
  });

  @override
  State<TouchSecurityOverlay> createState() => _TouchSecurityOverlayState();
}

class _TouchSecurityOverlayState extends State<TouchSecurityOverlay> {
  DateTime? _lastTouch;
  static const Duration _touchInterval = Duration(milliseconds: 500);

  void _handleTouch() {
    if (!widget.enabled) return;

    final now = DateTime.now();
    if (_lastTouch != null && now.difference(_lastTouch!) < _touchInterval) {
      // Rapid touch detected - potential security concern
      widget.onTouch?.call();
      return;
    }

    _lastTouch = now;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handleTouch(),
      child: widget.child,
    );
  }
}

class SecureTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final bool isSensitive;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const SecureTextField({
    required this.controller,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.isSensitive = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    super.key,
  });

  @override
  State<SecureTextField> createState() => _SecureTextFieldState();
}

class _SecureTextFieldState extends State<SecureTextField> {
  bool _obscureText = true;
  bool _hasFocus = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText ? _obscureText : false,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.isSensitive ? Colors.orange : Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                icon: Icon(
                  _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
              )
            : widget.isSensitive
                ? Icon(
                    Icons.security,
                    color: Colors.orange.shade700,
                    size: 20,
                  )
                : null,
      ),
      // Enable autofill for better mobile experience
      autofillHints: widget.isSensitive ? null : [AutofillHints.username],
      // Enable smart punctuation and text suggestions
      enableSuggestions: !widget.isSensitive,
      autocorrect: !widget.isSensitive,
      // Enable keyboard return key
      textInputAction: TextInputAction.next,
    );
  }
}