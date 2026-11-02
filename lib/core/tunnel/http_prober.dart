import 'dart:async';
import 'dart:io';

class HttpProbeResult {
  const HttpProbeResult({
    this.statusCode,
    this.wwwAuthenticate,
    this.contentType,
    this.server,
    this.error,
  });
  final int? statusCode;
  final String? wwwAuthenticate;
  final String? contentType;
  final String? server;
  final Object? error;

  bool get isPaperless =>
      (statusCode == 200 || statusCode == 401) &&
      (wwwAuthenticate != null ||
          (contentType?.toLowerCase().contains('application/json') ?? false));
}

typedef HttpProbeRequest = Future<HttpProbeResult> Function(Uri uri);

class HttpProber {
  HttpProber({HttpProbeRequest? request}) : _request = request ?? _httpRequest;
  final HttpProbeRequest _request;

  Future<HttpProbeResult> probe(String url) async {
    try {
      final base = Uri.parse(url);
      final path = base.path.replaceFirst(RegExp(r'/+$'), '');
      final uri = base.replace(
        path: '$path/api/ui_settings/',
        query: '',
        fragment: '',
      );
      return await _request(uri).timeout(const Duration(seconds: 2));
    } catch (error) {
      return HttpProbeResult(error: error);
    }
  }

  static Future<HttpProbeResult> _httpRequest(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final result = HttpProbeResult(
        statusCode: response.statusCode,
        wwwAuthenticate: response.headers.value(
          HttpHeaders.wwwAuthenticateHeader,
        ),
        contentType: response.headers.value(HttpHeaders.contentTypeHeader),
        server: response.headers.value(HttpHeaders.serverHeader),
      );
      await response.listen((_) {}).cancel();
      return result;
    } finally {
      client.close(force: true);
    }
  }
}
