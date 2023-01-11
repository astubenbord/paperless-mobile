import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class StoragePathAutofillFormBuilderField extends StatefulWidget {
  final String name;
  final String? initialValue;
  const StoragePathAutofillFormBuilderField({
    super.key,
    required this.name,
    this.initialValue,
  });

  @override
  State<StoragePathAutofillFormBuilderField> createState() =>
      _StoragePathAutofillFormBuilderFieldState();
}

class _StoragePathAutofillFormBuilderFieldState
    extends State<StoragePathAutofillFormBuilderField> {
  late final TextEditingController _textEditingController;

  late bool _showClearIcon;
  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController.fromValue(
      TextEditingValue(text: widget.initialValue ?? ''),
    )..addListener(() {
        setState(() {
          _showClearIcon = _textEditingController.text.isNotEmpty;
        });
      });
    _showClearIcon = widget.initialValue?.isNotEmpty ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<String>(
      name: widget.name,
      initialValue: widget.initialValue ?? '',
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _textEditingController,
            validator: FormBuilderValidators.required(), //TODO: INTL
            decoration: InputDecoration(
                label: Text(S.of(context).documentStoragePathPropertyLabel),
                suffixIcon: _showClearIcon
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _resetfield(field),
                      )
                    : null),
            onChanged: field.didChange,
          ),
          const SizedBox(height: 8.0),
          Text(
            "Select to autofill path variable",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 4.0,
            runSpacing: 4.0,
            children: [
              InputChip(
                label: Text(
                    S.of(context).documentArchiveSerialNumberPropertyLongLabel),
                onPressed: () => _addParameterToInput("{asn}", field),
              ),
              InputChip(
                label: Text(S.of(context).documentCorrespondentPropertyLabel),
                onPressed: () => _addParameterToInput("{correspondent}", field),
              ),
              InputChip(
                label: Text(S.of(context).documentDocumentTypePropertyLabel),
                onPressed: () => _addParameterToInput("{document_type}", field),
              ),
              InputChip(
                label: Text(S.of(context).documentTagsPropertyLabel),
                onPressed: () => _addParameterToInput("{tag_list}", field),
              ),
              InputChip(
                label: Text(S.of(context).documentTitlePropertyLabel),
                onPressed: () => _addParameterToInput("{title}", field),
              ),
              InputChip(
                label: Text(S.of(context).documentCreatedPropertyLabel),
                onPressed: () => _addParameterToInput("{created}", field),
              ),
              InputChip(
                label: Text(S.of(context).documentCreatedPropertyLabel +
                    " (${S.of(context).storagePathParameterYearLabel})"),
                onPressed: () => _addParameterToInput("{created_year}", field),
              ),
              InputChip(
                label: Text(S.of(context).documentCreatedPropertyLabel +
                    " (${S.of(context).storagePathParameterMonthLabel})"),
                onPressed: () => _addParameterToInput("{created_month}", field),
              ),
              InputChip(
                label: Text(S.of(context).documentCreatedPropertyLabel +
                    " (${S.of(context).storagePathParameterDayLabel})"),
                onPressed: () => _addParameterToInput("{created_day}", field),
              ),
              InputChip(
                label: Text(S.of(context).documentCreatedPropertyLabel),
                onPressed: () => _addParameterToInput("{added}", field),
              ),
              InputChip(
                label: Text(S.of(context).documentCreatedPropertyLabel +
                    " (${S.of(context).storagePathParameterYearLabel})"),
                onPressed: () => _addParameterToInput("{added_year}", field),
              ),
              InputChip(
                label: Text(S.of(context).documentCreatedPropertyLabel +
                    " (${S.of(context).storagePathParameterMonthLabel})"),
                onPressed: () => _addParameterToInput("{added_month}", field),
              ),
              InputChip(
                label: Text(S.of(context).documentCreatedPropertyLabel +
                    " (${S.of(context).storagePathParameterDayLabel})"),
                onPressed: () => _addParameterToInput("{added_day}", field),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _addParameterToInput(String param, FormFieldState<String> field) {
    final text = (field.value ?? "") + param;
    field.didChange(text);
    _textEditingController.text = text;
    _textEditingController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textEditingController.text.length));
  }

  void _resetfield(FormFieldState<String> field) {
    field.didChange("");
    _textEditingController.clear();
  }
}
