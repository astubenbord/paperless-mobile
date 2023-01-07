import 'dart:async';
import 'dart:developer';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';

class DocumentsCubit extends Cubit<DocumentsState> with HydratedMixin {
  final PaperlessDocumentsApi _api;
  final SavedViewRepository _savedViewRepository;

  DocumentsCubit(this._api, this._savedViewRepository)
      : super(const DocumentsState()) {
    hydrate();
  }

  Future<void> bulkRemove(List<DocumentModel> documents) async {
    log("[DocumentsCubit] bulkRemove");
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
    log("[DocumentsCubit] bulkEditTags");
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
    log("[DocumentsCubit] update");
    if (updateRemote) {
      await _api.update(document);
    }
    await reload();
  }

  Future<void> load() async {
    log("[DocumentsCubit] load");
    emit(state.copyWith(isLoading: true));
    try {
      final result = await _api.find(state.filter);
      emit(state.copyWith(
        isLoading: false,
        hasLoaded: true,
        value: [...state.value, result],
      ));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> reload() async {
    log("[DocumentsCubit] reload");
    emit(state.copyWith(isLoading: true));
    try {
      final result = await _api.find(state.filter.copyWith(page: 1));
      emit(state.copyWith(
        hasLoaded: true,
        value: [result],
        isLoading: false,
      ));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _bulkReloadDocuments() async {
    emit(state.copyWith(isLoading: true));
    try {
      final result = await _api.find(
        state.filter.copyWith(
          page: 1,
          pageSize: state.documents.length,
        ),
      );
      emit(DocumentsState(
        hasLoaded: true,
        value: [result],
        filter: state.filter,
        isLoading: false,
      ));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> loadMore() async {
    log("[DocumentsCubit] loadMore");
    if (state.isLastPageLoaded) {
      return;
    }
    emit(state.copyWith(isLoading: true));
    final newFilter = state.filter.copyWith(page: state.filter.page + 1);
    try {
      final result = await _api.find(newFilter);
      emit(
        DocumentsState(
          hasLoaded: true,
          value: [...state.value, result],
          filter: newFilter,
          isLoading: false,
        ),
      );
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  ///
  /// Updates document filter and automatically reloads documents. Always resets page to 1.
  /// Use [loadMore] to load more data.
  Future<void> updateFilter({
    final DocumentFilter filter = DocumentFilter.initial,
  }) async {
    log("[DocumentsCubit] updateFilter");
    try {
      emit(state.copyWith(isLoading: true));
      final result = await _api.find(filter.copyWith(page: 1));

      emit(
        DocumentsState(
          filter: filter,
          value: [result],
          hasLoaded: true,
          isLoading: false,
        ),
      );
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> resetFilter() {
    log("[DocumentsCubit] resetFilter");
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
    log("[DocumentsCubit] toggleSelection");
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
    log("[DocumentsCubit] resetSelection");
    emit(state.copyWith(selection: []));
  }

  void reset() {
    log("[DocumentsCubit] reset");
    emit(const DocumentsState());
  }

  Future<void> selectView(int id) async {
    emit(state.copyWith(isLoading: true));
    try {
      final filter =
          _savedViewRepository.current?.values[id]?.toDocumentFilter();
      if (filter == null) {
        return;
      }
      final results = await _api.find(filter.copyWith(page: 1));
      emit(
        DocumentsState(
          filter: filter,
          hasLoaded: true,
          isLoading: false,
          selectedSavedViewId: id,
          value: [results],
        ),
      );
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  void unselectView() {
    emit(state.copyWith(selectedSavedViewId: null));
  }

  @override
  DocumentsState? fromJson(Map<String, dynamic> json) {
    return DocumentsState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(DocumentsState state) {
    return state.toJson();
  }
}
