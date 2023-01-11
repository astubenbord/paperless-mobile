import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/provider/label_repositories_provider.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/view/widgets/grid/document_grid_item.dart';
import 'package:paperless_mobile/features/documents/view/widgets/list/document_list_item.dart';
import 'package:paperless_mobile/features/settings/model/view_type.dart';

class AdaptiveDocumentsView extends StatelessWidget {
  final ViewType viewType;
  final Widget beforeItems;
  final void Function(DocumentModel) onTap;
  final void Function(DocumentModel) onSelected;
  final ScrollController scrollController;
  final DocumentsState state;
  final bool hasInternetConnection;
  final bool isLabelClickable;
  final void Function(int id)? onTagSelected;
  final void Function(int? id)? onCorrespondentSelected;
  final void Function(int? id)? onDocumentTypeSelected;
  final void Function(int? id)? onStoragePathSelected;
  final Widget pageLoadingWidget;

  const AdaptiveDocumentsView({
    super.key,
    required this.onTap,
    required this.scrollController,
    required this.state,
    required this.onSelected,
    required this.hasInternetConnection,
    this.isLabelClickable = true,
    this.onTagSelected,
    this.onCorrespondentSelected,
    this.onDocumentTypeSelected,
    this.onStoragePathSelected,
    required this.pageLoadingWidget,
    required this.beforeItems,
    required this.viewType,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: beforeItems),
        if (viewType == ViewType.list) _buildListView() else _buildGridView(),
      ],
    );
  }

  SliverList _buildListView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: state.documents.length,
        (context, index) {
          final document = state.documents.elementAt(index);
          return LabelRepositoriesProvider(
            child: DocumentListItem(
              isLabelClickable: isLabelClickable,
              document: document,
              onTap: onTap,
              isSelected: state.selectedIds.contains(document.id),
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
      ),
    );
  }

  Widget _buildGridView() {
    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 178,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1 / 2,
      ),
      itemCount: state.documents.length,
      itemBuilder: (context, index) {
        if (state.hasLoaded &&
            state.isLoading &&
            index == state.documents.length) {
          return Center(child: pageLoadingWidget);
        }
        final document = state.documents.elementAt(index);
        return DocumentGridItem(
          document: document,
          onTap: onTap,
          isSelected: state.selectedIds.contains(document.id),
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
        );
      },
    );
  }
}
