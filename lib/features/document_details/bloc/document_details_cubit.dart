import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:paperless_api/paperless_api.dart';

part 'document_details_state.dart';

class DocumentDetailsCubit extends Cubit<DocumentDetailsState> {
  final PaperlessDocumentsApi _api;

  DocumentDetailsCubit(this._api, DocumentModel initialDocument)
      : super(DocumentDetailsState(document: initialDocument)) {
    loadSuggestions();
  }

  Future<void> delete(DocumentModel document) async {
    await _api.delete(document);
  }

  Future<void> loadSuggestions() async {
    final suggestions = await _api.findSuggestions(state.document);
    emit(state.copyWith(suggestions: suggestions));
  }

  Future<void> loadFullContent() async {
    final doc = await _api.find(state.document.id);
    if (doc == null) {
      return;
    }
    emit(state.copyWith(
      isFullContentLoaded: true,
      fullContent: doc.content,
    ));
  }

  Future<void> assignAsn(DocumentModel document) async {
    if (document.archiveSerialNumber == null) {
      final int asn = await _api.findNextAsn();
      final updatedDocument =
          await _api.update(document.copyWith(archiveSerialNumber: asn));
      emit(state.copyWith(document: updatedDocument));
    }
  }

  void replaceDocument(DocumentModel document) {
    emit(state.copyWith(document: document));
  }
}
