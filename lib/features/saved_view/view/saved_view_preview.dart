import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/document_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/cubit/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/view/widgets/items/document_list_item.dart';
import 'package:paperless_mobile/features/landing/view/widgets/expansion_card.dart';
import 'package:paperless_mobile/features/saved_view_details/cubit/saved_view_preview_cubit.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';
import 'package:provider/provider.dart';

class SavedViewPreview extends StatelessWidget {
  final SavedView savedView;
  final bool expanded;
  const SavedViewPreview({
    super.key,
    required this.savedView,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => SavedViewPreviewCubit(
        context.read(),
        context.read(),
        context.read(),
        view: savedView,
      )..initialize(),
      builder: (context, child) {
        return ExpansionCard(
          initiallyExpanded: expanded,
          title: Text(savedView.name),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BlocBuilder<SavedViewPreviewCubit, SavedViewPreviewState>(
                builder: (context, state) {
                  return switch (state) {
                    LoadedSavedViewPreviewState(documents: var documents) =>
                      Builder(
                        builder: (context) {
                          if (documents.isEmpty) {
                            return Text(S.of(context)!.noDocumentsFound)
                                .padded();
                          } else {
                            return Column(
                              children: [
                                for (final document in documents)
                                  DocumentListItem(
                                    document: document,
                                    isLabelClickable: false,
                                    isSelected: false,
                                    isSelectionActive: false,
                                    onTap: (document) {
                                      DocumentDetailsRoute(
                                        title: document.title,
                                        id: document.id,
                                        thumbnailUrl:
                                            document.buildThumbnailUrl(context),
                                      ).push(context);
                                    },
                                    onSelected: null,
                                  ),
                              ],
                            );
                          }
                        },
                      ),
                    ErrorSavedViewPreviewState() =>
                      Text(S.of(context)!.couldNotLoadSavedViews).padded(16),
                    OfflineSavedViewPreviewState() =>
                      Text(S.of(context)!.youAreCurrentlyOffline).padded(16),
                    _ => const CircularProgressIndicator()
                        .paddedOnly(top: 8, bottom: 24),
                  };
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: Text(S.of(context)!.showAll),
                    onPressed: () {
                      context.read<DocumentsCubit>().updateFilter(
                            filter: savedView.toDocumentFilter(),
                          );
                      DocumentsRoute().go(context);
                    },
                  ).paddedOnly(bottom: 8),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
