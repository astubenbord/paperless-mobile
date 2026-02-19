import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_api/src/constants.dart';
import 'package:paperless_api/src/extensions/dio_exception_extension.dart';

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
    int? asn,
    void Function(double progress)? onProgressChanged,
  }) async {
    final formData = FormData();
    formData.files.add(
      MapEntry(
        'document',
        MultipartFile.fromBytes(documentBytes, filename: filename),
      ),
    );
    formData.fields.add(MapEntry('title', title));

    if (createdAt != null) {
      formData.fields.add(
        MapEntry('created', apiDateFormat.format(createdAt)),
      );
    }
    if (correspondent != null) {
      formData.fields.add(MapEntry('correspondent', jsonEncode(correspondent)));
    }
    if (documentType != null) {
      formData.fields.add(MapEntry('document_type', jsonEncode(documentType)));
    }
    if (asn != null) {
      formData.fields.add(MapEntry('archive_serial_number', jsonEncode(asn)));
    }
    for (final tag in tags) {
      formData.fields.add(MapEntry('tags', tag.toString()));
    }
    try {
      final response = await client.post(
        '/api/documents/post_document/',
        data: formData,
        onSendProgress: (count, total) {
          onProgressChanged?.call(count.toDouble() / total.toDouble());
        },
        options: Options(validateStatus: (status) => status == 200),
      );
      if (response.data != "OK") {
        return response.data as String;
      } else {
        return null;
      }
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.documentUploadFailed),
      );
    }
  }

  @override
  Future<DocumentModel> update(DocumentModel doc) async {
    // Only send fields that are writable via the Paperless-ngx API.
    // Sending read-only fields (id, added, modified, owner, permissions, etc.)
    // causes the server to reject the request on newer API versions.
    final updatePayload = {
      'title': doc.title,
      'content': doc.content,
      'tags': doc.tags.toList(),
      'document_type': doc.documentType,
      'correspondent': doc.correspondent,
      'storage_path': doc.storagePath,
      'archive_serial_number': doc.archiveSerialNumber,
      'custom_fields': doc.customFields
          .map((cf) => {'field': cf.id, 'value': cf.value})
          .toList(),
      'created': doc.created.toUtc().toIso8601String(),
      if (doc.owner != null) 'owner': doc.owner,
      if (doc.permissions != null)
        'set_permissions': {
          'view': {
            'users': doc.permissions!.view.users,
            'groups': doc.permissions!.view.groups,
          },
          'change': {
            'users': doc.permissions!.change.users,
            'groups': doc.permissions!.change.groups,
          },
        },
    };
    try {
      final response = await client.put(
        "/api/documents/${doc.id}/",
        data: updatePayload,
        options: Options(validateStatus: (status) => status == 200),
      );
      return DocumentModel.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.documentUpdateFailed),
      );
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
        options: Options(validateStatus: (status) => status == 200),
      );
      return compute(
        PagedSearchResult.fromJsonSingleParam,
        PagedSearchResultJsonSerializer<DocumentModel>(
          response.data,
          DocumentModelJsonConverter(),
        ),
      );
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: PaperlessApiException(
          ErrorCode.documentLoadFailed,
          details: exception.message,
        ),
      );
    }
  }

  @override
  Future<int> delete(DocumentModel doc) async {
    try {
      await client.delete(
        "/api/documents/${doc.id}/",
        options: Options(validateStatus: (status) => status == 204),
      );

      return Future.value(doc.id);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.documentDeleteFailed),
      );
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
          responseType: ResponseType.bytes,
          validateStatus: (status) => status == 200,
        ), //TODO: Check if bytes or stream is required
      );
      return response.data;
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.documentPreviewFailed),
      );
    }
  }

  @override
  Future<int> findNextAsn() async {
    const DocumentFilter asnQueryFilter = DocumentFilter(
      sortField: SortField.archiveSerialNumber,
      sortOrder: SortOrder.descending,
      asnQuery: AnyAssignedIdQueryParameter(),
      page: 1,
      pageSize: 1,
    );
    try {
      final result = await findAll(asnQueryFilter);
      return result.results
              .map((e) => e.archiveSerialNumber)
              .firstWhere((asn) => asn != null, orElse: () => 0)! +
          1;
    } on PaperlessApiException {
      throw const PaperlessApiException(ErrorCode.documentAsnQueryFailed);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.documentAsnQueryFailed),
      );
    }
  }

  @override
  Future<Iterable<int>> bulkAction(BulkAction action) async {
    try {
      await client.post(
        "/api/documents/bulk_edit/",
        data: action.toJson(),
        options: Options(validateStatus: (status) => status == 200),
      );
      return action.documentIds;
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(
          ErrorCode.documentBulkActionFailed,
        ),
      );
    }
  }

  @override
  Future<Uint8List> downloadDocument(
    int id, {
    bool original = false,
  }) async {
    try {
      final response = await client.get(
        "/api/documents/$id/download/",
        queryParameters: {'original': original},
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException.unknown(),
      );
    }
  }

  @override
  Future<void> downloadToFile(
    int id,
    String localFilePath, {
    bool original = false,
    void Function(double)? onProgressChanged,
  }) async {
    try {
      final response = await client.download(
        "/api/documents/$id/download/",
        localFilePath,
        onReceiveProgress: (count, total) =>
            onProgressChanged?.call(count / total),
        queryParameters: {'original': original},
      );
      return response.data;
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException.unknown(),
      );
    }
  }

  @override
  Future<DocumentMetaData> getMetaData(int id) async {
    debugPrint("Fetching data for /api/documents/$id/metadata/...");

    try {
      final response = await client.get(
        "/api/documents/$id/metadata/",
        options: Options(
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );
      debugPrint("Fetched data for /api/documents/$id/metadata/.");

      return DocumentMetaData.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException.unknown(),
      );
    }
  }

  @override
  Future<List<String>> autocomplete(String query, [int limit = 10]) async {
    try {
      final response = await client.get(
        '/api/search/autocomplete/',
        queryParameters: {
          'term': query,
          'limit': limit,
        },
        options: Options(validateStatus: (status) => status == 200),
      );
      return (response.data as List).cast<String>();
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(
          ErrorCode.autocompleteQueryError,
        ),
      );
    }
  }

  @override
  Future<FieldSuggestions> findSuggestions(DocumentModel document) async {
    try {
      final response = await client.get(
        "/api/documents/${document.id}/suggestions/",
        options: Options(validateStatus: (status) => status == 200),
      );
      return FieldSuggestions.fromJson(response.data)
          .forDocumentId(document.id);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.suggestionsQueryError),
      );
    }
  }

  @override
  Future<DocumentModel> find(int id) async {
    debugPrint("Fetching data from /api/documents/$id/...");
    try {
      final response = await client.get(
        "/api/documents/$id/",
        options: Options(
          validateStatus: (status) => status == 200,
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );
      debugPrint("Fetched data for /api/documents/$id/.");
      return DocumentModel.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException.unknown(),
      );
    }
  }

  @override
  Future<DocumentModel> deleteNote(DocumentModel document, int noteId) async {
    try {
      final response = await client.delete(
        "/api/documents/${document.id}/notes/?id=$noteId",
        options: Options(validateStatus: (status) => status == 200),
      );
      final notes =
          (response.data as List).map((e) => NoteModel.fromJson(e)).toList();

      return document.copyWith(notes: notes);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.deleteNoteFailed),
      );
    }
  }

  @override
  Future<DocumentModel> addNote({
    required DocumentModel document,
    required String text,
  }) async {
    try {
      final response = await client.post(
        "/api/documents/${document.id}/notes/",
        options: Options(validateStatus: (status) => status == 200),
        data: {'note': text},
      );

      final notes =
          (response.data as List).map((e) => NoteModel.fromJson(e)).toList();

      return document.copyWith(notes: notes);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.addNoteFailed),
      );
    }
  }
}
