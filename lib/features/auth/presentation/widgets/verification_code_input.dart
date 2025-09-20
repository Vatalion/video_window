import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VerificationCodeInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCodeComplete;
  final ValueChanged<String>? onCodeChanged;
  final bool isError;
  final String? errorMessage;

  const VerificationCodeInput({
    super.key,
    this.length = 6,
    required this.onCodeComplete,
    this.onCodeChanged,
    this.isError = false,
    this.errorMessage,
  });

  @override
  State<VerificationCodeInput> createState() => _VerificationCodeInputState();
}

class _VerificationCodeInputState extends State<VerificationCodeInput> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  String _currentCode = '';

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.length; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value[value.length - 1];
    }

    final newCode = _controllers.map((c) => c.text).join();
    setState(() => _currentCode = newCode);

    widget.onCodeChanged?.call(newCode);

    if (newCode.length == widget.length) {
      widget.onCodeComplete(newCode);
    }

    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (index) {
            return SizedBox(
              width: 50,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                onChanged: (value) => _onChanged(index, value),
                onSubmitted: (_) {
                  if (_currentCode.length == widget.length) {
                    widget.onCodeComplete(_currentCode);
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: widget.isError ? Colors.red : Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: widget.isError ? Colors.red : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: widget.isError ? Colors.red : Colors.blue,
                    ),
                  ),
                  counterText: '',
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ),
        if (widget.isError && widget.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              widget.errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
      ],
    );
  }
}
