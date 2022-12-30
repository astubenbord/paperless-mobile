import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/provider/label_repositories_provider.dart';
import 'package:paperless_mobile/core/widgets/documents_list_loading_widget.dart';
import 'package:paperless_mobile/core/widgets/offline_widget.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/view/widgets/list/document_list_item.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class DocumentListView extends StatelessWidget {
  final void Function(DocumentModel) onTap;
  final void Function(DocumentModel) onSelected;

  final PagingController<int, DocumentModel> pagingController;
  final DocumentsState state;
  final bool hasInternetConnection;
  final bool isLabelClickable;
  final void Function(int id)? onTagSelected;
  final void Function(int? id)? onCorrespondentSelected;
  final void Function(int? id)? onDocumentTypeSelected;
  final void Function(int? id)? onStoragePathSelected;

  const DocumentListView({
    super.key,
    required this.onTap,
    required this.pagingController,
    required this.state,
    required this.onSelected,
    required this.hasInternetConnection,
    this.isLabelClickable = true,
    this.onTagSelected,
    this.onCorrespondentSelected,
    this.onDocumentTypeSelected,
    this.onStoragePathSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PagedSliverList<int, DocumentModel>(
      pagingController: pagingController,
      builderDelegate: PagedChildBuilderDelegate(
        animateTransitions: true,
        itemBuilder: (context, document, index) {
          return LabelRepositoriesProvider(
            child: DocumentListItem(
              isLabelClickable: isLabelClickable,
              document: document,
              onTap: onTap,
              isSelected: state.selection.contains(document),
              onSelected: onSelected,
              isAtLeastOneSelected: state.selection.isNotEmpty,
              isTagSelectedPredicate: (int tagId) {
                return state.filter.tags is IdsTagsQuery
                    ? (state.filter.tags as IdsTagsQuery)
                        .includedIds
                        .contains(tagId)
                    : false;
              },
              onTagSelected: onTagSelected,
              onCorrespondentSelected: onCorrespondentSelected,
              onDocumentTypeSelected: onDocumentTypeSelected,
              onStoragePathSelected: onStoragePathSelected,
            ),
          );
        },
        noItemsFoundIndicatorBuilder: (context) => hasInternetConnection
            ? const DocumentsListLoadingWidget()
            : const OfflineWidget(),
      ),
    );
  }
}
