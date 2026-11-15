import 'dart:typed_data';

import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/document_extensions.dart';
import 'package:paperless_mobile/core/repository/change_notifier_mixin.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:path/path.dart' as p;

class AssignAsnRequest {
  final int? asn;
  final bool auto;

  AssignAsnRequest({this.asn, required this.auto});
}

class DocumentRepository with ChangeNotifierMixin {
  final PaperlessDocumentsApi _api;
  final Set<String> _cachedDocumentQueriesToInvalidate = {};

  DocumentRepository(this._api);

  String queryKeyForFilter(DocumentFilter? filter, [String? overrideKey]) {
    if (overrideKey != null) {
      return overrideKey;
    }
    final key = filter?.copyWith(page: 1).hashCode.toString() ?? 'unset_filter';
    return 'documents/$key';
  }

  /// Gets an infinite query for documents with optional filtering.
  /// [key] is the unique key for the query, e.g. the screen where the query is executed.
  /// [filter] is an optional DocumentFilter to apply.
  InfiniteQuery<PaginatedResultList<Document>, int> getAllQuery({
    DocumentFilter? filter,
    String? overrideKey,
  }) {
    // Page is always set to 1 to ensure it does not alter the cache key.
    final queryKey = queryKeyForFilter(filter, overrideKey);
    return InfiniteQuery<PaginatedResultList<Document>, int>(
      key: queryKey,
      queryFn: (page) async {
        try {
          final response = await _api.getAll(
            (filter ?? DocumentFilter()).copyWith(page: page, pageSize: 25),
          );
          return response;
        } catch (e) {
          rethrow;
        }
      },
      onSuccess: (data) {
        _cachedDocumentQueriesToInvalidate.add(queryKey);
        debugPrint(
          'Cached document queries to invalidate: $_cachedDocumentQueriesToInvalidate',
        );
      },
      getNextArg: (state) {
        final lastPage = state?.lastPage;
        if (lastPage == null) {
          return 1;
        }
        if (lastPage.next == null) {
          return null;
        }
        return state!.args.last + 1;
      },
    );
  }

  Mutation<List<Note>, String> addNoteMutation(int documentId) {
    return Mutation<List<Note>, String>(
      key: 'add_note/$documentId',
      mutationFn: (arg) {
        return _api.addNote(documentId, arg);
      },
      onSuccess: (res, arg) {
        final documentQuery = getDocumentQuery(documentId);
        if (documentQuery.state.data != null) {
          documentQuery.update((old) => old!.copyWith(notes: res));
        }
        getAllNotesQuery(documentId).update((_) => res);
      },
    );
  }

  Mutation<List<Note>, void> deleteNoteMutation(int documentId, int noteId) {
    return Mutation<List<Note>, void>(
      key: 'delete_note/$documentId/$noteId',
      mutationFn: (_) {
        return _api.deleteNote(documentId, noteId);
      },
      onSuccess: (res, arg) {
        final documentQuery = getDocumentQuery(documentId);
        if (documentQuery.state.data != null) {
          documentQuery.update((old) => old!.copyWith(notes: res));
        }
        getAllNotesQuery(documentId).update((_) => res);
      },
      // refetchQueries: ['document_notes/$documentId'],
    );
  }

  Mutation<Iterable<int>, BulkEditRequest> bulkActionMutation() {
    return Mutation<Iterable<int>, BulkEditRequest>(
      key: 'bulk_edit_documents',
      mutationFn: (arg) {
        return _api.bulkAction(arg);
      },
      refetchQueries: [..._cachedDocumentQueriesToInvalidate],
    );
  }

  Future<BulkDownload> bulkDownload(BulkDownloadRequest request) {
    return _api.bulkDownload(request);
  }

  Mutation<int?, AssignAsnRequest> assignAsnMutation(int documentId) {
    return Mutation<int?, AssignAsnRequest>(
      key: 'assign_asn/$documentId',
      mutationFn: (request) async {
        var nextAsn = request.asn;
        if (request.auto) {
          final asnResponse = await getNextAsnQuery().fetch();
          if (asnResponse.isError) {
            throw PaperlessApiException(ErrorCode.documentAsnQueryFailed);
          }
          nextAsn = asnResponse.data;
        }
        final response = await patchDocumentMutation(documentId).mutate(
          PatchedDocumentRequest(archiveSerialNumber: PatchedValue(nextAsn)),
        );
        if (response.isError && response.data == null) {
          throw PaperlessApiException(ErrorCode.documentUpdateFailed);
        }
        return response.data!.archiveSerialNumber;
      },
      onSuccess: (res, arg) {
        final query = CachedQuery.instance.getQuery<Query<Document>>(
          getDocumentQuery(documentId).key,
        );
        if (query == null || query.state.data == null) {
          return;
        }
        query.update(
          (currentData) => currentData!.copyWith(archiveSerialNumber: res),
        );
      },
      invalidateQueries: [
        'next_asn',
        'document/$documentId',
        ..._cachedDocumentQueriesToInvalidate,
      ],
    );
  }

  Mutation<BulkEditDocumentsResult, BulkEditRequest>
      bulkEditDocumentsMutation() {
    return Mutation<BulkEditDocumentsResult, BulkEditRequest>(
      key: 'bulk_edit_documents',
      mutationFn: (arg) {
        return _api.bulkEditDocuments(arg);
      },
      onSuccess: (res, arg) {
        for (final id in arg.documents) {
          final query = CachedQuery.instance.getQuery<Query<Document>>(
            'document/$id',
          );
          query?.invalidate();
        }
        notifyChangeListeners(ChangeType.update);
      },
      invalidateQueries: [..._cachedDocumentQueriesToInvalidate],
    );
  }

  Mutation<String?, void> createDocumentMutation(
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
  }) {
    return Mutation<String?, void>(
      key: 'create_document/$filename',
      mutationFn: (_) {
        return _api.create(
          documentBytes,
          filename: filename,
          title: title,
          createdAt: createdAt,
          documentType: documentType,
          correspondent: correspondent,
          storagePath: storagePath,
          customFields: customFields,
          tags: tags,
          archiveSerialNumber: archiveSerialNumber,
          onProgressChanged: onProgressChanged,
        );
      },
    );
  }

  Mutation<void, void> deleteDocumentMutation(int id) {
    return Mutation<void, void>(
      key: 'delete_document/$id',
      mutationFn: (_) {
        return _api.delete(id);
      },
      onSuccess: (res, arg) {
        notifyChangeListeners(ChangeType.delete);
      },
      invalidateQueries: [
        'document/$id',
        'field_suggestions/$id',
        ..._cachedDocumentQueriesToInvalidate,
      ],
    );
  }

  Query<Uint8List> downloadDocumentQuery(int id, {required bool original}) {
    return Query<Uint8List>(
      key: 'download_document/$id/$original',
      queryFn: () {
        return _api.downloadDocument(id, original: original);
      },
    );
  }

  Query<Document> getDocumentQuery(int id, {List<String>? fields}) {
    return Query<Document>(
      key: 'document/$id',
      queryFn: () {
        return _api.get(id, fields: fields);
      },
    );
  }

  Query<Suggestions> getFieldSuggestionsQuery(int documentId) {
    return Query(
      key: 'field_suggestions/$documentId',
      queryFn: () async {
        final result = await _api.getFieldSuggestions(documentId);
        return result;
      },
    );
  }

  InfiniteQuery<PaginatedResultList<LogEntry>, int> getLogsQuery(
    int id, {
    int? pageSize,
  }) {
    return InfiniteQuery<PaginatedResultList<LogEntry>, int>(
      key: 'document_logs/$id',
      queryFn: (page) async {
        return _api.getLogs(id, page: page, pageSize: pageSize);
      },
      getNextArg: (state) {
        if (state == null) return 1;
        final currentCount = state.args.length * (pageSize ?? 20);
        final totalCount = state.lastPage?.count ?? 0;
        if (currentCount >= totalCount) {
          return null;
        }
        return state.args.last + 1;
      },
    );
  }

  Query<Metadata> getMetaDataQuery(int id) {
    return Query<Metadata>(
      key: 'document_metadata/$id',
      queryFn: () {
        return _api.getMetaData(id);
      },
    );
  }

  Query<int> getNextAsnQuery() {
    return Query(key: 'next_asn', queryFn: _api.getNextAsn);
  }

  Query<List<Note>> getAllNotesQuery(int id) {
    return Query<List<Note>>(
      key: 'document_notes/$id',
      queryFn: () async {
        return _api.getNotes(id);
      },
    );
  }

  Query<Uint8List> getPreviewQuery(int documentId) {
    return Query<Uint8List>(
      key: 'document_preview/$documentId',
      queryFn: () {
        return _api.getPreview(documentId);
      },
    );
  }

  String getPreviewUrl(int id) {
    return _api.getPreviewUrl(id);
  }

  Query<Iterable<ShareLink>> getShareLinksQuery(int documentId) {
    return Query<List<ShareLink>>(
      key: 'document_share_links/$documentId',
      queryFn: () async {
        final data = await _api.getShareLinks(documentId);
        return data.toList();
      },
    );
  }

  String getThumbnailUrl(int documentId) {
    return _api.getThumbnailUrl(documentId);
  }

  Mutation<Document, PatchedDocumentRequest> patchDocumentMutation(
    int id, {
    invalidateGetAllQueries = true,
  }) {
    return Mutation<Document, PatchedDocumentRequest>(
      key: 'patch_document/$id',
      mutationFn: (document) {
        return _api.patch(id, document);
      },
      onStartMutation: (arg) {
        final query = CachedQuery.instance.getQuery<Query<Document>>(
          'document/$id',
        );
        if (query?.state.data != null) {
          query!.update((currentData) => currentData!.mergePatchedRequest(arg));
        }
      },
      onSuccess: (res, arg) {
        notifyChangeListeners(ChangeType.update);
      },
      invalidateQueries: [
        'document/$id',
        'field_suggestions/$id',
        ..._cachedDocumentQueriesToInvalidate,
      ],
    );
  }

  Mutation<Document, DocumentRequest> putDocumentMutation(int id) {
    return Mutation<Document, DocumentRequest>(
      key: 'patch_document/$id',
      mutationFn: (request) {
        return _api.put(id, request);
      },
      onStartMutation: (arg) {
        final query = CachedQuery.instance.getQuery<Query<Document>>(
          'document/$id',
        );
        if (query?.state.data != null) {
          query!.update((currentData) => currentData!.mergeRequest(arg));
        }
      },
      onSuccess: (res, arg) {
        notifyChangeListeners(ChangeType.update);
      },
      invalidateQueries: [
        'document/$id',
        'field_suggestions/$id',
        ..._cachedDocumentQueriesToInvalidate,
      ],
    );
  }

  Future<String> generateLocalFilePath(
    int documentId, {
    bool original = false,
    PaperlessDirectoryType type = PaperlessDirectoryType.temporary,
  }) async {
    final metadataResult = await getMetaDataQuery(documentId).fetch();
    final documentResult = await getDocumentQuery(documentId).fetch();
    if (documentResult.isError || metadataResult.isError) {
      throw metadataResult.error ?? documentResult.error;
    }

    final metadata = metadataResult.data!;
    final document = documentResult.data!;

    final effectiveFilePath = document.archivedFileName ??
        document.originalFileName ??
        metadata.mediaFilename;
    if (effectiveFilePath == null) {
      logger.fe(
        'No valid filename found for document $documentId',
        className: runtimeType.toString(),
        methodName: 'generateLocalFilePath',
      );
      throw Exception('No valid filename found for document $documentId');
    }
    final normalizedPath = effectiveFilePath.replaceAll("/", " ");
    final extension = original ? p.extension(normalizedPath) : '.pdf';
    return "${FileService.instance.getDirectory(type).path}/${p.basenameWithoutExtension(normalizedPath)}$extension";
  }
}
