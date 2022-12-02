import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:paperless_api/src/models/paperless_server_exception.dart';
import 'package:paperless_api/src/models/saved_view_model.dart';
import 'package:paperless_api/src/utils.dart';

import 'paperless_saved_views_api.dart';

class PaperlessSavedViewsApiImpl implements PaperlessSavedViewsApi {
  final BaseClient client;

  PaperlessSavedViewsApiImpl(this.client);

  @override
  Future<List<SavedView>> getAll() {
    return getCollection(
      "/api/saved_views/",
      SavedView.fromJson,
      ErrorCode.loadSavedViewsError,
      client: client,
    );
  }

  @override
  Future<SavedView> save(SavedView view) async {
    final response = await client.post(
      Uri.parse("/api/saved_views/"),
      body: jsonEncode(view.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == HttpStatus.created) {
      return SavedView.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw PaperlessServerException(
      ErrorCode.createSavedViewError,
      httpStatusCode: response.statusCode,
    );
  }

  @override
  Future<int> delete(SavedView view) async {
    final response =
        await client.delete(Uri.parse("/api/saved_views/${view.id}/"));
    if (response.statusCode == HttpStatus.noContent) {
      return view.id!;
    }
    throw PaperlessServerException(
      ErrorCode.deleteSavedViewError,
      httpStatusCode: response.statusCode,
    );
  }
}
