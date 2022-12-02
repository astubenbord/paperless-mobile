import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:paperless_api/src/models/paperless_server_exception.dart';

Future<T> getSingleResult<T>(
  String url,
  T Function(Map<String, dynamic>) fromJson,
  ErrorCode errorCode, {
  required BaseClient client,
  int minRequiredApiVersion = 1,
}) async {
  final response = await client.get(
    Uri.parse(url),
    headers: {'accept': 'application/json; version=$minRequiredApiVersion'},
  );
  if (response.statusCode == HttpStatus.ok) {
    return compute(
      fromJson,
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }
  throw PaperlessServerException(
    errorCode,
    httpStatusCode: response.statusCode,
  );
}

Future<List<T>> getCollection<T>(
  String url,
  T Function(Map<String, dynamic>) fromJson,
  ErrorCode errorCode, {
  required BaseClient client,
  int minRequiredApiVersion = 1,
}) async {
  final response = await client.get(
    Uri.parse(url),
    headers: {'accept': 'application/json; version=$minRequiredApiVersion'},
  );
  if (response.statusCode == HttpStatus.ok) {
    final Map<String, dynamic> body =
        jsonDecode(utf8.decode(response.bodyBytes));
    if (body.containsKey('count')) {
      if (body['count'] == 0) {
        return <T>[];
      } else {
        return compute(
          _collectionFromJson,
          _CollectionFromJsonSerializationParams(
              fromJson, (body['results'] as List).cast<Map<String, dynamic>>()),
        );
      }
    }
  }
  throw PaperlessServerException(
    errorCode,
    httpStatusCode: response.statusCode,
  );
}

List<T> _collectionFromJson<T>(
    _CollectionFromJsonSerializationParams<T> params) {
  return params.list.map<T>((result) => params.fromJson(result)).toList();
}

class _CollectionFromJsonSerializationParams<T> {
  final T Function(Map<String, dynamic>) fromJson;
  final List<Map<String, dynamic>> list;

  _CollectionFromJsonSerializationParams(this.fromJson, this.list);
}
