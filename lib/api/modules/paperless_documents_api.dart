import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:paperless_mobile/api/constants/api_date_format.dart';
import 'package:paperless_mobile/api/extensions/extensions.dart';
import 'package:paperless_mobile/api/models/models.dart';

abstract class PaperlessDocumentsApi {
  Future<String> create(
    Uint8List documentBytes, {
    required String filename,
    String? title,
    DateTime? createdAt,
    int? documentType,
    int? correspondent,
    int? storagePath,
    Iterable<int> customFields = const [],
    Iterable<int> tags = const [],
    int? archiveSerialNumber,
    void Function(double progress)? onProgressChanged,
  });
  Future<PaginatedResultList<Document>> getAll(
    DocumentFilter? options, {
    bool truncateContent = true,
  });
  Future<Document> get(int id, {List<String>? fields});
  Future<Document> put(int id, DocumentRequest document);
  Future<Document> patch(int id, PatchedDocumentRequest document);
  Future<void> delete(int id);
  Future<Metadata> getMetaData(int id);
  Future<PaginatedResultList<LogEntry>> getLogs(
    int id, {
    int? page,
    int? pageSize,
  });
  Future<List<Note>> getNotes(int id, {int? page, int? pageSize});
  Future<List<Note>> addNote(int documentId, String note);
  Future<List<Note>> deleteNote(int documentId, int noteId);
  String getPreviewUrl(int id);
  Future<Uint8List> getPreview(int documentId);
  Future<Iterable<ShareLink>> getShareLinks(int documentId);
  Future<Suggestions> getFieldSuggestions(int documentId);
  String getThumbnailUrl(int documentId);
  Future<BulkDownload> bulkDownload(BulkDownloadRequest request);
  Future<BulkEditDocumentsResult> bulkEditDocuments(BulkEditRequest request);
  Future<int> getNextAsn();
  Future<Iterable<int>> bulkAction(BulkEditRequest action);
  Future<SelectionData> getSelectionData(Iterable<int> documentIds);
  Future<Uint8List> downloadDocument(int id, {bool original});

  Future<void> downloadToFile(
    int id,
    String localFilePath, {
    bool original = false,
    void Function(double progress)? onProgressChanged,
  });
}

class PaperlessDocumentsApiImpl implements PaperlessDocumentsApi {
  final Dio client;

  PaperlessDocumentsApiImpl(this.client);

  @override
  Future<String> create(
    Uint8List documentBytes, {
    required String filename,
    String? title,
    DateTime? createdAt,
    int? documentType,
    int? correspondent,
    int? storagePath,
    Iterable<int> customFields = const [],
    Iterable<int> tags = const [],
    int? archiveSerialNumber,
    void Function(double progress)? onProgressChanged,
  }) async {
    final formData = FormData();
    formData.files.add(
      MapEntry(
        'document',
        MultipartFile.fromBytes(documentBytes, filename: filename),
      ),
    );

    formData.fields.addAll([
      if (title != null) MapEntry('title', title),
      if (storagePath != null)
        MapEntry('storage_path', jsonEncode(storagePath)),
      if (createdAt != null)
        MapEntry('created', apiDateFormat.format(createdAt)),
      if (correspondent != null)
        MapEntry('correspondent', jsonEncode(correspondent)),
      if (documentType != null)
        MapEntry('document_type', jsonEncode(documentType)),
      if (storagePath != null)
        MapEntry('storage_path', jsonEncode(storagePath)),
      if (archiveSerialNumber != null)
        MapEntry('archive_serial_number', jsonEncode(archiveSerialNumber)),
      for (final tag in tags) MapEntry('tags', tag.toString()),
      for (final field in customFields)
        MapEntry('custom_fields', field.toString()),
    ]);

    try {
      final response = await client.post<String>(
        '/api/documents/post_document/',
        data: formData,
        options: Options(sendTimeout: 60.seconds),
        onSendProgress: (count, total) {
          onProgressChanged?.call(count.toDouble() / total.toDouble());
        },
      );
      return response.data!;
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.documentUploadFailed),
      );
    }
  }

  @override
  Future<Document> put(int id, DocumentRequest request) async {
    try {
      final response = await client.put(
        "/api/documents/$id/",
        data: request.toJson(),
      );
      return Document.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.documentUpdateFailed),
      );
    }
  }

  @override
  Future<Document> patch(int id, PatchedDocumentRequest request) async {
    final data = request.toJson();
    try {
      final response = await client.patch("/api/documents/$id/", data: data);
      return Document.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.documentUpdateFailed),
      );
    }
  }

  @override
  Future<PaginatedResultList<Document>> getAll(
    DocumentFilter? options, {
    bool truncateContent = true,
  }) async {
    final filterParams = options?.toQueryParameters() ?? {}
      ..['truncate_content'] = truncateContent.toString();
    try {
      final response = await client.get(
        "/api/documents/",
        queryParameters: filterParams,
      );
      return PaginatedResultList<Document>.fromJson(
        response.data,
        (arg) => Document.fromJson(arg),
      );
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: PaperlessApiException(
          ErrorCode.documentLoadFailed,
          details: exception.message,
        ),
      );
    } catch (exception) {
      throw PaperlessApiException(
        ErrorCode.documentLoadFailed,
        details: exception.toString(),
      );
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      await client.delete("/api/documents/$id/");

      return Future.value(id);
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

  @override
  String getPreviewUrl(int documentId) {
    return "/api/documents/$documentId/preview/";
  }

  @override
  Future<Uint8List> getPreview(int documentId) async {
    try {
      final response = await client.get(
        getPreviewUrl(documentId),
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.documentPreviewFailed),
      );
    }
  }

  @override
  Future<int> getNextAsn() async {
    try {
      final response = await client.get<int>("/api/documents/next_asn/");
      return response.data!;
    } on PaperlessApiException {
      throw const PaperlessApiException(ErrorCode.documentAsnQueryFailed);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.documentAsnQueryFailed),
      );
    }
  }

  @override
  Future<Iterable<int>> bulkAction(BulkEditRequest action) async {
    try {
      await client.post("/api/documents/bulk_edit/", data: action.toJson());
      return action.documents;
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.documentBulkActionFailed),
      );
    }
  }

  @override
  Future<Uint8List> downloadDocument(int id, {bool original = false}) async {
    try {
      final response = await client.get(
        "/api/documents/$id/download/",
        queryParameters: {'original': original},
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException catch (exception) {
      throw exception.unravel(orElse: const PaperlessApiException.unknown());
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
      await client.download(
        "/api/documents/$id/download/",
        localFilePath,
        onReceiveProgress: (count, total) =>
            onProgressChanged?.call(count.toDouble() / total.toDouble()),
        queryParameters: {'original': original},
      );
    } on DioException catch (exception) {
      throw exception.unravel(orElse: const PaperlessApiException.unknown());
    }
  }

  @override
  Future<Metadata> getMetaData(int id) async {
    try {
      final response = await client.get(
        "/api/documents/$id/metadata/",
        options: Options(
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );

      return Metadata.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(orElse: const PaperlessApiException.unknown());
    }
  }

  @override
  Future<Document> get(int id, {List<String>? fields}) async {
    try {
      final response = await client.get(
        "/api/documents/$id/",
        queryParameters: {
          if (fields != null) 'fields': fields.join(','),
          'full_perms': 'true',
        },
        options: Options(
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );
      return Document.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(orElse: const PaperlessApiException.unknown());
    }
  }

  @override
  Future<List<Note>> deleteNote(int documentId, int noteId) async {
    try {
      final response = await client.delete<List<dynamic>>(
        "/api/documents/$documentId/notes/",
        queryParameters: {'id': noteId},
      );
      return response.data?.map((e) => Note.fromJson(e)).toList() ?? [];
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.deleteNoteFailed),
      );
    }
  }

  @override
  Future<List<Note>> addNote(int documentId, String text) async {
    try {
      final response = await client.post<List<dynamic>>(
        "/api/documents/$documentId/notes/",
        data: {'note': text},
      );
      return response.data?.map((e) => Note.fromJson(e)).toList() ?? [];
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.addNoteFailed),
      );
    }
  }

  @override
  Future<BulkDownload> bulkDownload(BulkDownloadRequest request) async {
    try {
      final response = await client.post(
        "/api/documents/bulk_download/",
        data: request.toJson(),
      );
      return BulkDownload.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.bulkDownloadFailed),
      );
    }
  }

  @override
  Future<BulkEditDocumentsResult> bulkEditDocuments(
    BulkEditRequest request,
  ) async {
    try {
      final response = await client.post(
        "/api/documents/bulk_edit/",
        data: request.toJson(),
      );
      return BulkEditDocumentsResult.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.bulkEditDocumentsFailed),
      );
    }
  }

  @override
  Future<Suggestions> getFieldSuggestions(int documentId) async {
    try {
      final response = await client.get(
        "/api/documents/$documentId/suggestions/",
      );
      return Suggestions.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(orElse: const PaperlessApiException.unknown());
    }
  }

  @override
  Future<PaginatedResultList<LogEntry>> getLogs(
    int id, {
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await client.get(
        "/api/documents/$id/logs/",
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return PaginatedResultList.fromJson(
        response.data,
        (json) => LogEntry.fromJson(json),
      );
    } on DioException catch (exception) {
      throw exception.unravel(orElse: const PaperlessApiException.unknown());
    }
  }

  @override
  Future<List<Note>> getNotes(int id, {int? page, int? pageSize}) async {
    try {
      final response = await client.get<List<dynamic>>(
        "/api/documents/$id/notes/",
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return response.data?.map((e) => Note.fromJson(e)).toList() ?? [];
    } on DioException catch (exception) {
      throw exception.unravel(orElse: const PaperlessApiException.unknown());
    }
  }

  @override
  Future<SelectionData> getSelectionData(Iterable<int> documentIds) async {
    try {
      final response = await client.post(
        "/api/documents/selection_data/",
        data: {'document_ids': documentIds.toList()},
      );
      return SelectionData.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(orElse: const PaperlessApiException.unknown());
    }
  }

  @override
  Future<Iterable<ShareLink>> getShareLinks(int documentId) async {
    try {
      final response = await client.get<List<dynamic>>(
        "/api/documents/$documentId/share_links/",
      );
      return response.data?.map((e) => ShareLink.fromJson(e)) ?? [];
    } on DioException catch (exception) {
      throw exception.unravel(orElse: const PaperlessApiException.unknown());
    }
  }
}
