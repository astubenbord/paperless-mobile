import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:collection/collection.dart';

part 'edit_document_state.dart';

class EditDocumentCubit extends Cubit<EditDocumentState> {
  final DocumentModel _initialDocument;
  final PaperlessDocumentsApi _docsApi;

  final LabelRepository<Correspondent> _correspondentRepository;
  final LabelRepository<DocumentType> _documentTypeRepository;
  final LabelRepository<StoragePath> _storagePathRepository;
  final LabelRepository<Tag> _tagRepository;

  final List<StreamSubscription> _subscriptions = [];
  EditDocumentCubit(
    DocumentModel document, {
    required PaperlessDocumentsApi documentsApi,
    required LabelRepository<Correspondent> correspondentRepository,
    required LabelRepository<DocumentType> documentTypeRepository,
    required LabelRepository<StoragePath> storagePathRepository,
    required LabelRepository<Tag> tagRepository,
  })  : _initialDocument = document,
        _docsApi = documentsApi,
        _correspondentRepository = correspondentRepository,
        _documentTypeRepository = documentTypeRepository,
        _storagePathRepository = storagePathRepository,
        _tagRepository = tagRepository,
        super(
          EditDocumentState(
            document: document,
            correspondents: correspondentRepository.current ?? {},
            documentTypes: documentTypeRepository.current ?? {},
            storagePaths: storagePathRepository.current ?? {},
            tags: tagRepository.current ?? {},
          ),
        ) {
    _subscriptions.add(
      _correspondentRepository.values
          .listen((v) => emit(state.copyWith(correspondents: v))),
    );
    _subscriptions.add(
      _documentTypeRepository.values
          .listen((v) => emit(state.copyWith(documentTypes: v))),
    );
    _subscriptions.add(
      _storagePathRepository.values
          .listen((v) => emit(state.copyWith(storagePaths: v))),
    );
    _subscriptions.add(
      _tagRepository.values.listen(
        (v) => emit(state.copyWith(tags: v)),
      ),
    );
  }

  Future<void> updateDocument(DocumentModel document) async {
    final updated = await _docsApi.update(document);
    // Reload changed labels (documentCount property changes with removal/add)
    if (document.documentType != _initialDocument.documentType) {
      _documentTypeRepository
          .find((document.documentType ?? _initialDocument.documentType)!);
    }
    if (document.correspondent != _initialDocument.correspondent) {
      _correspondentRepository
          .find((document.correspondent ?? _initialDocument.correspondent)!);
    }
    if (document.storagePath != _initialDocument.storagePath) {
      _storagePathRepository
          .find((document.storagePath ?? _initialDocument.storagePath)!);
    }
    if (!const DeepCollectionEquality.unordered()
        .equals(document.tags, _initialDocument.tags)) {
      _tagRepository.findAll(document.tags);
    }
    emit(state.copyWith(document: updated));
  }

  @override
  Future<void> close() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    return super.close();
  }
}
