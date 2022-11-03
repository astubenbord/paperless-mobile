import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/documents_list_loading_widget.dart';
import 'package:paperless_mobile/core/widgets/offline_widget.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/view/widgets/list/document_list_item.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class DocumentListView extends StatelessWidget {
  final void Function(DocumentModel) onTap;
  final void Function(DocumentModel) onSelected;

  final PagingController<int, DocumentModel> pagingController;
  final DocumentsState state;
  final bool hasInternetConnection;
  final bool isLabelClickable;
  const DocumentListView({
    super.key,
    required this.onTap,
    required this.pagingController,
    required this.state,
    required this.onSelected,
    required this.hasInternetConnection,
    this.isLabelClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    return PagedSliverList<int, DocumentModel>(
      pagingController: pagingController,
      builderDelegate: PagedChildBuilderDelegate(
        animateTransitions: true,
        itemBuilder: (context, document, index) {
          return DocumentListItem(
            isLabelClickable: isLabelClickable,
            document: document,
            onTap: onTap,
            isSelected: state.selection.contains(document),
            onSelected: onSelected,
            isAtLeastOneSelected: state.selection.isNotEmpty,
          );
        },
        noItemsFoundIndicatorBuilder: (context) => hasInternetConnection
            ? const DocumentsListLoadingWidget()
            : const OfflineWidget(),
      ),
    );
  }
}
