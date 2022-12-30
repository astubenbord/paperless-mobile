import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

class SubmitButtonConfig<T extends Label> {
  final Widget icon;
  final Widget label;
  final Future<T> Function(T) onSubmit;

  SubmitButtonConfig({
    required this.icon,
    required this.label,
    required this.onSubmit,
  });
}

class LabelForm<T extends Label> extends StatefulWidget {
  final T? initialValue;

  final SubmitButtonConfig submitButtonConfig;

  /// FromJson method to parse the form field values into a label instance.
  final T Function(Map<String, dynamic> json) fromJsonT;

  /// List of additionally rendered form fields.
  final List<Widget> additionalFields;

  const LabelForm({
    Key? key,
    required this.initialValue,
    required this.fromJsonT,
    this.additionalFields = const [],
    required this.submitButtonConfig,
  }) : super(key: key);

  @override
  State<LabelForm> createState() => _LabelFormState<T>();
}

class _LabelFormState<T extends Label> extends State<LabelForm<T>> {
  final _formKey = GlobalKey<FormBuilderState>();

  PaperlessValidationErrors _errors = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton.extended(
        icon: widget.submitButtonConfig.icon,
        label: widget.submitButtonConfig.label,
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
              initialValue: widget.initialValue?.name,
              onChanged: (val) => setState(() => _errors = {}),
            ),
            FormBuilderTextField(
              name: Label.matchKey,
              decoration: InputDecoration(
                labelText: S.of(context).labelMatchPropertyLabel,
                errorText: _errors[Label.matchKey],
              ),
              initialValue: widget.initialValue?.match,
              onChanged: (val) => setState(() => _errors = {}),
            ),
            FormBuilderDropdown<int?>(
              //TODO: Extract to own widget.
              name: Label.matchingAlgorithmKey,
              initialValue: widget.initialValue?.matchingAlgorithm?.value ??
                  MatchingAlgorithm.allWords.value,
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
              initialValue: widget.initialValue?.isInsensitive ?? true,
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
        final mergedJson = {
          ...widget.initialValue?.toJson() ?? {},
          ..._formKey.currentState!.value
        };
        final createdLabel = await widget.submitButtonConfig
            .onSubmit(widget.fromJsonT(mergedJson));
        Navigator.pop(context, createdLabel);
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      } on DioError catch (error) {
        setState(() => _errors = error.error as PaperlessValidationErrors);
      }
    }
  }
}
