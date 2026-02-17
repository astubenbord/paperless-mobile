import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/paging/cubit/paged_documents_state.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class DocumentsEmptyState extends StatelessWidget {
  final DocumentPagingState state;
  final VoidCallback? onReset;

  const DocumentsEmptyState({
    super.key,
    required this.state,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            S.of(context)!.noDocumentsFound,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (state.filter != DocumentFilter.initial && onReset != null)
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onReset!();
              },
              child: Text(
                S.of(context)!.resetFilter,
              ),
            ).padded(),
        ],
      ).padded(24),
    );
  }
}
