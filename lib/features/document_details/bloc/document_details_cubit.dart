import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/repository/document_repository.dart';

part 'document_details_state.dart';

class DocumentDetailsCubit extends Cubit<DocumentDetailsState> {
  final DocumentRepository _documentRepository;

  DocumentDetailsCubit(this._documentRepository, DocumentModel initialDocument)
      : super(DocumentDetailsState(document: initialDocument));

  Future<void> delete(DocumentModel document) async {
    await _documentRepository.delete(document);
    emit(const DocumentDetailsState());
  }

  Future<void> update(DocumentModel document) async {
    final updatedDocument = await _documentRepository.update(document);
    emit(DocumentDetailsState(document: updatedDocument));
  }

  Future<void> assignAsn(DocumentModel document) async {
    if (document.archiveSerialNumber == null) {
      final int asn = await _documentRepository.findNextAsn();
      update(document.copyWith(archiveSerialNumber: asn));
    }
  }
}
