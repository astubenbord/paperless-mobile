import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';

part 'document_upload_state.dart';

class DocumentUploadCubit extends Cubit<DocumentUploadState> {
  final LocalVault _localVault;
  final PaperlessDocumentsApi _documentApi;

  final LabelRepository<Tag> _tagRepository;
  final LabelRepository<Correspondent> _correspondentRepository;
  final LabelRepository<DocumentType> _documentTypeRepository;

  final List<StreamSubscription> _subs = [];

  DocumentUploadCubit({
    required LocalVault localVault,
    required PaperlessDocumentsApi documentApi,
    required LabelRepository<Tag> tagRepository,
    required LabelRepository<Correspondent> correspondentRepository,
    required LabelRepository<DocumentType> documentTypeRepository,
  })  : _documentApi = documentApi,
        _tagRepository = tagRepository,
        _correspondentRepository = correspondentRepository,
        _documentTypeRepository = documentTypeRepository,
        _localVault = localVault,
        super(
          const DocumentUploadState(
            tags: {},
            correspondents: {},
            documentTypes: {},
          ),
        ) {
    _subs.add(_tagRepository.labels.listen(
      (tags) => emit(state.copyWith(tags: tags)),
    ));
    _subs.add(_correspondentRepository.labels.listen(
      (correspondents) => emit(state.copyWith(correspondents: correspondents)),
    ));
    _subs.add(_documentTypeRepository.labels.listen(
      (documentTypes) => emit(state.copyWith(documentTypes: documentTypes)),
    ));
  }

  Future<void> upload(
    Uint8List bytes, {
    required String filename,
    required String title,
    required void Function(DocumentModel document)? onConsumptionFinished,
    int? documentType,
    int? correspondent,
    Iterable<int> tags = const [],
    DateTime? createdAt,
  }) async {
    final auth = await _localVault.loadAuthenticationInformation();
    if (auth == null || !auth.isValid) {
      throw const PaperlessServerException(ErrorCode.notAuthenticated);
    }
    await _documentApi.create(
      bytes,
      filename: filename,
      title: title,
      correspondent: correspondent,
      documentType: documentType,
      tags: tags,
      createdAt: createdAt,
      authToken: auth.token!,
      serverUrl: auth.serverUrl,
    );
    if (onConsumptionFinished != null) {
      _documentApi
          .waitForConsumptionFinished(filename, title)
          .then((value) => onConsumptionFinished(value));
    }
  }

  @override
  Future<void> close() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    return super.close();
  }
}
