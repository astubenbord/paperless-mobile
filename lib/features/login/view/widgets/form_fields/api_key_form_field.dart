import 'package:flutter/material.dart';

class ApiKeyFormField extends StatefulWidget {
  final String? initialValue;
  final String label;
  final void Function(String?) onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final FocusNode? focusNode;
  final ValueChanged<String?>? onFieldSubmitted;

  const ApiKeyFormField({
    super.key,
    required this.onChanged,
    required this.label,
    this.validator,
    this.initialValue,
    this.enabled = true,
    this.focusNode,
    this.onFieldSubmitted,
  });

  @override
  State<ApiKeyFormField> createState() => _ApiKeyFormFieldState();
}

class _ApiKeyFormFieldState extends State<ApiKeyFormField> {
  bool _showApiKey = false;
  late final FocusNode _apiKeyFocusNode;

  @override
  void initState() {
    super.initState();
    _apiKeyFocusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _apiKeyFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: widget.enabled,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      initialValue: widget.initialValue,
      focusNode: _apiKeyFocusNode,
      obscureText: !_showApiKey,
      autocorrect: false,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        label: Text(widget.label),
        suffixIcon: IconButton(
          icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() {
            _showApiKey = !_showApiKey;
          }),
        ),
      ),
    );
  }
}
