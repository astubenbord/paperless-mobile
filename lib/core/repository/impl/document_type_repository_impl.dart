import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;

class DocumentTypeRepositoryImpl implements LabelRepository<DocumentType> {
  final PaperlessLabelsApi _api;

  final _subject = BehaviorSubject<Map<int, DocumentType>>.seeded(const {});

  DocumentTypeRepositoryImpl(this._api);

  @override
  Stream<Map<int, DocumentType>> get labels =>
      _subject.stream.asBroadcastStream();

  @override
  Future<DocumentType> create(DocumentType documentType) async {
    final created = await _api.saveDocumentType(documentType);
    final updatedState = {..._subject.value}
      ..putIfAbsent(created.id!, () => created);
    _subject.add(updatedState);
    return created;
  }

  @override
  Future<void> delete(DocumentType documentType) async {
    await _api.deleteDocumentType(documentType);
    final updatedState = {..._subject.value}
      ..removeWhere((k, v) => k == documentType.id);
    _subject.add(updatedState);
  }

  @override
  Future<DocumentType?> find(int id) async {
    final documentType = await _api.getDocumentType(id);
    if (documentType != null) {
      final updatedState = {..._subject.value}..[id] = documentType;
      _subject.add(updatedState);
      return documentType;
    }
    return null;
  }

  @override
  Future<Iterable<DocumentType>> findAll([Iterable<int>? ids]) async {
    final documentTypes = await _api.getDocumentTypes(ids);
    final updatedState = {..._subject.value}
      ..addEntries(documentTypes.map((e) => MapEntry(e.id!, e)));
    _subject.add(updatedState);
    return documentTypes;
  }

  @override
  Future<DocumentType> update(DocumentType documentType) async {
    final updated = await _api.updateDocumentType(documentType);
    final updatedState = {..._subject.value}
      ..update(updated.id!, (_) => updated);
    _subject.add(updatedState);
    return updated;
  }

  @override
  void clear() {
    _subject.add(const {});
  }

  @override
  Map<int, DocumentType> get current => _subject.value;
}
