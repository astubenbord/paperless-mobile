import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/core/tunnel/http_prober.dart';

void main() {
  test('recognizes Paperless responses and rejects proxies', () async {
    for (final entry in <(HttpProbeResult, bool)>[
      (const HttpProbeResult(statusCode: 403, server: 'openresty'), false),
      (const HttpProbeResult(statusCode: 401, wwwAuthenticate: 'Token'), true),
      (
        const HttpProbeResult(statusCode: 200, contentType: 'application/json'),
        true,
      ),
      (const HttpProbeResult(statusCode: 302, contentType: 'text/html'), false),
    ]) {
      final probe = HttpProber(
        request: (uri) async {
          expect(uri.path, '/base/api/ui_settings/');
          return entry.$1;
        },
      );
      expect(
        (await probe.probe('https://example.com/base/')).isPaperless,
        entry.$2,
      );
    }
    final timeout = HttpProber(
      request: (_) async => throw TimeoutException('timeout'),
    );
    expect((await timeout.probe('https://example.com')).isPaperless, false);
  });
}
