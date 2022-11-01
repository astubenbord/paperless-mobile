import 'dart:convert';

import 'package:flutter_paperless_mobile/core/model/error_message.dart';
import 'package:flutter_paperless_mobile/core/util.dart';
import 'package:flutter_paperless_mobile/di_initializer.dart';
import 'package:flutter_paperless_mobile/features/documents/model/saved_view.model.dart';
import 'package:http/http.dart';
import 'package:injectable/injectable.dart';

abstract class SavedViewsRepository {
  Future<List<SavedView>> getAll();

  Future<SavedView> save(SavedView view);
  Future<int> delete(SavedView view);
}

@Injectable(as: SavedViewsRepository)
class SavedViewRepositoryImpl implements SavedViewsRepository {
  final BaseClient httpClient;

  SavedViewRepositoryImpl(@Named("timeoutClient") this.httpClient);

  @override
  Future<List<SavedView>> getAll() {
    return getCollection(
      "/api/saved_views/",
      SavedView.fromJson,
      ErrorCode.loadSavedViewsError,
    );
  }

  @override
  Future<SavedView> save(SavedView view) async {
    final response = await httpClient.post(
      Uri.parse("/api/saved_views/"),
      body: jsonEncode(view.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 201) {
      return SavedView.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw ErrorMessage(ErrorCode.createSavedViewError, httpStatusCode: response.statusCode);
  }

  @override
  Future<int> delete(SavedView view) async {
    final response = await httpClient.delete(Uri.parse("/api/saved_views/${view.id}/"));
    if (response.statusCode == 204) {
      return view.id!;
    }
    throw ErrorMessage(ErrorCode.deleteSavedViewError, httpStatusCode: response.statusCode);
  }
}
