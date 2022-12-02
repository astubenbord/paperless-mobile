import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:paperless_api/paperless_api.dart';

part 'document_details_state.dart';

class DocumentDetailsCubit extends Cubit<DocumentDetailsState> {
  final PaperlessDocumentsApi _api;

  DocumentDetailsCubit(this._api, DocumentModel initialDocument)
      : super(DocumentDetailsState(document: initialDocument));

  Future<void> delete(DocumentModel document) async {
    await _api.delete(document);
    emit(const DocumentDetailsState());
  }

  Future<void> update(DocumentModel document) async {
    final updatedDocument = await _api.update(document);
    emit(DocumentDetailsState(document: updatedDocument));
  }

  Future<void> assignAsn(DocumentModel document) async {
    if (document.archiveSerialNumber == null) {
      final int asn = await _api.findNextAsn();
      update(document.copyWith(archiveSerialNumber: asn));
    }
  }
}
