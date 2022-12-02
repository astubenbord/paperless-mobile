import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/documents_list_loading_widget.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/view/widgets/grid/document_grid_item.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class DocumentGridView extends StatelessWidget {
  final void Function(DocumentModel model) onTap;
  final void Function(DocumentModel) onSelected;
  final PagingController<int, DocumentModel> pagingController;
  final DocumentsState state;
  final bool hasInternetConnection;
  final void Function(int tagId) onTagSelected;

  const DocumentGridView({
    super.key,
    required this.onTap,
    required this.pagingController,
    required this.state,
    required this.onSelected,
    required this.hasInternetConnection,
    required this.onTagSelected,
  });
  @override
  Widget build(BuildContext context) {
    return PagedSliverGrid<int, DocumentModel>(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1 / 2,
      ),
      pagingController: pagingController,
      builderDelegate: PagedChildBuilderDelegate(
        itemBuilder: (context, item, index) {
          return DocumentGridItem(
            document: item,
            onTap: onTap,
            isSelected: state.selection.contains(item),
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
        noItemsFoundIndicatorBuilder: (context) =>
            const DocumentsListLoadingWidget(), //TODO: Replace with grid loading widget
      ),
    );
  }
}
