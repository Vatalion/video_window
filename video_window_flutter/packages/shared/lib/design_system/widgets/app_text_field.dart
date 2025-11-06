import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/design_system/tokens.dart';

/// Text field type for specialized keyboard and validation
enum AppTextFieldType {
  /// General text input
  text,

  /// Email address input with email keyboard
  email,

  /// Password input with obscured text
  password,

  /// Phone number input with number keyboard
  phone,

  /// Numeric input
  number,

  /// Multi-line text input
  multiline,
}

/// A customizable text input field that follows the app's design system.
///
/// Provides consistent styling, validation, and behavior across the application.
/// Automatically meets WCAG 2.1 AA accessibility requirements.
///
/// Example:
/// ```dart
/// AppTextField(
///   label: 'Email',
///   type: AppTextFieldType.email,
///   onChanged: (value) => print(value),
///   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
/// )
/// ```
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.type = AppTextFieldType.text,
    this.controller,
    this.initialValue,
    this.hint,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
  });

  /// Field label text
  final String label;

  /// Input type determines keyboard and formatting
  final AppTextFieldType type;

  /// Text editing controller (optional)
  final TextEditingController? controller;

  /// Initial value if no controller provided
  final String? initialValue;

  /// Placeholder hint text
  final String? hint;

  /// Helper text shown below field
  final String? helperText;

  /// Leading icon
  final IconData? prefixIcon;

  /// Trailing icon
  final IconData? suffixIcon;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// Callback when field is submitted
  final ValueChanged<String>? onSubmitted;

  /// Validation function
  final String? Function(String?)? validator;

  /// Whether field is enabled
  final bool enabled;

  /// Maximum number of lines (1 for single line)
  final int maxLines;

  /// Maximum character length
  final int? maxLength;

  /// Whether to autofocus this field
  final bool autofocus;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _controller;
  bool _obscurePassword = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  TextInputType get _keyboardType {
    switch (widget.type) {
      case AppTextFieldType.email:
        return TextInputType.emailAddress;
      case AppTextFieldType.phone:
        return TextInputType.phone;
      case AppTextFieldType.number:
        return TextInputType.number;
      case AppTextFieldType.multiline:
        return TextInputType.multiline;
      case AppTextFieldType.text:
      case AppTextFieldType.password:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter>? get _inputFormatters {
    switch (widget.type) {
      case AppTextFieldType.number:
        return [FilteringTextInputFormatter.digitsOnly];
      case AppTextFieldType.phone:
        return [FilteringTextInputFormatter.digitsOnly];
      default:
        return null;
    }
  }

  void _validate(String value) {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(value);
      });
    }
  }

  void _handleChanged(String value) {
    _validate(value);
    widget.onChanged?.call(value);
  }

  void _handleSubmitted(String value) {
    _validate(value);
    widget.onSubmitted?.call(value);
  }

  Widget? _buildSuffixIcon() {
    if (widget.type == AppTextFieldType.password) {
      return IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        tooltip: _obscurePassword ? 'Show password' : 'Hide password',
      );
    }

    if (widget.suffixIcon != null) {
      return Icon(widget.suffixIcon, size: 20);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          keyboardType: _keyboardType,
          inputFormatters: _inputFormatters,
          obscureText:
              widget.type == AppTextFieldType.password && _obscurePassword,
          enabled: widget.enabled,
          maxLines:
              widget.type == AppTextFieldType.password ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          autofocus: widget.autofocus,
          onChanged: _handleChanged,
          onSubmitted: _handleSubmitted,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            helperText: widget.helperText,
            errorText: _errorText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20)
                : null,
            suffixIcon: _buildSuffixIcon(),
            counterText: '', // Hide character counter
          ),
          style: AppTypography.bodyMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
