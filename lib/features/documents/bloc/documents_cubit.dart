import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/bloc/global_error_cubit.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/model/paged_search_result.dart';
import 'package:paperless_mobile/features/documents/repository/document_repository.dart';
import 'package:injectable/injectable.dart';

@singleton
class DocumentsCubit extends Cubit<DocumentsState> {
  final DocumentRepository documentRepository;
  final GlobalErrorCubit errorCubit;

  DocumentsCubit(this.documentRepository, this.errorCubit)
      : super(DocumentsState.initial);

  Future<void> addDocument(
    Uint8List bytes,
    String fileName, {
    required String title,
    required void Function(DocumentModel document) onConsumptionFinished,
    int? documentType,
    int? correspondent,
    List<int>? tags,
    DateTime? createdAt,
    bool propagateEventOnError = true,
  }) async {
    try {
      await documentRepository.create(
        bytes,
        fileName,
        title: title,
        documentType: documentType,
        correspondent: correspondent,
        tags: tags,
        createdAt: createdAt,
      );
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      } else {
        rethrow;
      }
    }
    // documentRepository
    //     .waitForConsumptionFinished(fileName, title)
    //     .then((value) => onConsumptionFinished(value));
  }

  Future<void> removeDocument(
    DocumentModel document, {
    bool propagateEventOnError = true,
  }) async {
    try {
      await documentRepository.delete(document);
      return await reloadDocuments();
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      } else {
        rethrow;
      }
    }
  }

  Future<void> bulkRemoveDocuments(List<DocumentModel> documents,
      {bool propagateEventOnError = true}) async {
    try {
      await documentRepository.bulkDelete(documents);
      return await reloadDocuments();
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      } else {
        rethrow;
      }
    }
  }

  Future<void> updateDocument(
    DocumentModel document, {
    bool propagateEventOnError = true,
  }) async {
    try {
      await documentRepository.update(document);
      await reloadDocuments();
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      } else {
        rethrow;
      }
    }
  }

  Future<void> loadDocuments({
    bool propagateEventOnError = true,
  }) async {
    try {
      final result = await documentRepository.find(state.filter);
      emit(DocumentsState(
        isLoaded: true,
        value: [...state.value, result],
        filter: state.filter,
      ));
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      } else {
        rethrow;
      }
    }
  }

  Future<void> reloadDocuments({
    bool propagateEventOnError = true,
  }) async {
    if (state.currentPageNumber >= 5) {
      return _bulkReloadDocuments();
    }
    var newPages = <PagedSearchResult>[];
    try {
      for (final page in state.value) {
        final result = await documentRepository
            .find(state.filter.copyWith(page: page.pageKey));
        newPages.add(result);
      }
      emit(DocumentsState(
          isLoaded: true, value: newPages, filter: state.filter));
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _bulkReloadDocuments({
    bool propagateEventOnError = true,
  }) async {
    try {
      final result = await documentRepository.find(
          state.filter.copyWith(page: 1, pageSize: state.documents.length));
      emit(DocumentsState(
          isLoaded: true, value: [result], filter: state.filter));
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      } else {
        rethrow;
      }
    }
  }

  Future<void> loadMore({
    bool propagateEventOnError = true,
  }) async {
    if (state.isLastPageLoaded) {
      return;
    }
    final newFilter = state.filter.copyWith(page: state.filter.page + 1);
    try {
      final result = await documentRepository.find(newFilter);
      emit(DocumentsState(
          isLoaded: true, value: [...state.value, result], filter: newFilter));
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      } else {
        rethrow;
      }
    }
  }

  Future<void> assignAsn(
    DocumentModel document, {
    bool propagateEventOnError = true,
  }) async {
    try {
      if (document.archiveSerialNumber == null) {
        final int asn = await documentRepository.findNextAsn();
        updateDocument(document.copyWith(archiveSerialNumber: asn));
      }
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      } else {
        rethrow;
      }
    }
  }

  ///
  /// Update filter state and automatically reload documents. Always resets page to 1.
  /// Use [DocumentsCubit.loadMore] to load more data.
  Future<void> updateFilter(
      {final DocumentFilter filter = DocumentFilter.initial,
      bool propagateEventOnError = true}) async {
    try {
      final result = await documentRepository.find(filter.copyWith(page: 1));
      emit(DocumentsState(filter: filter, value: [result], isLoaded: true));
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      } else {
        rethrow;
      }
    }
  }

  ///
  /// Convenience method which allows to directly use [DocumentFilter.copyWith] on the current filter.
  ///
  Future<void> updateCurrentFilter(
    final DocumentFilter Function(DocumentFilter) transformFn, {
    bool propagateEventOnError = true,
  }) async {
    try {
      return updateFilter(filter: transformFn(state.filter));
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        return errorCubit.add(error);
      } else {
        rethrow;
      }
    }
  }

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
