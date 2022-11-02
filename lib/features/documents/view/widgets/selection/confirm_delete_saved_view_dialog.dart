import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/features/documents/bloc/saved_view_cubit.dart';
import 'package:paperless_mobile/features/documents/model/saved_view.model.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

class ConfirmDeleteSavedViewDialog extends StatelessWidget {
  const ConfirmDeleteSavedViewDialog({
    Key? key,
    required this.view,
  }) : super(key: key);

  final SavedView view;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Delete view " + view.name + "?",
        softWrap: true,
      ),
      content: Text("Do you really want to delete this view?"),
      actions: [
        TextButton(
          child: Text(S.of(context).genericActionCancelLabel),
          onPressed: () => Navigator.pop(context, false),
        ),
        TextButton(
          child: Text(
            S.of(context).genericActionDeleteLabel,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
