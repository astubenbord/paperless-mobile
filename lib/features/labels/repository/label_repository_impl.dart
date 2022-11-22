import 'dart:convert';

import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/util.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/labels/correspondent/model/correspondent.model.dart';
import 'package:paperless_mobile/features/labels/document_type/model/document_type.model.dart';
import 'package:paperless_mobile/features/labels/repository/label_repository.dart';
import 'package:paperless_mobile/features/labels/storage_path/model/storage_path.model.dart';
import 'package:paperless_mobile/features/labels/tags/model/tag.model.dart';
import 'package:http/http.dart';
import 'package:injectable/injectable.dart';

@Singleton(as: LabelRepository)
class LabelRepositoryImpl implements LabelRepository {
  final BaseClient httpClient;

  LabelRepositoryImpl(@Named("timeoutClient") this.httpClient);

  @override
  Future<Correspondent?> getCorrespondent(int id) async {
    return getSingleResult(
      "/api/correspondents/$id/",
      Correspondent.fromJson,
      ErrorCode.correspondentLoadFailed,
    );
  }

  @override
  Future<Tag?> getTag(int id) async {
    return getSingleResult(
        "/api/tags/$id/", Tag.fromJson, ErrorCode.tagLoadFailed);
  }

  @override
  Future<List<Tag>> getTags({List<int>? ids}) async {
    final results = await getCollection(
      "/api/tags/?page=1&page_size=100000",
      Tag.fromJson,
      ErrorCode.tagLoadFailed,
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
    );
  }

  @override
  Future<List<Correspondent>> getCorrespondents() {
    return getCollection(
      "/api/correspondents/?page=1&page_size=100000",
      Correspondent.fromJson,
      ErrorCode.correspondentLoadFailed,
    );
  }

  @override
  Future<List<DocumentType>> getDocumentTypes() {
    return getCollection(
      "/api/document_types/?page=1&page_size=100000",
      DocumentType.fromJson,
      ErrorCode.documentTypeLoadFailed,
    );
  }

  @override
  Future<Correspondent> saveCorrespondent(Correspondent correspondent) async {
    final response = await httpClient.post(
      Uri.parse('/api/correspondents/'),
      body: json.encode(correspondent.toJson()),
      headers: {"Content-Type": "application/json"},
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == 201) {
      return Correspondent.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw ErrorMessage(ErrorCode.correspondentCreateFailed,
        httpStatusCode: response.statusCode);
  }

  @override
  Future<DocumentType> saveDocumentType(DocumentType type) async {
    final response = await httpClient.post(
      Uri.parse('/api/document_types/'),
      body: json.encode(type.toJson()),
      headers: {"Content-Type": "application/json"},
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == 201) {
      return DocumentType.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw const ErrorMessage(ErrorCode.documentTypeCreateFailed);
  }

  @override
  Future<Tag> saveTag(Tag tag) async {
    final body = json.encode(tag.toJson());
    final response = await httpClient.post(
      Uri.parse('/api/tags/'),
      body: body,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json; version=2",
      },
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == 201) {
      return Tag.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw const ErrorMessage(ErrorCode.tagCreateFailed);
  }

  @override
  Future<int> deleteCorrespondent(Correspondent correspondent) async {
    assert(correspondent.id != null);
    final response = await httpClient
        .delete(Uri.parse('/api/correspondents/${correspondent.id}/'));
    if (response.statusCode == 204) {
      return correspondent.id!;
    }
    throw const ErrorMessage(ErrorCode.unknown);
  }

  @override
  Future<int> deleteDocumentType(DocumentType documentType) async {
    assert(documentType.id != null);
    final response = await httpClient
        .delete(Uri.parse('/api/document_types/${documentType.id}/'));
    if (response.statusCode == 204) {
      return documentType.id!;
    }
    throw const ErrorMessage(ErrorCode.unknown);
  }

  @override
  Future<int> deleteTag(Tag tag) async {
    assert(tag.id != null);
    final response = await httpClient.delete(Uri.parse('/api/tags/${tag.id}/'));
    if (response.statusCode == 204) {
      return tag.id!;
    }
    throw const ErrorMessage(ErrorCode.unknown);
  }

  @override
  Future<Correspondent> updateCorrespondent(Correspondent correspondent) async {
    assert(correspondent.id != null);
    final response = await httpClient.put(
      Uri.parse('/api/correspondents/${correspondent.id}/'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(correspondent.toJson()),
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == 200) {
      return Correspondent.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw const ErrorMessage(ErrorCode.unknown);
  }

  @override
  Future<DocumentType> updateDocumentType(DocumentType documentType) async {
    assert(documentType.id != null);
    final response = await httpClient.put(
      Uri.parse('/api/document_types/${documentType.id}/'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(documentType.toJson()),
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == 200) {
      return DocumentType.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw const ErrorMessage(ErrorCode.unknown);
  }

  @override
  Future<Tag> updateTag(Tag tag) async {
    assert(tag.id != null);
    final response = await httpClient.put(
      Uri.parse('/api/tags/${tag.id}/'),
      headers: {
        "Accept": "application/json; version=2",
        "Content-Type": "application/json",
      },
      body: json.encode(tag.toJson()),
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == 200) {
      return Tag.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw const ErrorMessage(ErrorCode.unknown);
  }

  @override
  Future<int> deleteStoragePath(StoragePath path) async {
    assert(path.id != null);
    final response =
        await httpClient.delete(Uri.parse('/api/storage_paths/${path.id}/'));
    if (response.statusCode == 204) {
      return path.id!;
    }
    throw const ErrorMessage(ErrorCode.unknown);
  }

  @override
  Future<StoragePath?> getStoragePath(int id) {
    return getSingleResult("/api/storage_paths/?page=1&page_size=100000",
        StoragePath.fromJson, ErrorCode.storagePathLoadFailed);
  }

  @override
  Future<List<StoragePath>> getStoragePaths() {
    return getCollection(
      "/api/storage_paths/?page=1&page_size=100000",
      StoragePath.fromJson,
      ErrorCode.storagePathLoadFailed,
    );
  }

  @override
  Future<StoragePath> saveStoragePath(StoragePath path) async {
    final response = await httpClient.post(
      Uri.parse('/api/storage_paths/'),
      body: json.encode(path.toJson()),
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == 201) {
      return StoragePath.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw ErrorMessage(ErrorCode.storagePathCreateFailed,
        httpStatusCode: response.statusCode);
  }

  @override
  Future<StoragePath> updateStoragePath(StoragePath path) async {
    assert(path.id != null);
    final response = await httpClient.put(
      Uri.parse('/api/storage_paths/${path.id}/'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(path.toJson()),
    );
    if (response.statusCode == 200) {
      return StoragePath.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw const ErrorMessage(ErrorCode.unknown);
  }
}
