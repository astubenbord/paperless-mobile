import 'dart:io';

import 'package:dio/dio.dart';
import 'package:paperless_api/src/models/paperless_server_exception.dart';
import 'package:paperless_api/src/models/saved_view_model.dart';
import 'package:paperless_api/src/request_utils.dart';

import 'paperless_saved_views_api.dart';

class PaperlessSavedViewsApiImpl implements PaperlessSavedViewsApi {
  final Dio _client;

  PaperlessSavedViewsApiImpl(this._client);

  @override
  Future<Iterable<SavedView>> findAll([Iterable<int>? ids]) async {
    final result = await getCollection(
      "/api/saved_views/",
      SavedView.fromJson,
      ErrorCode.loadSavedViewsError,
      client: _client,
    );

    return result.where((view) => ids?.contains(view.id!) ?? true);
  }

  @override
  Future<SavedView> save(SavedView view) async {
    try {
      final response = await _client.post(
        "/api/saved_views/",
        data: view.toJson(),
      );
      if (response.statusCode == HttpStatus.created) {
        return SavedView.fromJson(response.data);
      }
      throw PaperlessServerException(
        ErrorCode.createSavedViewError,
        httpStatusCode: response.statusCode,
      );
    } on DioError catch (err) {
      throw err.error;
    }
  }

  @override
  Future<int> delete(SavedView view) async {
    try {
      final response = await _client.delete("/api/saved_views/${view.id}/");
      if (response.statusCode == HttpStatus.noContent) {
        return view.id!;
      }
      throw PaperlessServerException(
        ErrorCode.deleteSavedViewError,
        httpStatusCode: response.statusCode,
      );
    } on DioError catch (err) {
      throw err.error;
    }
  }

  @override
  Future<SavedView> find(int id) {
    return getSingleResult(
      "/api/saved_views/$id/",
      SavedView.fromJson,
      ErrorCode.loadSavedViewsError,
      client: _client,
    );
  }
}
