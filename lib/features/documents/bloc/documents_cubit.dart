import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';

part 'documents_state.dart';

class DocumentsCubit extends Cubit<DocumentsState> {
  final PaperlessDocumentsApi _api;

  DocumentsCubit(this._api) : super(DocumentsState.initial);

  Future<void> bulkRemove(List<DocumentModel> documents) async {
    await _api.bulkAction(
      BulkDeleteAction(documents.map((doc) => doc.id)),
    );
    await reload();
  }

  Future<void> bulkEditTags(
    Iterable<DocumentModel> documents, {
    Iterable<int> addTags = const [],
    Iterable<int> removeTags = const [],
  }) async {
    await _api.bulkAction(BulkModifyTagsAction(
      documents.map((doc) => doc.id),
      addTags: addTags,
      removeTags: removeTags,
    ));
    await reload();
  }

  Future<void> update(
    DocumentModel document, [
    bool updateRemote = true,
  ]) async {
    if (updateRemote) {
      await _api.update(document);
    }
    await reload();
  }

  Future<void> load() async {
    final result = await _api.find(state.filter);
    emit(DocumentsState(
      isLoaded: true,
      value: [...state.value, result],
      filter: state.filter,
    ));
  }

  Future<void> reload() async {
    if (state.currentPageNumber >= 5) {
      return _bulkReloadDocuments();
    }
    var newPages = <PagedSearchResult>[];
    for (final page in state.value) {
      final result = await _api.find(state.filter.copyWith(page: page.pageKey));
      newPages.add(result);
    }
    emit(DocumentsState(isLoaded: true, value: newPages, filter: state.filter));
  }

  Future<void> _bulkReloadDocuments() async {
    final result = await _api
        .find(state.filter.copyWith(page: 1, pageSize: state.documents.length));
    emit(DocumentsState(isLoaded: true, value: [result], filter: state.filter));
  }

  Future<void> loadMore() async {
    if (state.isLastPageLoaded) {
      return;
    }
    final newFilter = state.filter.copyWith(page: state.filter.page + 1);
    final result = await _api.find(newFilter);
    emit(
      DocumentsState(
          isLoaded: true, value: [...state.value, result], filter: newFilter),
    );
  }

  ///
  /// Update filter state and automatically reload documents. Always resets page to 1.
  /// Use [DocumentsCubit.loadMore] to load more data.
  Future<void> updateFilter({
    final DocumentFilter filter = DocumentFilter.initial,
  }) async {
    final result = await _api.find(filter.copyWith(page: 1));
    emit(DocumentsState(filter: filter, value: [result], isLoaded: true));
  }

  Future<void> resetFilter() {
    final filter = DocumentFilter.initial.copyWith(
      sortField: state.filter.sortField,
      sortOrder: state.filter.sortOrder,
    );
    return updateFilter(filter: filter);
  }

  ///
  /// Convenience method which allows to directly use [DocumentFilter.copyWith] on the current filter.
  ///
  Future<void> updateCurrentFilter(
    final DocumentFilter Function(DocumentFilter) transformFn,
  ) async =>
      updateFilter(filter: transformFn(state.filter));

  void toggleDocumentSelection(DocumentModel model) {
    if (state.selection.contains(model)) {
      emit(
        state.copyWith(
          selection: state.selection
              .where((element) => element.id != model.id)
              .toList(),
        ),
      );
    } else {
      emit(
        state.copyWith(selection: [...state.selection, model]),
      );
    }
  }

  void resetSelection() {
    emit(state.copyWith(selection: []));
  }

  void reset() {
    emit(DocumentsState.initial);
  }
}
