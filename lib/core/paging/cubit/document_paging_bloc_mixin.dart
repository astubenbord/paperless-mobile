import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';

import 'paged_documents_state.dart';

///
/// Mixin which can be used on cubits that handle documents.
/// This implements all paging and filtering logic.
///
mixin DocumentPagingBlocMixin<State extends DocumentPagingState>
    on BlocBase<State> {
  ConnectivityStatusService get connectivityStatusService;
  PaperlessDocumentsApi get api;
  DocumentChangedNotifier get notifier;

  Future<void> onFilterUpdated(DocumentFilter filter);

  Future<void> loadMore() async {
    final hasConnection =
        await connectivityStatusService.isConnectedToInternet();
    if (state.isLastPageLoaded || !hasConnection || state.isLoading) {
      return;
    }
    emit(state.copyWithPaged(isLoading: true));
    final newFilter = state.filter.copyWith(page: state.filter.page + 1);
    debugPrint("Fetching page ${newFilter.page}");
    try {
      final result = await api.findAll(newFilter);
      emit(
        state.copyWithPaged(
          hasLoaded: true,
          filter: newFilter,
          value: [...state.value, result],
        ),
      );
    } finally {
      await onFilterUpdated(newFilter);
      emit(state.copyWithPaged(isLoading: false));
    }
  }

  Future<void> initialize() {
    return updateFilter();
  }

  ///
  /// Updates document filter and automatically reloads documents. Always resets page to 1.
  /// Use [loadMore] to load more data.
  Future<void> updateFilter({
    final DocumentFilter filter = const DocumentFilter(),
    bool emitLoading = true,
  }) async {
    final hasConnection =
        await connectivityStatusService.isConnectedToInternet();
    if (!hasConnection) {
      // Just filter currently loaded documents
      final filteredDocuments = state.value
          .expand((page) => page.results)
          .where((doc) => filter.matches(doc))
          .toList();
      if (emitLoading) {
        emit(state.copyWithPaged(isLoading: true));
      }

      emit(
        state.copyWithPaged(
          filter: filter,
          value: [
            PagedSearchResult(
              results: filteredDocuments,
              count: filteredDocuments.length,
              next: null,
              previous: null,
            )
          ],
          hasLoaded: true,
        ),
      );
      return;
    }
    try {
      if (emitLoading) {
        emit(state.copyWithPaged(isLoading: true));
      }
      final result = await api.findAll(filter.copyWith(page: 1));

      emit(
        state.copyWithPaged(
          filter: filter,
          value: [result],
          hasLoaded: true,
        ),
      );
    } finally {
      // await onFilterUpdated(filter);
      emit(state.copyWithPaged(isLoading: false));
    }
  }

  ///
  /// Convenience method which allows to directly use [DocumentFilter.copyWith] on the current filter.
  ///
  Future<void> updateCurrentFilter(
    final DocumentFilter Function(DocumentFilter filter) transformFn,
  ) async =>
      updateFilter(filter: transformFn(state.filter));

  Future<void> resetFilter() async {
    final filter = DocumentFilter.initial.copyWith(
      sortField: state.filter.sortField,
      sortOrder: state.filter.sortOrder,
    );
    return updateFilter(filter: filter);
  }

  Future<void> reload() async {
    // emit(state.copyWithPaged(isLoading: true));
    final filter = state.filter.copyWith(page: 1);
    try {
      final result = await api.findAll(filter);
      if (!isClosed) {
        emit(state.copyWithPaged(
          hasLoaded: true,
          value: [result],
          isLoading: false,
          filter: filter,
        ));
      }
    } finally {
      await onFilterUpdated(filter);
      if (!isClosed) {
        emit(state.copyWithPaged(isLoading: false));
      }
    }
  }

  ///
  /// Updates a document. If [shouldReload] is false, the updated document will
  /// replace the currently loaded one, otherwise all documents will be reloaded.
  ///
  Future<void> update(DocumentModel document) async {
    final updatedDocument = await api.update(document);
    notifier.notifyUpdated(updatedDocument);
    // replace(updatedDocument);
  }

  ///
  /// Deletes a document and removes it from the currently loaded state.
  ///
  Future<void> delete(DocumentModel document) async {
    // emit(state.copyWithPaged(isLoading: true));
    try {
      await api.delete(document);
      notifier.notifyDeleted(document);
    } finally {
      emit(state.copyWithPaged(isLoading: false));
    }
  }

  ///
  /// Removes [document] from the currently loaded state.
  /// Does not delete it from the server!
  ///
  void remove(DocumentModel document) {
    final index = state.value.indexWhere(
      (page) => page.results.any((element) => element.id == document.id),
    );
    if (index != -1) {
      final foundPage = state.value[index];
      final replacementPage = foundPage.copyWith(
        results: foundPage.results
          ..removeWhere((element) => element.id == document.id),
      );
      final newCount = foundPage.count - 1;
      emit(
        state.copyWithPaged(
          value: state.value
              .mapIndexed(
                (currIndex, element) =>
                    (currIndex == index ? replacementPage : element)
                        .copyWith(count: newCount),
              )
              .toList(),
        ),
      );
    }
  }

  ///
  /// Replaces the document with the same id as [document] from the currently
  /// loaded state if the document's properties still match the given filter criteria, otherwise removes it.
  ///
  Future<void> replace(DocumentModel document) async {
    final matchesFilterCriteria = state.filter.matches(document);
    if (!matchesFilterCriteria) {
      return remove(document);
    }
    final pageIndex = state.value.indexWhere(
      (page) => page.results.any((element) => element.id == document.id),
    );
    if (pageIndex != -1) {
      final foundPage = state.value[pageIndex];
      final replacementPage = foundPage.copyWith(
        results: foundPage.results
            .map((doc) => doc.id == document.id ? document : doc)
            .toList(),
      );
      final newState = state.copyWithPaged(
        value: state.value
            .mapIndexed((currIndex, element) =>
                currIndex == pageIndex ? replacementPage : element)
            .toList(),
      );
      emit(newState);
    }
  }

  @override
  Future<void> close() {
    notifier.removeListener(this);
    return super.close();
  }
}
