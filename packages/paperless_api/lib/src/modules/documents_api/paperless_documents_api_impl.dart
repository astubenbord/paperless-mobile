import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_api/src/constants.dart';

class PaperlessDocumentsApiImpl implements PaperlessDocumentsApi {
  final Dio client;

  PaperlessDocumentsApiImpl(this.client);

  @override
  Future<void> create(
    Uint8List documentBytes, {
    required String filename,
    required String title,
    String contentType = 'application/octet-stream',
    DateTime? createdAt,
    int? documentType,
    int? correspondent,
    Iterable<int> tags = const [],
  }) async {
    final formData = FormData()
      ..files.add(
        MapEntry(
          'document',
          MultipartFile.fromBytes(documentBytes, filename: filename),
        ),
      );

    formData.fields.add(MapEntry('title', title));
    if (createdAt != null) {
      formData.fields.add(MapEntry('created', apiDateFormat.format(createdAt)));
    }
    if (correspondent != null) {
      formData.fields.add(MapEntry('correspondent', jsonEncode(correspondent)));
    }
    if (documentType != null) {
      formData.fields.add(MapEntry('document_type', jsonEncode(documentType)));
    }
    for (final tag in tags) {
      formData.fields.add(MapEntry('tags', tag.toString()));
    }

    final response =
        await client.post('/api/documents/post_document/', data: formData);
    if (response.statusCode != 200) {
      throw PaperlessServerException(
        ErrorCode.documentUploadFailed,
        httpStatusCode: response.statusCode,
      );
    }
  }

  @override
  Future<DocumentModel> update(DocumentModel doc) async {
    final response = await client.put(
      "/api/documents/${doc.id}/",
      data: doc.toJson(),
    );
    if (response.statusCode == 200) {
      return DocumentModel.fromJson(response.data);
    } else {
      throw const PaperlessServerException(ErrorCode.documentUpdateFailed);
    }
  }

  @override
  Future<PagedSearchResult<DocumentModel>> find(DocumentFilter filter) async {
    final filterParams = filter.toQueryParameters();
    final response = await client.get(
      "/api/documents/",
      queryParameters: filterParams,
    );
    if (response.statusCode == 200) {
      return compute(
        PagedSearchResult.fromJson,
        PagedSearchResultJsonSerializer<DocumentModel>(
          response.data,
          DocumentModel.fromJson,
        ),
      );
    } else {
      throw const PaperlessServerException(ErrorCode.documentLoadFailed);
    }
  }

  @override
  Future<int> delete(DocumentModel doc) async {
    final response = await client.delete("/api/documents/${doc.id}/");

    if (response.statusCode == 204) {
      return Future.value(doc.id);
    }
    throw const PaperlessServerException(ErrorCode.documentDeleteFailed);
  }

  @override
  String getThumbnailUrl(int documentId) {
    return "/api/documents/$documentId/thumb/";
  }

  String getPreviewUrl(int documentId) {
    return "/api/documents/$documentId/preview/";
  }

  @override
  Future<Uint8List> getPreview(int documentId) async {
    final response = await client.get(
      getPreviewUrl(documentId),
      options: Options(
          responseType:
              ResponseType.bytes), //TODO: Check if bytes or stream is required
    );
    if (response.statusCode == 200) {
      return response.data;
    }
    throw const PaperlessServerException(ErrorCode.documentPreviewFailed);
  }

  @override
  Future<int> findNextAsn() async {
    const DocumentFilter asnQueryFilter = DocumentFilter(
      sortField: SortField.archiveSerialNumber,
      sortOrder: SortOrder.descending,
      asnQuery: IdQueryParameter.anyAssigned(),
      page: 1,
      pageSize: 1,
    );
    try {
      final result = await find(asnQueryFilter);
      return result.results
              .map((e) => e.archiveSerialNumber)
              .firstWhere((asn) => asn != null, orElse: () => 0)! +
          1;
    } on PaperlessServerException catch (_) {
      throw const PaperlessServerException(ErrorCode.documentAsnQueryFailed);
    }
  }

  @override
  Future<Iterable<int>> bulkAction(BulkAction action) async {
    final response = await client.post(
      "/api/documents/bulk_edit/",
      data: action.toJson(),
    );
    if (response.statusCode == 200) {
      return action.documentIds;
    } else {
      throw const PaperlessServerException(ErrorCode.documentBulkActionFailed);
    }
  }

  @override
  Future<DocumentModel> waitForConsumptionFinished(
      String fileName, String title) async {
    PagedSearchResult<DocumentModel> results =
        await find(DocumentFilter.latestDocument);

    while ((results.results.isEmpty ||
        (results.results[0].originalFileName != fileName &&
            results.results[0].title != title))) {
      //TODO: maybe implement more intelligent retry logic or find workaround for websocket authentication...
      await Future.delayed(const Duration(seconds: 2));
      results = await find(DocumentFilter.latestDocument);
    }
    try {
      return results.results.first;
    } on StateError {
      throw const PaperlessServerException(ErrorCode.documentUploadFailed);
    }
  }

  @override
  Future<Uint8List> download(DocumentModel document) async {
    //TODO: Add missing error handling
    final response = await client.get(
      "/api/documents/${document.id}/download/",
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }

  @override
  Future<DocumentMetaData> getMetaData(DocumentModel document) async {
    final response =
        await client.get("/api/documents/${document.id}/metadata/");
    return compute(
      DocumentMetaData.fromJson,
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<List<String>> autocomplete(String query, [int limit = 10]) async {
    final response = await client.get(
      '/api/search/autocomplete/',
      queryParameters: {
        'query': query,
        'limit': limit,
      },
    );
    if (response.statusCode == 200) {
      return response.data as List<String>;
    }
    throw const PaperlessServerException(ErrorCode.autocompleteQueryError);
  }

  @override
  Future<List<SimilarDocumentModel>> findSimilar(int docId) async {
    final response =
        await client.get("/api/documents/?more_like=$docId&pageSize=10");
    if (response.statusCode == 200) {
      return (await compute(
        PagedSearchResult<SimilarDocumentModel>.fromJson,
        PagedSearchResultJsonSerializer(
          response.data,
          SimilarDocumentModel.fromJson,
        ),
      ))
          .results;
    }
    throw const PaperlessServerException(ErrorCode.similarQueryError);
  }
}
