import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/translation/matching_algorithm_localization_mapper.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/core/util/message_helpers.dart';

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

  final SubmitButtonConfig<T> submitButtonConfig;

  /// FromJson method to parse the form field values into a label instance.
  final T Function(Map<String, dynamic> json) fromJsonT;

  /// List of additionally rendered form fields.
  final List<Widget> additionalFields;

  final bool autofocusNameField;
  final GlobalKey<FormBuilderState>? formKey;

  const LabelForm({
    super.key,
    required this.initialValue,
    required this.fromJsonT,
    this.additionalFields = const [],
    required this.submitButtonConfig,
    required this.autofocusNameField,
    this.formKey,
  });

  @override
  State<LabelForm> createState() => _LabelFormState<T>();
}

class _LabelFormState<T extends Label> extends State<LabelForm<T>> {
  late final GlobalKey<FormBuilderState> _formKey;

  late bool _enableMatchFormField;

  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _formKey = widget.formKey ?? GlobalKey<FormBuilderState>();
    var matchingAlgorithm = (widget.initialValue?.matchingAlgorithm ??
        MatchingAlgorithm.defaultValue);
    _enableMatchFormField = matchingAlgorithm != MatchingAlgorithm.auto &&
        matchingAlgorithm != MatchingAlgorithm.none;
  }

  @override
  Widget build(BuildContext context) {
    List<MatchingAlgorithm> selectableMatchingAlgorithmValues =
        getSelectableMatchingAlgorithmValues(
      context.watch<LocalUserAccount>().hasMultiUserSupport,
    );
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "fab_label_form",
        icon: widget.submitButtonConfig.icon,
        label: widget.submitButtonConfig.label,
        onPressed: _onSubmit,
      ),
      body: FormBuilder(
        key: _formKey,
        child: ListView(
          children: [
            FormBuilderTextField(
              autofocus: widget.autofocusNameField,
              name: Label.nameKey,
              decoration: InputDecoration(
                labelText: S.of(context)!.name,
                errorText: _errors[Label.nameKey],
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return S.of(context)!.thisFieldIsRequired;
                }
                return null;
              },
              initialValue: widget.initialValue?.name,
              onChanged: (val) => setState(() => _errors = {}),
            ),
            FormBuilderDropdown<int?>(
              name: Label.matchingAlgorithmKey,
              initialValue: (widget.initialValue?.matchingAlgorithm ??
                      MatchingAlgorithm.defaultValue)
                  .value,
              decoration: InputDecoration(
                labelText: S.of(context)!.matchingAlgorithm,
                errorText: _errors[Label.matchingAlgorithmKey],
              ),
              onChanged: (val) {
                setState(() {
                  _errors = {};
                  _enableMatchFormField = val != MatchingAlgorithm.auto.value &&
                      val != MatchingAlgorithm.none.value;
                });
              },
              items: selectableMatchingAlgorithmValues
                  .map(
                    (algo) => DropdownMenuItem<int?>(
                      value: algo.value,
                      child: Text(
                        translateMatchingAlgorithmDescription(context, algo),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (_enableMatchFormField)
              FormBuilderTextField(
                name: Label.matchKey,
                decoration: InputDecoration(
                  labelText: S.of(context)!.match,
                  errorText: _errors[Label.matchKey],
                ),
                initialValue: widget.initialValue?.match,
                onChanged: (val) => setState(() => _errors = {}),
              ),
            FormBuilderField<bool>(
              name: Label.isInsensitiveKey,
              initialValue: widget.initialValue?.isInsensitive ?? true,
              builder: (field) {
                return CheckboxListTile(
                  value: field.value,
                  title: Text(S.of(context)!.caseIrrelevant),
                  onChanged: (value) => field.didChange(value),
                );
              },
            ),
            ...widget.additionalFields,
          ].padded(),
        ),
      ),
    );
  }

  List<MatchingAlgorithm> getSelectableMatchingAlgorithmValues(
      bool hasMultiUserSupport) {
    var selectableMatchingAlgorithmValues = MatchingAlgorithm.values;
    if (!hasMultiUserSupport) {
      selectableMatchingAlgorithmValues = selectableMatchingAlgorithmValues
          .where((matchingAlgorithm) =>
              matchingAlgorithm != MatchingAlgorithm.none)
          .toList();
    }
    return selectableMatchingAlgorithmValues;
  }

  void _onSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      try {
        final mergedJson = {
          ...widget.initialValue?.toJson() ?? {},
          ..._formKey.currentState!.value
        };
        final parsed = widget.fromJsonT(mergedJson);
        final createdLabel = await widget.submitButtonConfig.onSubmit(parsed);
        if (mounted) context.pop(createdLabel);
      } on PaperlessApiException catch (error, stackTrace) {
        if (mounted) showErrorMessage(context, error, stackTrace);
      } on PaperlessFormValidationException catch (exception) {
        setState(() => _errors = exception.validationMessages);
      }
    }
  }
}
