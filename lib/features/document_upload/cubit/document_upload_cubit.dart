import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/correspondent_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/document_type_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/tag_repository_state.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';

part 'document_upload_state.dart';

class DocumentUploadCubit extends Cubit<DocumentUploadState> {
  final PaperlessDocumentsApi _documentApi;

  final LabelRepository<Tag, TagRepositoryState> _tagRepository;
  final LabelRepository<Correspondent, CorrespondentRepositoryState>
      _correspondentRepository;
  final LabelRepository<DocumentType, DocumentTypeRepositoryState>
      _documentTypeRepository;

  final List<StreamSubscription> _subs = [];

  DocumentUploadCubit({
    required LocalVault localVault,
    required PaperlessDocumentsApi documentApi,
    required LabelRepository<Tag, TagRepositoryState> tagRepository,
    required LabelRepository<Correspondent, CorrespondentRepositoryState>
        correspondentRepository,
    required LabelRepository<DocumentType, DocumentTypeRepositoryState>
        documentTypeRepository,
  })  : _documentApi = documentApi,
        _tagRepository = tagRepository,
        _correspondentRepository = correspondentRepository,
        _documentTypeRepository = documentTypeRepository,
        super(
          const DocumentUploadState(
            tags: {},
            correspondents: {},
            documentTypes: {},
          ),
        ) {
    _subs.add(_tagRepository.values.listen(
      (tags) => emit(state.copyWith(tags: tags?.values)),
    ));
    _subs.add(_correspondentRepository.values.listen(
      (correspondents) =>
          emit(state.copyWith(correspondents: correspondents?.values)),
    ));
    _subs.add(_documentTypeRepository.values.listen(
      (documentTypes) =>
          emit(state.copyWith(documentTypes: documentTypes?.values)),
    ));
  }

  Future<String?> upload(
    Uint8List bytes, {
    required String filename,
    required String title,
    int? documentType,
    int? correspondent,
    Iterable<int> tags = const [],
    DateTime? createdAt,
  }) async {
    return await _documentApi.create(
      bytes,
      filename: filename,
      title: title,
      correspondent: correspondent,
      documentType: documentType,
      tags: tags,
      createdAt: createdAt,
    );
  }

  @override
  Future<void> close() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    return super.close();
  }
}
