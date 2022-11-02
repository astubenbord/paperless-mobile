import 'package:flutter/material.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class RadioSettingsDialog<T> extends StatefulWidget {
  final List<RadioOption<T>> options;
  final T initialValue;
  final Widget? title;
  final Widget? confirmButton;
  final Widget? cancelButton;

  const RadioSettingsDialog({
    super.key,
    required this.options,
    required this.initialValue,
    this.title,
    this.confirmButton,
    this.cancelButton,
  });

  @override
  State<RadioSettingsDialog<T>> createState() => _RadioSettingsDialogState<T>();
}

class _RadioSettingsDialogState<T> extends State<RadioSettingsDialog<T>> {
  late T _groupValue;

  @override
  void initState() {
    super.initState();
    _groupValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actions: [
        widget.confirmButton ??
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(S.of(context).genericActionCancelLabel)),
        widget.confirmButton ??
            TextButton(
                onPressed: () => Navigator.pop(context, _groupValue),
                child: Text(S.of(context).genericActionOkLabel)),
      ],
      title: widget.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.options.map(_buildOptionListTile).toList(),
      ),
    );
  }

  Widget _buildOptionListTile(RadioOption<T> option) => RadioListTile<T>(
        groupValue: _groupValue,
        onChanged: (value) => setState(() => _groupValue = value!),
        value: option.value,
        title: Text(option.label),
      );
}

class RadioOption<T> {
  final T value;
  final String label;

  RadioOption({required this.value, required this.label});
}
