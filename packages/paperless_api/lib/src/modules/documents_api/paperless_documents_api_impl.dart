import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/src/boundary_characters.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:paperless_api/src/constants.dart';
import 'package:paperless_api/src/models/bulk_edit_model.dart';
import 'package:paperless_api/src/models/document_filter.dart';
import 'package:paperless_api/src/models/document_meta_data_model.dart';
import 'package:paperless_api/src/models/document_model.dart';
import 'package:paperless_api/src/models/paged_search_result.dart';
import 'package:paperless_api/src/models/paperless_server_exception.dart';
import 'package:paperless_api/src/models/query_parameters/asn_query.dart';
import 'package:paperless_api/src/models/query_parameters/sort_field.dart';
import 'package:paperless_api/src/models/query_parameters/sort_order.dart';
import 'package:paperless_api/src/models/similar_document_model.dart';
import 'paperless_documents_api.dart';

class PaperlessDocumentsApiImpl implements PaperlessDocumentsApi {
  final BaseClient baseClient;
  final HttpClient httpClient;

  PaperlessDocumentsApiImpl(this.baseClient, this.httpClient);

  @override
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
  }) async {
    // The multipart request has to be generated from scratch as the http library does
    // not allow the same key (tags) to be added multiple times. However, this is what the
    // paperless api expects, i.e. one block for each tag.
    final request = await httpClient.postUrl(
      Uri.parse("$serverUrl/api/documents/post_document/"),
    );

    final boundary = _boundaryString();

    StringBuffer bodyBuffer = StringBuffer();

    var fields = <String, String>{};
    fields.putIfAbsent('title', () => title);
    if (createdAt != null) {
      fields.putIfAbsent('created', () => apiDateFormat.format(createdAt));
    }
    if (correspondent != null) {
      fields.putIfAbsent('correspondent', () => jsonEncode(correspondent));
    }
    if (documentType != null) {
      fields.putIfAbsent('document_type', () => jsonEncode(documentType));
    }

    for (final key in fields.keys) {
      bodyBuffer.write(_buildMultipartField(key, fields[key]!, boundary));
    }

    for (final tag in tags) {
      bodyBuffer.write(_buildMultipartField('tags', tag.toString(), boundary));
    }

    bodyBuffer.write("--$boundary"
        '\r\nContent-Disposition: form-data; name="document"; filename="$filename"'
        "\r\nContent-type: application/octet-stream"
        "\r\n\r\n");

    final closing = "\r\n--$boundary--\r\n";

    // Set headers
    request.headers.set(HttpHeaders.contentTypeHeader,
        "multipart/form-data; boundary=$boundary");
    request.headers.set(HttpHeaders.contentLengthHeader,
        "${bodyBuffer.length + closing.length + documentBytes.lengthInBytes}");
    request.headers.set(HttpHeaders.authorizationHeader, "Token $authToken");

    //Write fields to request
    request.write(bodyBuffer.toString());
    //Stream file
    await request.addStream(Stream.fromIterable(documentBytes.map((e) => [e])));
    // Write closing boundary to request
    request.write(closing);

    final response = await request.close();

    if (response.statusCode != 200) {
      throw PaperlessServerException(
        ErrorCode.documentUploadFailed,
        httpStatusCode: response.statusCode,
      );
    }
  }

  String _buildMultipartField(String fieldName, String value, String boundary) {
    // ignore: prefer_interpolation_to_compose_strings
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
    var list = List<int>.generate(
      70 - prefix.length,
      (index) => boundaryCharacters[_random.nextInt(boundaryCharacters.length)],
      growable: false,
    );
    return '$prefix${String.fromCharCodes(list)}';
  }

  @override
  Future<DocumentModel> update(DocumentModel doc) async {
    final response = await baseClient.put(
      Uri.parse("/api/documents/${doc.id}/"),
      body: json.encode(doc.toJson()),
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == 200) {
      return DocumentModel.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } else {
      throw const PaperlessServerException(ErrorCode.documentUpdateFailed);
    }
  }

  @override
  Future<PagedSearchResult<DocumentModel>> find(DocumentFilter filter) async {
    final filterParams = filter.toQueryString();
    final response = await baseClient.get(
      Uri.parse("/api/documents/?$filterParams"),
    );
    if (response.statusCode == 200) {
      return compute(
        PagedSearchResult.fromJson,
        PagedSearchResultJsonSerializer<DocumentModel>(
          jsonDecode(utf8.decode(response.bodyBytes)),
          DocumentModel.fromJson,
        ),
      );
    } else {
      throw const PaperlessServerException(ErrorCode.documentLoadFailed);
    }
  }

  @override
  Future<int> delete(DocumentModel doc) async {
    final response =
        await baseClient.delete(Uri.parse("/api/documents/${doc.id}/"));

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
    final response = await baseClient.get(Uri.parse(getPreviewUrl(documentId)));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw const PaperlessServerException(ErrorCode.documentPreviewFailed);
  }

  @override
  Future<int> findNextAsn() async {
    const DocumentFilter asnQueryFilter = DocumentFilter(
      sortField: SortField.archiveSerialNumber,
      sortOrder: SortOrder.descending,
      asnQuery: AsnQuery.anyAssigned(),
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
    final response = await baseClient.post(
      Uri.parse("/api/documents/bulk_edit/"),
      body: json.encode(action.toJson()),
      headers: {'Content-Type': 'application/json'},
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
    final response = await baseClient
        .get(Uri.parse("/api/documents/${document.id}/download/"));
    return response.bodyBytes;
  }

  @override
  Future<DocumentMetaData> getMetaData(DocumentModel document) async {
    final response = await baseClient
        .get(Uri.parse("/api/documents/${document.id}/metadata/"));
    return compute(
      DocumentMetaData.fromJson,
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<String>> autocomplete(String query, [int limit = 10]) async {
    final response = await baseClient
        .get(Uri.parse("/api/search/autocomplete/?query=$query&limit=$limit}"));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<String>;
    }
    throw const PaperlessServerException(ErrorCode.autocompleteQueryError);
  }

  @override
  Future<List<SimilarDocumentModel>> findSimilar(int docId) async {
    final response = await baseClient
        .get(Uri.parse("/api/documents/?more_like=$docId&pageSize=10"));
    if (response.statusCode == 200) {
      return (await compute(
        PagedSearchResult<SimilarDocumentModel>.fromJson,
        PagedSearchResultJsonSerializer(
          jsonDecode(utf8.decode(response.bodyBytes)),
          SimilarDocumentModel.fromJson,
        ),
      ))
          .results;
    }
    throw const PaperlessServerException(ErrorCode.similarQueryError);
  }
}
