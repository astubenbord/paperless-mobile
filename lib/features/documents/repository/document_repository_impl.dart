import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';
import 'package:paperless_mobile/core/type/json.dart';
import 'package:paperless_mobile/core/util.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/extensions/dart_extensions.dart';
import 'package:paperless_mobile/features/documents/model/bulk_edit.model.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/model/document_meta_data.model.dart';
import 'package:paperless_mobile/features/documents/model/paged_search_result.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/asn_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/sort_field.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/sort_order.dart';
import 'package:paperless_mobile/features/documents/model/similar_document.model.dart';
import 'package:paperless_mobile/features/documents/repository/document_repository.dart';
import 'package:paperless_mobile/util.dart';
import 'package:http/http.dart';
import 'package:http/src/boundary_characters.dart'; //TODO: remove once there is either a paperless API update or there is a better solution...
import 'package:injectable/injectable.dart';

@Injectable(as: DocumentRepository)
class DocumentRepositoryImpl implements DocumentRepository {
  ////
  //final StatusService statusService;
  final LocalVault localStorage;
  final BaseClient httpClient;

  DocumentRepositoryImpl(
    //this.statusService,
    this.localStorage,
    @Named("timeoutClient") this.httpClient,
  );
  @override
  Future<void> create(
    Uint8List documentBytes,
    String filename, {
    required String title,
    int? documentType,
    int? correspondent,
    List<int>? tags,
    DateTime? createdAt,
  }) async {
    final auth = await localStorage.loadAuthenticationInformation();

    if (auth == null) {
      throw const ErrorMessage(ErrorCode.notAuthenticated);
    }

    // The multipart request has to be generated from scratch as the http library does
    // not allow the same key (tags) to be added multiple times. However, this is what the
    // paperless api expects, i.e. one block for each tag.
    final request = await getIt<HttpClient>().postUrl(
      Uri.parse("${auth.serverUrl}/api/documents/post_document/"),
    );

    final boundary = _boundaryString();

    StringBuffer bodyBuffer = StringBuffer();

    var fields = <String, String>{};

    fields.tryPutIfAbsent('title', () => title);
    fields.tryPutIfAbsent('created', () => formatDateNullable(createdAt));
    fields.tryPutIfAbsent(
        'correspondent', () => correspondent == null ? null : json.encode(correspondent));
    fields.tryPutIfAbsent(
        'document_type', () => documentType == null ? null : json.encode(documentType));

    for (final key in fields.keys) {
      bodyBuffer.write(_buildMultipartField(key, fields[key]!, boundary));
    }

    for (final tag in tags ?? <int>[]) {
      bodyBuffer.write(_buildMultipartField('tags', tag.toString(), boundary));
    }

    bodyBuffer.write("--$boundary"
        '\r\nContent-Disposition: form-data; name="document"; filename="$filename"'
        "\r\nContent-type: application/octet-stream"
        "\r\n\r\n");

    final closing = "\r\n--" + boundary + "--\r\n";

    // Set headers
    request.headers.set(HttpHeaders.contentTypeHeader, "multipart/form-data; boundary=" + boundary);
    request.headers.set(HttpHeaders.contentLengthHeader,
        "${bodyBuffer.length + closing.length + documentBytes.lengthInBytes}");
    request.headers.set(HttpHeaders.authorizationHeader, "Token ${auth.token}");

    //Write fields to request
    request.write(bodyBuffer.toString());
    //Stream file
    await request.addStream(Stream.fromIterable(documentBytes.map((e) => [e])));
    // Write closing boundary to request
    request.write(closing);

    final response = await request.close();

    if (response.statusCode != 200) {
      throw ErrorMessage(ErrorCode.documentUploadFailed, httpStatusCode: response.statusCode);
    }
  }

  String _buildMultipartField(String fieldName, String value, String boundary) {
    return '--$boundary'
            '\r\nContent-Disposition: form-data; name="$fieldName"'
            '\r\nContent-type: text/plain'
            '\r\n\r\n' +
        value +
        '\r\n';
  }

  String _boundaryString() {
    Random _random = Random();
    var prefix = 'dart-http-boundary-';
    var list = List<int>.generate(70 - prefix.length,
        (index) => boundaryCharacters[_random.nextInt(boundaryCharacters.length)],
        growable: false);
    return '$prefix${String.fromCharCodes(list)}';
  }

  @override
  Future<DocumentModel> update(DocumentModel doc) async {
    final response = await httpClient.put(Uri.parse("/api/documents/${doc.id}/"),
        body: json.encode(doc.toJson()),
        headers: {"Content-Type": "application/json"}).timeout(requestTimeout);
    if (response.statusCode == 200) {
      return DocumentModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw const ErrorMessage(ErrorCode.documentUpdateFailed);
    }
  }

  @override
  Future<PagedSearchResult<DocumentModel>> find(DocumentFilter filter) async {
    final filterParams = filter.toQueryString();
    final response = await httpClient.get(
      Uri.parse("/api/documents/?$filterParams"),
    );
    if (response.statusCode == 200) {
      final searchResult = PagedSearchResult.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
        DocumentModel.fromJson,
      );
      return searchResult;
    } else {
      throw const ErrorMessage(ErrorCode.documentLoadFailed);
    }
  }

  @override
  Future<int> delete(DocumentModel doc) async {
    final response = await httpClient.delete(Uri.parse("/api/documents/${doc.id}/"));

    if (response.statusCode == 204) {
      return Future.value(doc.id);
    }
    throw const ErrorMessage(ErrorCode.documentDeleteFailed);
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
    final response = await httpClient.get(Uri.parse(getPreviewUrl(documentId)));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw const ErrorMessage(ErrorCode.documentPreviewFailed);
  }

  @override
  Future<int> findNextAsn() async {
    const DocumentFilter asnQueryFilter = DocumentFilter(
      sortField: SortField.archiveSerialNumber,
      sortOrder: SortOrder.descending,
      asn: AsnQuery.anyAssigned(),
      page: 1,
      pageSize: 1,
    );
    try {
      final result = await find(asnQueryFilter);
      return result.results
              .map((e) => e.archiveSerialNumber)
              .firstWhere((asn) => asn != null, orElse: () => 0)! +
          1;
    } on ErrorMessage catch (_) {
      throw const ErrorMessage(ErrorCode.documentAsnQueryFailed);
    }
  }

  @override
  Future<List<int>> bulkDelete(List<DocumentModel> documentModels) async {
    final List<int> ids = documentModels.map((e) => e.id).toList();
    final action = BulkEditAction.delete(ids);
    final response = await httpClient.post(
      Uri.parse("/api/documents/bulk_edit/"),
      body: json.encode(action.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return ids;
    } else {
      throw const ErrorMessage(ErrorCode.documentBulkDeleteFailed);
    }
  }

  @override
  Future<DocumentModel> waitForConsumptionFinished(String fileName, String title) async {
    // Always wait 5 seconds, processing usually takes longer...
    //await Future.delayed(const Duration(seconds: 5));
    PagedSearchResult<DocumentModel> results = await find(DocumentFilter.latestDocument);

    while ((results.results.isEmpty ||
        (results.results[0].originalFileName != fileName && results.results[0].title != title))) {
      //TODO: maybe implement more intelligent retry logic or find workaround for websocket authentication...
      await Future.delayed(const Duration(seconds: 2));
      results = await find(DocumentFilter.latestDocument);
    }
    try {
      return results.results.first;
    } on StateError {
      throw const ErrorMessage(ErrorCode.documentUploadFailed);
    }
  }

  @override
  Future<Uint8List> download(DocumentModel document) async {
    //TODO: Check if this works...
    final response = await httpClient.get(Uri.parse("/api/documents/${document.id}/download/"));
    return response.bodyBytes;
  }

  @override
  Future<DocumentMetaData> getMetaData(DocumentModel document) async {
    final response = await httpClient.get(Uri.parse("/api/documents/${document.id}/metadata/"));
    return DocumentMetaData.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  }

  @override
  Future<List<String>> autocomplete(String query, [int limit = 10]) async {
    final response =
        await httpClient.get(Uri.parse("/api/search/autocomplete/?query=$query&limit=$limit}"));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<String>;
    }
    throw const ErrorMessage(ErrorCode.autocompleteQueryError);
  }

  @override
  Future<List<SimilarDocumentModel>> findSimilar(int docId) async {
    final response =
        await httpClient.get(Uri.parse("/api/documents/?more_like=$docId&pageSize=10"));
    if (response.statusCode == 200) {
      return PagedSearchResult<SimilarDocumentModel>.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
        SimilarDocumentModel.fromJson,
      ).results;
    }
    throw const ErrorMessage(ErrorCode.similarQueryError);
  }
}
