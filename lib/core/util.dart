import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:paperless_mobile/core/logic/timeout_client.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

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
    return fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as JSON);
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
        return body['results']
            .cast<JSON>()
            .map<T>((result) => fromJson(result))
            .toList();
      }
    }
  }
  return Future.error(errorCode);
}
