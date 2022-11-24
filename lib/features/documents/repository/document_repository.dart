import 'dart:typed_data';

import 'package:paperless_mobile/features/documents/model/bulk_edit.model.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/model/document_meta_data.model.dart';
import 'package:paperless_mobile/features/documents/model/paged_search_result.dart';
import 'package:paperless_mobile/features/documents/model/similar_document.model.dart';
import 'package:paperless_mobile/features/labels/tags/model/tag.model.dart';

abstract class DocumentRepository {
  Future<void> create(
    Uint8List documentBytes,
    String filename, {
    required String title,
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
