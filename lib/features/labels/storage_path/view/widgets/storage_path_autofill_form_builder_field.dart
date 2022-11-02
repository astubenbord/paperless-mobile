import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/features/labels/storage_path/model/storage_path.model.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

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

class _StoragePathAutofillFormBuilderFieldState extends State<StoragePathAutofillFormBuilderField> {
  late final TextEditingController _textEditingController;

  late String _exampleOutput;
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
    _exampleOutput = _buildExampleOutput(widget.initialValue ?? '');
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
            style: Theme.of(context).textTheme.caption,
          ),
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 8.0,
            children: [
              InputChip(
                label: Text(S.of(context).documentArchiveSerialNumberPropertyLongLabel),
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
  }

  String _buildExampleOutput(String input) {
    return input
        .replaceAll("{asn}", "1234")
        .replaceAll("{correspondent}", "My Bank")
        .replaceAll("{document_type}", "Invoice")
        .replaceAll("{tag_list}", "TODO,University,Work")
        .replaceAll("{created}", "2020-02-10")
        .replaceAll("{created_year}", "2020")
        .replaceAll("{created_month}", "02")
        .replaceAll("{created_day}", "10")
        .replaceAll("{added}", "2029-12-24")
        .replaceAll("{added_year}", "2029")
        .replaceAll("{added_month}", "12")
        .replaceAll("{added_day}", "24");
  }

  void _resetfield(FormFieldState<String> field) {
    field.didChange("");
    _textEditingController.clear();
  }
}
