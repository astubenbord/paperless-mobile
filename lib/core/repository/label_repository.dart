import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/logging/logger.dart';

class LabelRepository extends ChangeNotifier {
  final PaperlessLabelsApi _api;

  Map<int, Correspondent> correspondents = {};
  Map<int, DocumentType> documentTypes = {};
  Map<int, StoragePath> storagePaths = {};
  Map<int, Tag> tags = {};

  LabelRepository(this._api);

  // Resets the repository to its initial state and loads all data from the API.
  Future<void> initialize({
    required bool loadCorrespondents,
    required bool loadDocumentTypes,
    required bool loadStoragePaths,
    required bool loadTags,
  }) async {
    correspondents = {};
    documentTypes = {};
    storagePaths = {};
    tags = {};
    await Future.wait([
      if (loadCorrespondents) findAllCorrespondents(),
      if (loadDocumentTypes) findAllDocumentTypes(),
      if (loadStoragePaths) findAllStoragePaths(),
      if (loadTags) findAllTags(),
    ]);
  }

  Future<Tag> createTag(Tag object) async {
    final created = await _api.saveTag(object);
    tags = {...tags, created.id!: created};
    notifyListeners();
    return created;
  }

  Future<int> deleteTag(Tag tag) async {
    await _api.deleteTag(tag);
    tags.remove(tag.id!);
    notifyListeners();
    return tag.id!;
  }

  Future<Tag?> findTag(int id) async {
    final tag = await _api.getTag(id);
    if (tag != null) {
      tags = {...tags, id: tag};
      notifyListeners();
      return tag;
    }
    return null;
  }

  Future<Iterable<Tag>> findAllTags([Iterable<int>? ids]) async {
    logger.fd(
      "Loading ${ids?.isEmpty ?? true ? "all" : "a subset of"} tags"
      "${ids?.isEmpty ?? true ? "" : " (${ids!.join(",")})"}...",
      className: runtimeType.toString(),
      methodName: "findAllTags",
    );
    final data = await _api.getTags(ids);
    if (ids?.isNotEmpty ?? false) {
      logger.fd(
        "Successfully updated subset of tags: ${ids!.join(",")}",
        className: runtimeType.toString(),
        methodName: "findAllTags",
      );
      // Only update the tags that were requested, keep existing ones.
      tags = {...tags, for (var tag in data) tag.id!: tag};
    } else {
      logger.fd(
        "Successfully updated all tags.",
        className: runtimeType.toString(),
        methodName: "findAllTags",
      );
      tags = {for (var tag in data) tag.id!: tag};
    }
    notifyListeners();
    return data;
  }

  Future<Tag> updateTag(Tag tag) async {
    final updated = await _api.updateTag(tag);
    tags = {...tags, updated.id!: updated};
    notifyListeners();
    return updated;
  }

  Future<Correspondent> createCorrespondent(Correspondent correspondent) async {
    final created = await _api.saveCorrespondent(correspondent);
    correspondents = {...correspondents, created.id!: created};
    notifyListeners();
    return created;
  }

  Future<int> deleteCorrespondent(Correspondent correspondent) async {
    await _api.deleteCorrespondent(correspondent);
    correspondents.remove(correspondent.id!);
    notifyListeners();
    return correspondent.id!;
  }

  Future<Correspondent?> findCorrespondent(int id) async {
    final correspondent = await _api.getCorrespondent(id);
    if (correspondent != null) {
      correspondents = {...correspondents, id: correspondent};
      notifyListeners();
      return correspondent;
    }
    return null;
  }

  Future<Iterable<Correspondent>> findAllCorrespondents() async {
    final data = await _api.getCorrespondents();
    correspondents = {for (var element in data) element.id!: element};
    notifyListeners();
    return data;
  }

  Future<Correspondent> updateCorrespondent(Correspondent correspondent) async {
    final updated = await _api.updateCorrespondent(correspondent);
    correspondents = {...correspondents, updated.id!: updated};
    notifyListeners();
    return updated;
  }

  Future<DocumentType> createDocumentType(DocumentType documentType) async {
    final created = await _api.saveDocumentType(documentType);
    documentTypes = {...documentTypes, created.id!: created};
    notifyListeners();
    return created;
  }

  Future<int> deleteDocumentType(DocumentType documentType) async {
    await _api.deleteDocumentType(documentType);
    documentTypes.remove(documentType.id!);
    notifyListeners();
    return documentType.id!;
  }

  Future<DocumentType?> findDocumentType(int id) async {
    final documentType = await _api.getDocumentType(id);
    if (documentType != null) {
      documentTypes = {...documentTypes, id: documentType};
      notifyListeners();
      return documentType;
    }
    return null;
  }

  Future<Iterable<DocumentType>> findAllDocumentTypes() async {
    final documentTypes = await _api.getDocumentTypes();
    this.documentTypes = {
      for (var dt in documentTypes) dt.id!: dt,
    };
    notifyListeners();
    return documentTypes;
  }

  Future<DocumentType> updateDocumentType(DocumentType documentType) async {
    final updated = await _api.updateDocumentType(documentType);
    documentTypes = {...documentTypes, updated.id!: updated};
    notifyListeners();
    return updated;
  }

  Future<StoragePath> createStoragePath(StoragePath storagePath) async {
    final created = await _api.saveStoragePath(storagePath);
    storagePaths = {...storagePaths, created.id!: created};
    notifyListeners();
    return created;
  }

  Future<int> deleteStoragePath(StoragePath storagePath) async {
    await _api.deleteStoragePath(storagePath);
    storagePaths.remove(storagePath.id!);
    notifyListeners();
    return storagePath.id!;
  }

  Future<StoragePath?> findStoragePath(int id) async {
    final storagePath = await _api.getStoragePath(id);
    if (storagePath != null) {
      storagePaths = {...storagePaths, id: storagePath};
      notifyListeners();
      return storagePath;
    }
    return null;
  }

  Future<Iterable<StoragePath>> findAllStoragePaths() async {
    final storagePaths = await _api.getStoragePaths();
    this.storagePaths = {
      for (var sp in storagePaths) sp.id!: sp,
    };
    notifyListeners();
    return storagePaths;
  }

  Future<StoragePath> updateStoragePath(StoragePath storagePath) async {
    final updated = await _api.updateStoragePath(storagePath);
    storagePaths = {...storagePaths, updated.id!: updated};
    notifyListeners();
    return updated;
  }

  // @override
  // LabelRepositoryState? fromJson(Map<String, dynamic> json) {
  //   return LabelRepositoryState.fromJson(json);
  // }

  // @override
  // Map<String, dynamic>? toJson(LabelRepositoryState state) {
  //   return state.toJson();
  // }
}
