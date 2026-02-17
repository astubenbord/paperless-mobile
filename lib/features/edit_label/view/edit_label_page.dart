import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_cancel_button.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_confirm_button.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/pop_with_unsaved_changes.dart';
import 'package:paperless_mobile/features/edit_label/view/label_form.dart';
import 'package:paperless_mobile/features/labels/cubit/label_cubit.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/core/util/message_helpers.dart';

class EditLabelPage<T extends Label> extends StatelessWidget {
  final T label;
  final T Function(Map<String, dynamic> json) fromJsonT;
  final List<Widget> additionalFields;
  final Future<T> Function(BuildContext context, T label) onSubmit;
  final Future<void> Function(BuildContext context, T label) onDelete;
  final bool canDelete;

  const EditLabelPage({
    super.key,
    required this.label,
    required this.fromJsonT,
    this.additionalFields = const [],
    required this.onSubmit,
    required this.onDelete,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LabelCubit(
        context.read<LabelRepository>(),
      ),
      child: EditLabelForm(
        label: label,
        additionalFields: additionalFields,
        fromJsonT: fromJsonT,
        onSubmit: onSubmit,
        onDelete: onDelete,
        canDelete: canDelete,
      ),
    );
  }
}

class EditLabelForm<T extends Label> extends StatelessWidget {
  final T label;
  final T Function(Map<String, dynamic> json) fromJsonT;
  final List<Widget> additionalFields;
  final Future<T> Function(BuildContext context, T label) onSubmit;
  final Future<void> Function(BuildContext context, T label) onDelete;
  final bool canDelete;
  final _formKey = GlobalKey<FormBuilderState>();

  EditLabelForm({
    super.key,
    required this.label,
    required this.fromJsonT,
    required this.additionalFields,
    required this.onSubmit,
    required this.onDelete,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopWithUnsavedChanges(
      hasChangesPredicate: () {
        return _formKey.currentState?.isDirty ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context)!.edit),
          actions: [
            IconButton(
              onPressed: canDelete ? () => _onDelete(context) : null,
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
        body: LabelForm<T>(
          formKey: _formKey,
          autofocusNameField: false,
          initialValue: label,
          fromJsonT: fromJsonT,
          submitButtonConfig: SubmitButtonConfig<T>(
            icon: const Icon(Icons.save),
            label: Text(S.of(context)!.saveChanges),
            onSubmit: (label) => onSubmit(context, label),
          ),
          additionalFields: additionalFields,
        ),
      ),
    );
  }

  void _onDelete(BuildContext context) async {
    if ((label.documentCount ?? 0) > 0) {
      final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(S.of(context)!.confirmDeletion),
              content: Text(
                S.of(context)!.deleteLabelWarningText,
              ),
              actions: [
                const DialogCancelButton(),
                DialogConfirmButton(
                  label: S.of(context)!.delete,
                  style: DialogConfirmButtonStyle.danger,
                ),
              ],
            ),
          ) ??
          false;
      if (shouldDelete) {
        try {
          if (context.mounted) onDelete(context, label);
        } on PaperlessApiException catch (error) {
          if (context.mounted) {
            showErrorMessage(context, error);
          }
        } catch (error, stackTrace) {
          log("An error occurred!", error: error, stackTrace: stackTrace);
        }
        if (context.mounted) {
          context.pop();
        }
      }
    } else {
      onDelete(context, label);
      context.pop();
    }
  }
}
