import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_api/src/constants.dart';

class PaperlessDocumentsApiImpl implements PaperlessDocumentsApi {
  final Dio client;

  PaperlessDocumentsApiImpl(this.client);

  @override
  Future<String?> create(
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
      )
      ..fields.add(MapEntry('title', title));
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
    try {
      final response =
          await client.post('/api/documents/post_document/', data: formData);
      if (response.statusCode == 200) {
        if (response.data is String && response.data != "OK") {
          return response.data;
        }
        return null;
      } else {
        throw PaperlessServerException(
          ErrorCode.documentUploadFailed,
          httpStatusCode: response.statusCode,
        );
      }
    } on DioError catch (err) {
      throw err.error;
    }
  }

  @override
  Future<DocumentModel> update(DocumentModel doc) async {
    try {
      final response = await client.put(
        "/api/documents/${doc.id}/",
        data: doc.toJson(),
      );
      if (response.statusCode == 200) {
        return DocumentModel.fromJson(response.data);
      } else {
        throw const PaperlessServerException(ErrorCode.documentUpdateFailed);
      }
    } on DioError catch (err) {
      throw err.error;
    }
  }

  @override
  Future<PagedSearchResult<DocumentModel>> findAll(
    DocumentFilter filter,
  ) async {
    final filterParams = filter.toQueryParameters()
      ..addAll({'truncate_content': "true"});
    try {
      final response = await client.get(
        "/api/documents/",
        queryParameters: filterParams,
      );
      if (response.statusCode == 200) {
        return compute(
          PagedSearchResult.fromJsonSingleParam,
          PagedSearchResultJsonSerializer<DocumentModel>(
            response.data,
            DocumentModelJsonConverter(),
          ),
        );
      } else {
        throw const PaperlessServerException(ErrorCode.documentLoadFailed);
      }
    } on DioError catch (err) {
      throw err.error;
    }
  }

  @override
  Future<int> delete(DocumentModel doc) async {
    try {
      final response = await client.delete("/api/documents/${doc.id}/");

      if (response.statusCode == 204) {
        return Future.value(doc.id);
      }
      throw const PaperlessServerException(ErrorCode.documentDeleteFailed);
    } on DioError catch (err) {
      throw err.error;
    }
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
    try {
      final response = await client.get(
        getPreviewUrl(documentId),
        options: Options(
            responseType: ResponseType
                .bytes), //TODO: Check if bytes or stream is required
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw const PaperlessServerException(ErrorCode.documentPreviewFailed);
    } on DioError catch (err) {
      throw err.error;
    }
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
      final result = await findAll(asnQueryFilter);
      return result.results
              .map((e) => e.archiveSerialNumber)
              .firstWhere((asn) => asn != null, orElse: () => 0)! +
          1;
    } on PaperlessServerException {
      throw const PaperlessServerException(ErrorCode.documentAsnQueryFailed);
    } on DioError catch (err) {
      throw err.error;
    }
  }

  @override
  Future<Iterable<int>> bulkAction(BulkAction action) async {
    try {
      final response = await client.post(
        "/api/documents/bulk_edit/",
        data: action.toJson(),
      );
      if (response.statusCode == 200) {
        return action.documentIds;
      } else {
        throw const PaperlessServerException(
          ErrorCode.documentBulkActionFailed,
        );
      }
    } on DioError catch (err) {
      throw err.error;
    }
  }

  @override
  Future<Uint8List> download(DocumentModel document) async {
    try {
      final response = await client.get(
        "/api/documents/${document.id}/download/",
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioError catch (err) {
      throw err.error;
    }
  }

  @override
  Future<DocumentMetaData> getMetaData(DocumentModel document) async {
    try {
      final response =
          await client.get("/api/documents/${document.id}/metadata/");
      return compute(
        DocumentMetaData.fromJson,
        response.data as Map<String, dynamic>,
      );
    } on DioError catch (err) {
      throw err.error;
    }
  }

  @override
  Future<List<String>> autocomplete(String query, [int limit = 10]) async {
    try {
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
    } on DioError catch (err) {
      throw err.error;
    }
  }

  @override
  Future<List<SimilarDocumentModel>> findSimilar(int docId) async {
    try {
      final response =
          await client.get("/api/documents/?more_like=$docId&pageSize=10");
      if (response.statusCode == 200) {
        return (await compute(
          PagedSearchResult<SimilarDocumentModel>.fromJsonSingleParam,
          PagedSearchResultJsonSerializer(
            response.data,
            SimilarDocumentModelJsonConverter(),
          ),
        ))
            .results;
      }
      throw const PaperlessServerException(ErrorCode.similarQueryError);
    } on DioError catch (err) {
      throw err.error;
    }
  }

  @override
  Future<FieldSuggestions> findSuggestions(DocumentModel document) async {
    try {
      final response =
          await client.get("/api/documents/${document.id}/suggestions/");
      if (response.statusCode == 200) {
        return FieldSuggestions.fromJson(response.data);
      }
      throw const PaperlessServerException(ErrorCode.suggestionsQueryError);
    } on DioError catch (err) {
      throw err.error;
    }
  }

  @override
  Future<DocumentModel?> find(int id) async {
    try {
      final response = await client.get("/api/documents/$id/");
      if (response.statusCode == 200) {
        return DocumentModel.fromJson(response.data);
      } else {
        return null;
      }
    } on DioError catch (err) {
      throw err.error;
    }
  }
}
