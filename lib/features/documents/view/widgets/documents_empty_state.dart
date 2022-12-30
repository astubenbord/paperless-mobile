import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/empty_state.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class DocumentsEmptyState extends StatelessWidget {
  final DocumentsState state;
  final VoidCallback onReset;
  const DocumentsEmptyState({
    Key? key,
    required this.state,
    required this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        title: S.of(context).documentsPageEmptyStateOopsText,
        subtitle: S.of(context).documentsPageEmptyStateNothingHereText,
        bottomChild: state.filter != DocumentFilter.initial
            ? TextButton(
                onPressed: onReset,
                child: Text(
                  S.of(context).documentsEmptyStateResetFilterLabel,
                ),
              ).padded()
            : null,
      ),
    );
  }
}
