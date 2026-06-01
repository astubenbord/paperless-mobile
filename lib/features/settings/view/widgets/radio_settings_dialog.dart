import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_cancel_button.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_confirm_button.dart';

class RadioSettingsDialog<T> extends StatefulWidget {
  final List<RadioOption<T>> options;
  final T initialValue;
  final String? titleText;
  final String? descriptionText;
  final Widget? footer;
  final Widget? confirmButton;
  final Widget? cancelButton;

  const RadioSettingsDialog({
    super.key,
    required this.options,
    required this.initialValue,
    this.titleText,
    this.confirmButton,
    this.cancelButton,
    this.descriptionText,
    this.footer,
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
        const DialogCancelButton(),
        widget.confirmButton ?? DialogConfirmButton(returnValue: _groupValue),
      ],
      title: widget.titleText != null ? Text(widget.titleText!) : null,
      content: SingleChildScrollView(
        child: RadioGroup(
          groupValue: _groupValue,
          onChanged: (value) {
            if (value != null) {
              setState(() => _groupValue = value);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.descriptionText != null)
                Text(
                  widget.descriptionText!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ...widget.options.map(_buildOptionListTile),
              if (widget.footer != null) widget.footer!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionListTile(RadioOption<T> option) {
    return RadioListTile<T>(value: option.value, title: Text(option.label));
  }
}

class RadioOption<T> {
  final T value;
  final String label;

  RadioOption({required this.value, required this.label});
}
