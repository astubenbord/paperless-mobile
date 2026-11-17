import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/core/service/dio_file_service.dart';

class _FakeHttpClientAdapter implements HttpClientAdapter {
  final int statusCode;
  RequestOptions? lastRequest;

  _FakeHttpClientAdapter(this.statusCode);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromBytes(
      statusCode == HttpStatus.ok ? [1, 2, 3] : [],
      statusCode,
      headers: {
        HttpHeaders.etagHeader: ['"abc"'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DioFileService _service(_FakeHttpClientAdapter adapter) =>
    DioFileService(Dio()..httpClientAdapter = adapter);

void main() {
  group('DioFileService', () {
    test('returns 200 responses', () async {
      final response = await _service(
        _FakeHttpClientAdapter(HttpStatus.ok),
      ).get('https://example.com/api/documents/1/thumb/');
      expect(response.statusCode, HttpStatus.ok);
      expect(await response.content.expand((e) => e).toList(), [1, 2, 3]);
    });

    test(
      'returns 304 Not Modified to the cache manager instead of throwing',
      () async {
        final adapter = _FakeHttpClientAdapter(HttpStatus.notModified);
        final response = await _service(adapter).get(
          'https://example.com/api/documents/1/thumb/',
          headers: {HttpHeaders.ifNoneMatchHeader: '"abc"'},
        );
        expect(response.statusCode, HttpStatus.notModified);
        expect(response.eTag, '"abc"');
        expect(
          adapter.lastRequest?.headers[HttpHeaders.ifNoneMatchHeader],
          '"abc"',
        );
      },
    );

    test('still throws on error status codes', () async {
      expect(
        _service(
          _FakeHttpClientAdapter(HttpStatus.notFound),
        ).get('https://example.com/api/documents/1/thumb/'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
