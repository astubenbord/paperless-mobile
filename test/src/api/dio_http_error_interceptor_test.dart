import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/api/paperless_api.dart';

class _FakeAdapter implements HttpClientAdapter {
  final int statusCode;

  _FakeAdapter(this.statusCode);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('Server Error', statusCode);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('passes on errors other than 400 instead of swallowing them', () async {
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter(500)
      ..interceptors.add(DioHttpErrorInterceptor());

    await expectLater(
      dio.get('/api/documents/').timeout(const Duration(seconds: 5)),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          500,
        ),
      ),
    );
  });
}
