import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:http/http.dart';

const requestTimeout = Duration(seconds: 5);

Future<T> getSingleResult<T>(
  String url,
  T Function(JSON) fromJson,
  ErrorCode errorCode, {
  int minRequiredApiVersion = 1,
}) async {
  final httpClient = getIt<BaseClient>(instanceName: "timeoutClient");
  final response = await httpClient.get(
    Uri.parse(url),
    headers: {'accept': 'application/json; version=$minRequiredApiVersion'},
  );
  if (response.statusCode == 200) {
    return compute(
      fromJson,
      jsonDecode(utf8.decode(response.bodyBytes)) as JSON,
    );
  }
  return Future.error(errorCode);
}

Future<List<T>> getCollection<T>(
  String url,
  T Function(JSON) fromJson,
  ErrorCode errorCode, {
  int minRequiredApiVersion = 1,
}) async {
  final httpClient = getIt<BaseClient>(instanceName: "timeoutClient");
  final response = await httpClient.get(
    Uri.parse(url),
    headers: {'accept': 'application/json; version=$minRequiredApiVersion'},
  );
  if (response.statusCode == 200) {
    final JSON body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body.containsKey('count')) {
      if (body['count'] == 0) {
        return <T>[];
      } else {
        return compute(
          _collectionFromJson,
          _CollectionFromJsonSerializationParams(
              fromJson, (body['results'] as List).cast<JSON>()),
        );
      }
    }
  }
  return Future.error(errorCode);
}

List<T> _collectionFromJson<T>(
    _CollectionFromJsonSerializationParams<T> params) {
  return params.list.map<T>((result) => params.fromJson(result)).toList();
}

class _CollectionFromJsonSerializationParams<T> {
  final T Function(JSON) fromJson;
  final List<JSON> list;

  _CollectionFromJsonSerializationParams(this.fromJson, this.list);
}
