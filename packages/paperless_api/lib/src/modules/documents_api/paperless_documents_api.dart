import 'dart:typed_data';

import 'package:paperless_api/src/models/models.dart';

abstract class PaperlessDocumentsApi {
  /// Uploads a document using a form data request and from server version 1.11.3
  /// returns the celery task id which can be used to track the status of the document.
  Future<String?> create(
    Uint8List documentBytes, {
    required String filename,
    required String title,
    DateTime? createdAt,
    int? documentType,
    int? correspondent,
    Iterable<int> tags = const [],
  });
  Future<DocumentModel> update(DocumentModel doc);
  Future<int> findNextAsn();
  Future<PagedSearchResult<DocumentModel>> findAll(DocumentFilter filter);
  Future<DocumentModel?> find(int id);
  Future<List<SimilarDocumentModel>> findSimilar(int docId);
  Future<int> delete(DocumentModel doc);
  Future<DocumentMetaData> getMetaData(DocumentModel document);
  Future<Iterable<int>> bulkAction(BulkAction action);
  Future<Uint8List> getPreview(int docId);
  String getThumbnailUrl(int docId);
  Future<Uint8List> download(DocumentModel document);
  Future<FieldSuggestions> findSuggestions(DocumentModel document);

  Future<List<String>> autocomplete(String query, [int limit = 10]);
}
