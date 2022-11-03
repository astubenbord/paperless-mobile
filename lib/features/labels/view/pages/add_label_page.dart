import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/core/bloc/label_cubit.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/labels/document_type/model/matching_algorithm.dart';
import 'package:paperless_mobile/features/labels/model/label.model.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class AddLabelPage<T extends Label> extends StatefulWidget {
  final String? initialName;
  final String addLabelStr;
  final T Function(Map<String, dynamic> json) fromJson;
  final LabelCubit<T> cubit;
  final List<Widget> additionalFields;

  const AddLabelPage({
    Key? key,
    this.initialName,
    required this.addLabelStr,
    required this.fromJson,
    required this.cubit,
    this.additionalFields = const [],
  }) : super(key: key);

  @override
  State<AddLabelPage> createState() => _AddLabelPageState<T>();
}

class _AddLabelPageState<T extends Label> extends State<AddLabelPage<T>> {
  final _formKey = GlobalKey<FormBuilderState>();
  PaperlessValidationErrors _errors = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.addLabelStr),
      ),
      floatingActionButton: Visibility(
        visible: MediaQuery.of(context).viewInsets.bottom == 0,
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: Text(S.of(context).genericActionCreateLabel),
          onPressed: _onSubmit,
        ),
      ),
      body: FormBuilder(
        key: _formKey,
        child: ListView(
          children: [
            FormBuilderTextField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              name: Label.nameKey,
              decoration: InputDecoration(
                labelText: S.of(context).labelNamePropertyLabel,
                errorText: _errors[Label.nameKey],
              ),
              initialValue: widget.initialName,
              validator: FormBuilderValidators.required(),
              onChanged: (val) => setState(() => _errors = {}),
            ),
            FormBuilderTextField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              name: Label.matchKey,
              decoration: InputDecoration(
                labelText: S.of(context).labelMatchPropertyLabel,
              ),
              onChanged: (val) => setState(() => _errors = {}),
            ),
            FormBuilderDropdown<int?>(
              name: Label.matchingAlgorithmKey,
              initialValue: MatchingAlgorithm.anyWord.value,
              decoration: InputDecoration(
                labelText: S.of(context).labelMatchingAlgorithmPropertyLabel,
                errorText: _errors[Label.matchingAlgorithmKey],
              ),
              onChanged: (val) => setState(() => _errors = {}),
              items: MatchingAlgorithm.values
                  .map((algo) => DropdownMenuItem<int?>(
                      child: Text(algo.name), //TODO: INTL
                      value: algo.value))
                  .toList(),
            ),
            FormBuilderCheckbox(
              name: Label.isInsensitiveKey,
              initialValue: true,
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
        final label = await widget.cubit
            .add(widget.fromJson(_formKey.currentState!.value));
        Navigator.pop(context, label);
      } on ErrorMessage catch (e) {
        showSnackBar(context, translateError(context, e.code));
      } on PaperlessValidationErrors catch (json) {
        setState(() => _errors = json);
      }
    }
  }
}
