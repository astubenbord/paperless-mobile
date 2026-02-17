import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/logging/logger.dart';

part 'document_edit_state.dart';
part 'document_edit_cubit.freezed.dart';

class DocumentEditCubit extends Cubit<DocumentEditState> {
  final DocumentModel _initialDocument;
  final PaperlessDocumentsApi _docsApi;
  final LabelRepository _labelRepository;
  final DocumentChangedNotifier _notifier;

  DocumentEditCubit(
    this._labelRepository,
    this._docsApi,
    this._notifier, {
    required DocumentModel document,
  })  : _initialDocument = document,
        super(DocumentEditState(document: document)) {
    _notifier.addListener(
      this,
      onUpdated: (doc) {
        emit(state.copyWith(
          document: doc,
          suggestions: null,
        ));
        loadFieldSuggestions();
      },
      ids: [document.id],
    );
  }

  Future<void> updateDocument(DocumentModel document) async {
    logger.fi(
      "Updating document ${document.id}...",
      className: runtimeType.toString(),
      methodName: "updateDocument",
    );
    final updated = await _docsApi.update(document);
    logger.fi(
      "Document ${document.id} successfully updated.",
      className: runtimeType.toString(),
      methodName: "updateDocument",
    );
    _notifier.notifyUpdated(updated);

    // Reload changed labels (documentCount property changes with removal/add)
    if (document.documentType != _initialDocument.documentType) {
      logger.fd(
        "Document type assigned to document ${document.id} has changed "
        "(${_initialDocument.documentType} -> ${document.documentType}). "
        "Reloading document type ${document.documentType}...",
        className: runtimeType.toString(),
        methodName: "updateDocument",
      );
      _labelRepository.findDocumentType(
        (document.documentType ?? _initialDocument.documentType)!,
      );
    }
    if (document.correspondent != _initialDocument.correspondent) {
      logger.fd(
        "Correspondent assigned to document ${document.id} has changed "
        "(${_initialDocument.correspondent} -> ${document.correspondent}). "
        "Reloading correspondent ${document.correspondent}...",
        className: runtimeType.toString(),
        methodName: "updateDocument",
      );
      _labelRepository.findCorrespondent(
          (document.correspondent ?? _initialDocument.correspondent)!);
    }
    if (document.storagePath != _initialDocument.storagePath) {
      logger.fd(
        "Storage path assigned to document ${document.id} has changed "
        "(${_initialDocument.storagePath} -> ${document.storagePath}). "
        "Reloading storage path ${document.storagePath}...",
        className: runtimeType.toString(),
        methodName: "updateDocument",
      );
      _labelRepository.findStoragePath(
          (document.storagePath ?? _initialDocument.storagePath)!);
    }
    if (!const DeepCollectionEquality.unordered()
        .equals(document.tags.toList(), _initialDocument.tags.toList())) {
      final tagsToReload = {...document.tags, ..._initialDocument.tags};
      logger.fd(
        "Tags assigned to document ${document.id} have changed "
        "(${_initialDocument.tags.join(",")} -> ${document.tags.join(",")}). "
        "Reloading tags ${tagsToReload.join(",")}...",
        className: runtimeType.toString(),
        methodName: "updateDocument",
      );
      _labelRepository.findAllTags(tagsToReload);
    }
  }

  Future<void> loadFieldSuggestions() async {
    logger.fi(
      "Loading suggestions for document ${state.document.id}...",
      className: runtimeType.toString(),
      methodName: "loadFieldSuggestions",
    );
    final suggestions = await _docsApi.findSuggestions(state.document);
    logger.fi(
      "Found ${suggestions.suggestionsCount} suggestions for document ${state.document.id}.",
      className: runtimeType.toString(),
      methodName: "loadFieldSuggestions",
    );
    emit(state.copyWith(suggestions: suggestions));
  }

  @override
  Future<void> close() {
    _notifier.removeListener(this);
    return super.close();
  }
}
