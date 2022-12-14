import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:paperless_api/src/models/labels/correspondent_model.dart';
import 'package:paperless_api/src/models/labels/document_type_model.dart';
import 'package:paperless_api/src/models/labels/storage_path_model.dart';
import 'package:paperless_api/src/models/labels/tag_model.dart';
import 'package:paperless_api/src/models/paperless_server_exception.dart';
import 'package:paperless_api/src/modules/labels_api/paperless_labels_api.dart';
import 'package:paperless_api/src/utils.dart';

class PaperlessLabelApiImpl implements PaperlessLabelsApi {
  final BaseClient client;

  PaperlessLabelApiImpl(this.client);
  @override
  Future<Correspondent?> getCorrespondent(int id) async {
    return getSingleResult(
      "/api/correspondents/$id/",
      Correspondent.fromJson,
      ErrorCode.correspondentLoadFailed,
      client: client,
    );
  }

  @override
  Future<Tag?> getTag(int id) async {
    return getSingleResult(
      "/api/tags/$id/",
      Tag.fromJson,
      ErrorCode.tagLoadFailed,
      client: client,
    );
  }

  @override
  Future<List<Tag>> getTags([Iterable<int>? ids]) async {
    final results = await getCollection(
      "/api/tags/?page=1&page_size=100000",
      Tag.fromJson,
      ErrorCode.tagLoadFailed,
      client: client,
      minRequiredApiVersion: 2,
    );
    return results
        .where((element) => ids?.contains(element.id) ?? true)
        .toList();
  }

  @override
  Future<DocumentType?> getDocumentType(int id) async {
    return getSingleResult(
      "/api/document_types/$id/",
      DocumentType.fromJson,
      ErrorCode.documentTypeLoadFailed,
      client: client,
    );
  }

  @override
  Future<List<Correspondent>> getCorrespondents([Iterable<int>? ids]) async {
    final results = await getCollection(
      "/api/correspondents/?page=1&page_size=100000",
      Correspondent.fromJson,
      ErrorCode.correspondentLoadFailed,
      client: client,
    );

    return results
        .where((element) => ids?.contains(element.id) ?? true)
        .toList();
  }

  @override
  Future<List<DocumentType>> getDocumentTypes([Iterable<int>? ids]) async {
    final results = await getCollection(
      "/api/document_types/?page=1&page_size=100000",
      DocumentType.fromJson,
      ErrorCode.documentTypeLoadFailed,
      client: client,
    );

    return results
        .where((element) => ids?.contains(element.id) ?? true)
        .toList();
  }

  @override
  Future<Correspondent> saveCorrespondent(Correspondent correspondent) async {
    final response = await client.post(
      Uri.parse('/api/correspondents/'),
      body: jsonEncode(correspondent.toJson()),
      headers: {"Content-Type": "application/json"},
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == HttpStatus.created) {
      return Correspondent.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    }
    throw PaperlessServerException(
      ErrorCode.correspondentCreateFailed,
      httpStatusCode: response.statusCode,
    );
  }

  @override
  Future<DocumentType> saveDocumentType(DocumentType type) async {
    final response = await client.post(
      Uri.parse('/api/document_types/'),
      body: json.encode(type.toJson()),
      headers: {"Content-Type": "application/json"},
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == HttpStatus.created) {
      return DocumentType.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    }
    throw PaperlessServerException(
      ErrorCode.documentTypeCreateFailed,
      httpStatusCode: response.statusCode,
    );
  }

  @override
  Future<Tag> saveTag(Tag tag) async {
    final body = json.encode(tag.toJson());
    final response = await client.post(
      Uri.parse('/api/tags/'),
      body: body,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json; version=2",
      },
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == HttpStatus.created) {
      return Tag.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw PaperlessServerException(
      ErrorCode.tagCreateFailed,
      httpStatusCode: response.statusCode,
    );
  }

  @override
  Future<int> deleteCorrespondent(Correspondent correspondent) async {
    assert(correspondent.id != null);
    final response = await client
        .delete(Uri.parse('/api/correspondents/${correspondent.id}/'));
    if (response.statusCode == HttpStatus.noContent) {
      return correspondent.id!;
    }
    throw PaperlessServerException(
      ErrorCode.unknown,
      httpStatusCode: response.statusCode,
    );
  }

  @override
  Future<int> deleteDocumentType(DocumentType documentType) async {
    assert(documentType.id != null);
    final response = await client
        .delete(Uri.parse('/api/document_types/${documentType.id}/'));
    if (response.statusCode == HttpStatus.noContent) {
      return documentType.id!;
    }
    throw PaperlessServerException(
      ErrorCode.unknown,
      httpStatusCode: response.statusCode,
    );
  }

  @override
  Future<int> deleteTag(Tag tag) async {
    assert(tag.id != null);
    final response = await client.delete(Uri.parse('/api/tags/${tag.id}/'));
    if (response.statusCode == HttpStatus.noContent) {
      return tag.id!;
    }
    throw PaperlessServerException(
      ErrorCode.unknown,
      httpStatusCode: response.statusCode,
    );
  }

  @override
  Future<Correspondent> updateCorrespondent(Correspondent correspondent) async {
    assert(correspondent.id != null);
    final response = await client.put(
      Uri.parse('/api/correspondents/${correspondent.id}/'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(correspondent.toJson()),
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == HttpStatus.ok) {
      return Correspondent.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw PaperlessServerException(
      ErrorCode.unknown,
      httpStatusCode: response.statusCode,
    );
  }

  @override
  Future<DocumentType> updateDocumentType(DocumentType documentType) async {
    assert(documentType.id != null);
    final response = await client.put(
      Uri.parse('/api/document_types/${documentType.id}/'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(documentType.toJson()),
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == HttpStatus.ok) {
      return DocumentType.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw PaperlessServerException(
      ErrorCode.unknown,
      httpStatusCode: response.statusCode,
    );
  }

  @override
  Future<Tag> updateTag(Tag tag) async {
    assert(tag.id != null);
    final response = await client.put(
      Uri.parse('/api/tags/${tag.id}/'),
      headers: {
        "Accept": "application/json; version=2",
        "Content-Type": "application/json",
      },
      body: json.encode(tag.toJson()),
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == HttpStatus.ok) {
      return Tag.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw PaperlessServerException(
      ErrorCode.unknown,
      httpStatusCode: response.statusCode,
    );
  }

  @override
  Future<int> deleteStoragePath(StoragePath path) async {
    assert(path.id != null);
    final response =
        await client.delete(Uri.parse('/api/storage_paths/${path.id}/'));
    if (response.statusCode == HttpStatus.noContent) {
      return path.id!;
    }
    throw PaperlessServerException(
      ErrorCode.unknown,
      httpStatusCode: response.statusCode,
    );
  }

  @override
  Future<StoragePath?> getStoragePath(int id) {
    return getSingleResult(
      "/api/storage_paths/$id/",
      StoragePath.fromJson,
      ErrorCode.storagePathLoadFailed,
      client: client,
    );
  }

  @override
  Future<List<StoragePath>> getStoragePaths([Iterable<int>? ids]) async {
    final results = await getCollection(
      "/api/storage_paths/?page=1&page_size=100000",
      StoragePath.fromJson,
      ErrorCode.storagePathLoadFailed,
      client: client,
    );

    return results
        .where((element) => ids?.contains(element.id) ?? true)
        .toList();
  }

  @override
  Future<StoragePath> saveStoragePath(StoragePath path) async {
    final response = await client.post(
      Uri.parse('/api/storage_paths/'),
      body: json.encode(path.toJson()),
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == HttpStatus.created) {
      return StoragePath.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw PaperlessServerException(ErrorCode.storagePathCreateFailed,
        httpStatusCode: response.statusCode);
  }

  @override
  Future<StoragePath> updateStoragePath(StoragePath path) async {
    assert(path.id != null);
    final response = await client.put(
      Uri.parse('/api/storage_paths/${path.id}/'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(path.toJson()),
    );
    if (response.statusCode == HttpStatus.ok) {
      return StoragePath.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw const PaperlessServerException(ErrorCode.unknown);
  }
}
