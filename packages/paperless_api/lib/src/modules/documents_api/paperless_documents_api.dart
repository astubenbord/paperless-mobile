import 'dart:typed_data';

import 'package:paperless_api/src/models/bulk_edit_model.dart';
import 'package:paperless_api/src/models/document_filter.dart';
import 'package:paperless_api/src/models/document_meta_data_model.dart';
import 'package:paperless_api/src/models/document_model.dart';
import 'package:paperless_api/src/models/paged_search_result.dart';
import 'package:paperless_api/src/models/similar_document_model.dart';

abstract class PaperlessDocumentsApi {
  Future<void> create(
    Uint8List documentBytes, {
    required String filename,
    required String title,
    required String authToken,
    required String serverUrl,
    int? documentType,
    int? correspondent,
    Iterable<int> tags = const [],
    DateTime? createdAt,
  });
  Future<DocumentModel> update(DocumentModel doc);
  Future<int> findNextAsn();
  Future<PagedSearchResult<DocumentModel>> find(DocumentFilter filter);
  Future<List<SimilarDocumentModel>> findSimilar(int docId);
  Future<int> delete(DocumentModel doc);
  Future<DocumentMetaData> getMetaData(DocumentModel document);
  Future<Iterable<int>> bulkAction(BulkAction action);
  Future<Uint8List> getPreview(int docId);
  String getThumbnailUrl(int docId);
  Future<DocumentModel> waitForConsumptionFinished(
      String filename, String title);
  Future<Uint8List> download(DocumentModel document);

  Future<List<String>> autocomplete(String query, [int limit = 10]);
}
