import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/type/json.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/labels/document_type/model/matching_algorithm.dart';
import 'package:paperless_mobile/features/labels/model/label.model.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class EditLabelPage<T extends Label> extends StatefulWidget {
  final T label;
  final Future<void> Function(T) onSubmit;
  final Future<void> Function(T) onDelete;
  final T Function(JSON) fromJson;
  final List<Widget> additionalFields;

  const EditLabelPage({
    Key? key,
    required this.label,
    required this.fromJson,
    required this.onSubmit,
    required this.onDelete,
    this.additionalFields = const [],
  }) : super(key: key);

  @override
  State<EditLabelPage> createState() => _EditLabelPageState<T>();
}

class _EditLabelPageState<T extends Label> extends State<EditLabelPage<T>> {
  final _formKey = GlobalKey<FormBuilderState>();

  Map<String, String> _errors = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(S.of(context).genericActionEditLabel),
        actions: [
          IconButton(
            onPressed: () => widget.onDelete(widget.label),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(S.of(context).genericActionUpdateLabel),
        onPressed: _onSubmit,
      ),
      body: FormBuilder(
        key: _formKey,
        child: ListView(
          children: [
            FormBuilderTextField(
              name: Label.nameKey,
              decoration: InputDecoration(
                labelText: S.of(context).labelNamePropertyLabel,
                errorText: _errors[Label.nameKey],
              ),
              validator: FormBuilderValidators.required(),
              initialValue: widget.label.name,
              onChanged: (val) => setState(() => _errors = {}),
            ),
            FormBuilderTextField(
              name: Label.matchKey,
              decoration: InputDecoration(
                labelText: S.of(context).labelMatchPropertyLabel,
                errorText: _errors[Label.matchKey],
              ),
              initialValue: widget.label.match,
              onChanged: (val) => setState(() => _errors = {}),
            ),
            FormBuilderDropdown<int?>(
              name: Label.matchingAlgorithmKey,
              initialValue:
                  widget.label.matchingAlgorithm?.value ?? MatchingAlgorithm.allWords.value,
              decoration: InputDecoration(
                labelText: S.of(context).labelMatchingAlgorithmPropertyLabel,
                errorText: _errors[Label.matchingAlgorithmKey],
              ),
              onChanged: (val) => setState(() => _errors = {}),
              items: MatchingAlgorithm.values
                  .map(
                    (algo) => DropdownMenuItem<int?>(
                      child: Text(algo.name), //TODO: INTL
                      value: algo.value,
                    ),
                  )
                  .toList(),
            ),
            FormBuilderCheckbox(
              name: Label.isInsensitiveKey,
              initialValue: widget.label.isInsensitive,
              title: Text(S.of(context).labelIsInsensivitePropertyLabel),
            ),
            ...widget.additionalFields,
          ].padded(),
        ),
      ),
    );
  }

  void _onSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      try {
        final mergedJson = {...widget.label.toJson(), ..._formKey.currentState!.value};
        await widget.onSubmit(widget.fromJson(mergedJson));
        Navigator.pop(context);
      } on ErrorMessage catch (e) {
        showSnackBar(context, translateError(context, e.code));
      } on Map<String, String> catch (errorMessages) {
        setState(() => _errors = errorMessages);
      }
    }
  }
}
