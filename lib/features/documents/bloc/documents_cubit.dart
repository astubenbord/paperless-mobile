import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
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

  DocumentsCubit(this.documentRepository) : super(DocumentsState.initial);

  Future<void> addDocument(
    Uint8List bytes,
    String fileName, {
    required String title,
    required void Function(DocumentModel document) onConsumptionFinished,
    int? documentType,
    int? correspondent,
    List<int>? tags,
    DateTime? createdAt,
  }) async {
    await documentRepository.create(
      bytes,
      fileName,
      title: title,
      documentType: documentType,
      correspondent: correspondent,
      tags: tags,
      createdAt: createdAt,
    );

    // documentRepository
    //     .waitForConsumptionFinished(fileName, title)
    //     .then((value) => onConsumptionFinished(value));
  }

  Future<void> removeDocument(DocumentModel document) async {
    await documentRepository.delete(document);
    return await reloadDocuments();
  }

  Future<void> bulkRemoveDocuments(List<DocumentModel> documents) async {
    await documentRepository.bulkDelete(documents);
    return await reloadDocuments();
  }

  Future<void> updateDocument(DocumentModel document) async {
    await documentRepository.update(document);
    await reloadDocuments();
  }

  Future<void> loadDocuments() async {
    final result = await documentRepository.find(state.filter);
    emit(DocumentsState(
      isLoaded: true,
      value: [...state.value, result],
      filter: state.filter,
    ));
  }

  Future<void> reloadDocuments() async {
    if (state.currentPageNumber >= 5) {
      return _bulkReloadDocuments();
    }
    var newPages = <PagedSearchResult>[];
    for (final page in state.value) {
      final result = await documentRepository
          .find(state.filter.copyWith(page: page.pageKey));
      newPages.add(result);
    }
    emit(DocumentsState(isLoaded: true, value: newPages, filter: state.filter));
  }

  Future<void> _bulkReloadDocuments() async {
    final result = await documentRepository
        .find(state.filter.copyWith(page: 1, pageSize: state.documents.length));
    emit(DocumentsState(isLoaded: true, value: [result], filter: state.filter));
  }

  Future<void> loadMore() async {
    if (state.isLastPageLoaded) {
      return;
    }
    final newFilter = state.filter.copyWith(page: state.filter.page + 1);
    final result = await documentRepository.find(newFilter);
    emit(DocumentsState(
        isLoaded: true, value: [...state.value, result], filter: newFilter));
  }

  Future<void> assignAsn(DocumentModel document) async {
    if (document.archiveSerialNumber == null) {
      final int asn = await documentRepository.findNextAsn();
      updateDocument(document.copyWith(archiveSerialNumber: asn));
    }
  }

  ///
  /// Update filter state and automatically reload documents. Always resets page to 1.
  /// Use [DocumentsCubit.loadMore] to load more data.
  Future<void> updateFilter({
    final DocumentFilter filter = DocumentFilter.initial,
  }) async {
    final result = await documentRepository.find(filter.copyWith(page: 1));
    emit(DocumentsState(filter: filter, value: [result], isLoaded: true));
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
