import 'package:flutter/foundation.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:paperless_mobile/features/labels/document_type/model/document_type.model.dart';
import 'package:injectable/injectable.dart';

@singleton
class DocumentTypeCubit extends LabelCubit<DocumentType> {
  DocumentTypeCubit(super.metaDataService);

  @override
  Future<void> initialize() async {
    labelRepository.getDocumentTypes().then(loadFrom);
  }

  @override
  Future<DocumentType> save(DocumentType item) =>
      labelRepository.saveDocumentType(item);

  @override
  Future<DocumentType> update(DocumentType item) =>
      labelRepository.updateDocumentType(item);

  @override
  Future<int> delete(DocumentType item) =>
      labelRepository.deleteDocumentType(item);
}
