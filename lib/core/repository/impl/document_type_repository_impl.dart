import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/document_type_repository_state.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;

class DocumentTypeRepositoryImpl
    extends LabelRepository<DocumentType, DocumentTypeRepositoryState> {
  final PaperlessLabelsApi _api;

  DocumentTypeRepositoryImpl(this._api)
      : super(const DocumentTypeRepositoryState());

  @override
  Future<DocumentType> create(DocumentType documentType) async {
    final created = await _api.saveDocumentType(documentType);
    final updatedState = {...state.values}
      ..putIfAbsent(created.id!, () => created);
    emit(DocumentTypeRepositoryState(values: updatedState, hasLoaded: true));
    return created;
  }

  @override
  Future<int> delete(DocumentType documentType) async {
    await _api.deleteDocumentType(documentType);
    final updatedState = {...state.values}
      ..removeWhere((k, v) => k == documentType.id);
    emit(DocumentTypeRepositoryState(values: updatedState, hasLoaded: true));
    return documentType.id!;
  }

  @override
  Future<DocumentType?> find(int id) async {
    final documentType = await _api.getDocumentType(id);
    if (documentType != null) {
      final updatedState = {...state.values}..[id] = documentType;
      emit(DocumentTypeRepositoryState(values: updatedState, hasLoaded: true));
      return documentType;
    }
    return null;
  }

  @override
  Future<Iterable<DocumentType>> findAll([Iterable<int>? ids]) async {
    final documentTypes = await _api.getDocumentTypes(ids);
    final updatedState = {...state.values}
      ..addEntries(documentTypes.map((e) => MapEntry(e.id!, e)));
    emit(DocumentTypeRepositoryState(values: updatedState, hasLoaded: true));
    return documentTypes;
  }

  @override
  Future<DocumentType> update(DocumentType documentType) async {
    final updated = await _api.updateDocumentType(documentType);
    final updatedState = {...state.values}..update(updated.id!, (_) => updated);
    emit(DocumentTypeRepositoryState(values: updatedState, hasLoaded: true));
    return updated;
  }

  @override
  DocumentTypeRepositoryState fromJson(Map<String, dynamic> json) {
    return DocumentTypeRepositoryState.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(DocumentTypeRepositoryState state) {
    return state.toJson();
  }
}
