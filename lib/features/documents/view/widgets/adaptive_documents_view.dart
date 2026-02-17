import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/view/widgets/placeholder/document_grid_loading_widget.dart';
import 'package:paperless_mobile/features/documents/view/widgets/items/document_detailed_item.dart';
import 'package:paperless_mobile/features/documents/view/widgets/items/document_grid_item.dart';
import 'package:paperless_mobile/features/documents/view/widgets/items/document_list_item.dart';
import 'package:paperless_mobile/features/documents/view/widgets/placeholder/documents_list_loading_widget.dart';
import 'package:paperless_mobile/core/paging/cubit/paged_documents_state.dart';
import 'package:paperless_mobile/core/model/view_type.dart';

abstract class AdaptiveDocumentsView extends StatelessWidget {
  final List<DocumentModel> documents;
  final bool isLoading;
  final bool hasLoaded;
  final bool enableHeroAnimation;
  final List<int> selectedDocumentIds;
  final ViewType viewType;
  final void Function(DocumentModel)? onTap;
  final void Function(DocumentModel)? onSelected;
  final bool hasInternetConnection;
  final bool isLabelClickable;
  final void Function(int id)? onTagSelected;
  final void Function(int? id)? onCorrespondentSelected;
  final void Function(int? id)? onDocumentTypeSelected;
  final void Function(int? id)? onStoragePathSelected;

  bool get showLoadingPlaceholder => !hasLoaded && isLoading;

  const AdaptiveDocumentsView({
    super.key,
    this.selectedDocumentIds = const [],
    required this.documents,
    this.onTap,
    this.onSelected,
    this.viewType = ViewType.list,
    required this.hasInternetConnection,
    required this.isLabelClickable,
    this.onTagSelected,
    this.onCorrespondentSelected,
    this.onDocumentTypeSelected,
    this.onStoragePathSelected,
    required this.isLoading,
    required this.hasLoaded,
    this.enableHeroAnimation = true,
  });

  AdaptiveDocumentsView.fromPagedState(
    DocumentPagingState state, {
    super.key,
    this.onSelected,
    this.onTap,
    this.onCorrespondentSelected,
    this.onDocumentTypeSelected,
    this.onStoragePathSelected,
    this.onTagSelected,
    this.isLabelClickable = true,
    this.enableHeroAnimation = true,
    required this.hasInternetConnection,
    this.viewType = ViewType.list,
    this.selectedDocumentIds = const [],
  })  : documents = state.documents,
        isLoading = state.isLoading,
        hasLoaded = state.hasLoaded;
}

class SliverAdaptiveDocumentsView extends AdaptiveDocumentsView {
  const SliverAdaptiveDocumentsView({
    super.key,
    required super.documents,
    required super.hasInternetConnection,
    required super.isLabelClickable,
    super.onCorrespondentSelected,
    super.onDocumentTypeSelected,
    super.onStoragePathSelected,
    super.onSelected,
    super.onTagSelected,
    super.onTap,
    super.selectedDocumentIds,
    super.viewType,
    super.enableHeroAnimation,
    required super.isLoading,
    required super.hasLoaded,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewType) {
      case ViewType.grid:
        return _buildGridView();
      case ViewType.list:
        return _buildListView();
      case ViewType.detailed:
        return _buildFullView(context);
    }
  }

  Widget _buildListView() {
    if (showLoadingPlaceholder) {
      return const DocumentsListLoadingWidget.sliver();
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: documents.length,
        (context, index) {
          final document = documents.elementAt(index);
          return DocumentListItem(
            isLabelClickable: isLabelClickable,
            document: document,
            onTap: onTap,
            isSelected: selectedDocumentIds.contains(document.id),
            onSelected: onSelected,
            isSelectionActive: selectedDocumentIds.isNotEmpty,
            onTagSelected: onTagSelected,
            onCorrespondentSelected: onCorrespondentSelected,
            onDocumentTypeSelected: onDocumentTypeSelected,
            onStoragePathSelected: onStoragePathSelected,
            enableHeroAnimation: enableHeroAnimation,
          );
        },
      ),
    );
  }

  Widget _buildFullView(BuildContext context) {
    if (showLoadingPlaceholder) {
      //TODO: Build detailed loading animation
      return const DocumentsListLoadingWidget.sliver();
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: documents.length,
        (context, index) {
          final document = documents.elementAt(index);
          return DocumentDetailedItem(
            isLabelClickable: isLabelClickable,
            document: document,
            onTap: onTap,
            isSelected: selectedDocumentIds.contains(document.id),
            onSelected: onSelected,
            isSelectionActive: selectedDocumentIds.isNotEmpty,
            onTagSelected: onTagSelected,
            onCorrespondentSelected: onCorrespondentSelected,
            onDocumentTypeSelected: onDocumentTypeSelected,
            onStoragePathSelected: onStoragePathSelected,
            enableHeroAnimation: enableHeroAnimation,
            highlights: document.searchHit?.highlights,
          );
        },
      ),
    );
  }

  Widget _buildGridView() {
    if (showLoadingPlaceholder) {
      return const DocumentGridLoadingWidget.sliver();
    }
    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        mainAxisExtent: 324,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents.elementAt(index);
        return DocumentGridItem(
          document: document,
          onTap: onTap,
          isSelected: selectedDocumentIds.contains(document.id),
          onSelected: onSelected,
          isSelectionActive: selectedDocumentIds.isNotEmpty,
          isLabelClickable: isLabelClickable,
          onTagSelected: onTagSelected,
          onCorrespondentSelected: onCorrespondentSelected,
          onDocumentTypeSelected: onDocumentTypeSelected,
          onStoragePathSelected: onStoragePathSelected,
          enableHeroAnimation: enableHeroAnimation,
        ).paddedSymmetrically(horizontal: 4);
      },
    );
  }
}

class DefaultAdaptiveDocumentsView extends AdaptiveDocumentsView {
  final ScrollController? scrollController;
  const DefaultAdaptiveDocumentsView({
    super.key,
    required super.documents,
    required super.hasInternetConnection,
    required super.isLabelClickable,
    required super.isLoading,
    required super.hasLoaded,
    super.onCorrespondentSelected,
    super.onDocumentTypeSelected,
    super.onStoragePathSelected,
    super.onSelected,
    super.onTagSelected,
    super.onTap,
    this.scrollController,
    super.selectedDocumentIds,
    super.viewType,
    super.enableHeroAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewType) {
      case ViewType.grid:
        return _buildGridView();
      case ViewType.list:
        return _buildListView();
      case ViewType.detailed:
        return _buildFullView();
    }
  }

  Widget _buildListView() {
    if (showLoadingPlaceholder) {
      return const DocumentsListLoadingWidget();
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      controller: scrollController,
      primary: false,
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents.elementAt(index);
        return DocumentListItem(
          isLabelClickable: isLabelClickable,
          document: document,
          onTap: onTap,
          isSelected: selectedDocumentIds.contains(document.id),
          onSelected: onSelected,
          isSelectionActive: selectedDocumentIds.isNotEmpty,
          onTagSelected: onTagSelected,
          onCorrespondentSelected: onCorrespondentSelected,
          onDocumentTypeSelected: onDocumentTypeSelected,
          onStoragePathSelected: onStoragePathSelected,
          enableHeroAnimation: enableHeroAnimation,
        );
      },
    );
  }

  Widget _buildFullView() {
    if (showLoadingPlaceholder) {
      return const DocumentsListLoadingWidget();
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const PageScrollPhysics(),
      controller: scrollController,
      primary: false,
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents.elementAt(index);
        return DocumentDetailedItem(
          isLabelClickable: isLabelClickable,
          document: document,
          onTap: onTap,
          isSelected: selectedDocumentIds.contains(document.id),
          onSelected: onSelected,
          isSelectionActive: selectedDocumentIds.isNotEmpty,
          onTagSelected: onTagSelected,
          onCorrespondentSelected: onCorrespondentSelected,
          onDocumentTypeSelected: onDocumentTypeSelected,
          onStoragePathSelected: onStoragePathSelected,
          enableHeroAnimation: enableHeroAnimation,
        );
      },
    );
  }

  Widget _buildGridView() {
    if (showLoadingPlaceholder) {
      return const DocumentGridLoadingWidget();
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      controller: scrollController,
      primary: false,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1 / 2,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents.elementAt(index);
        return DocumentGridItem(
          document: document,
          onTap: onTap,
          isSelected: selectedDocumentIds.contains(document.id),
          onSelected: onSelected,
          isSelectionActive: selectedDocumentIds.isNotEmpty,
          isLabelClickable: isLabelClickable,
          onTagSelected: onTagSelected,
          onCorrespondentSelected: onCorrespondentSelected,
          onDocumentTypeSelected: onDocumentTypeSelected,
          onStoragePathSelected: onStoragePathSelected,
          enableHeroAnimation: enableHeroAnimation,
        );
      },
    );
  }
}
