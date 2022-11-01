import 'dart:typed_data';

import 'dart:convert';

import 'package:flutter_paperless_mobile/core/model/error_message.dart';
import 'package:flutter_paperless_mobile/core/type/json.dart';
import 'package:flutter_paperless_mobile/di_initializer.dart';
import 'package:http/http.dart';
import 'package:injectable/injectable.dart';

///
/// Convenience class which handles timeout errors.
///
@Injectable(as: BaseClient)
@Named("timeoutClient")
class TimeoutClient implements BaseClient {
  static const Duration requestTimeout = Duration(seconds: 25);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    return getIt<BaseClient>().send(request).timeout(
          requestTimeout,
          onTimeout: () => Future.error(const ErrorMessage(ErrorCode.requestTimedOut)),
        );
  }

  @override
  void close() {
    getIt<BaseClient>().close();
  }

  @override
  Future<Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return _handle400Error(
      await getIt<BaseClient>()
          .delete(url, headers: headers, body: body, encoding: encoding)
          .timeout(
            requestTimeout,
            onTimeout: () => Future.error(const ErrorMessage(ErrorCode.requestTimedOut)),
          ),
    );
  }

  @override
  Future<Response> get(Uri url, {Map<String, String>? headers}) async {
    return _handle400Error(
      await getIt<BaseClient>().get(url, headers: headers).timeout(
            requestTimeout,
            onTimeout: () => Future.error(const ErrorMessage(ErrorCode.requestTimedOut)),
          ),
    );
  }

  @override
  Future<Response> head(Uri url, {Map<String, String>? headers}) async {
    return _handle400Error(
      await getIt<BaseClient>().head(url, headers: headers).timeout(
            requestTimeout,
            onTimeout: () => Future.error(const ErrorMessage(ErrorCode.requestTimedOut)),
          ),
    );
  }

  @override
  Future<Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return _handle400Error(
      await getIt<BaseClient>()
          .patch(url, headers: headers, body: body, encoding: encoding)
          .timeout(
            requestTimeout,
            onTimeout: () => Future.error(const ErrorMessage(ErrorCode.requestTimedOut)),
          ),
    );
  }

  @override
  Future<Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return _handle400Error(
      await getIt<BaseClient>().post(url, headers: headers, body: body, encoding: encoding).timeout(
            requestTimeout,
            onTimeout: () => Future.error(const ErrorMessage(ErrorCode.requestTimedOut)),
          ),
    );
  }

  @override
  Future<Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return _handle400Error(
      await getIt<BaseClient>().put(url, headers: headers, body: body, encoding: encoding).timeout(
            requestTimeout,
            onTimeout: () => Future.error(const ErrorMessage(ErrorCode.requestTimedOut)),
          ),
    );
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) async {
    return getIt<BaseClient>().read(url, headers: headers).timeout(
          requestTimeout,
          onTimeout: () => Future.error(const ErrorMessage(ErrorCode.requestTimedOut)),
        );
  }

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) {
    return getIt<BaseClient>().readBytes(url, headers: headers).timeout(
          requestTimeout,
          onTimeout: () => Future.error(const ErrorMessage(ErrorCode.requestTimedOut)),
        );
  }

  Response _handle400Error(Response response) {
    if (response.statusCode == 400) {
      // try to parse contained error message, otherwise return response
      final JSON json = jsonDecode(utf8.decode(response.bodyBytes));
      final Map<String, String> errorMessages = {};
      //TODO: This could be simplified, look at error message format of paperless-ngx
      for (final entry in json.entries) {
        if (entry.value is List) {
          errorMessages.putIfAbsent(entry.key, () => (entry.value as List).cast<String>().first);
        } else if (entry.value is String) {
          errorMessages.putIfAbsent(entry.key, () => entry.value);
        } else {
          errorMessages.putIfAbsent(entry.key, () => entry.value.toString());
        }
      }
      throw errorMessages;
    }
    return response;
  }
}
