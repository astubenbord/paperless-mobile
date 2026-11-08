import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:paperless_mobile/api/models/saved_view.dart';
import 'package:paperless_mobile/core/security/session_manager_impl.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart' as l;

/// Simulates a paperless-ngx 3.x server (API v10, v9 still allowed), which
/// only includes the legacy saved view fields when v9 is requested.
class _FakeServerAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.path == '/api/schema/') {
      return ResponseBody.fromString(
        '',
        200,
        headers: {
          'x-api-version': ['10'],
        },
      );
    }
    final accept = options.headers[HttpHeaders.acceptHeader] as String?;
    final view = <String, dynamic>{
      'id': 1,
      'name': 'Inbox',
      'filter_rules': [],
      'user_can_change': true,
      if (accept?.contains('version=9') ?? false) ...{
        'show_on_dashboard': true,
        'show_in_sidebar': true,
      },
    };
    return ResponseBody.fromString(
      jsonEncode([view]),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  l.logger = Logger(level: Level.off);

  late SessionManagerImpl sessionManager;
  late _FakeServerAdapter adapter;

  setUp(() {
    sessionManager = SessionManagerImpl()
      ..updateSettings(baseUrl: 'https://paperless.example', authToken: 'x');
    adapter = _FakeServerAdapter();
    sessionManager.client.httpClientAdapter = adapter;
  });

  test('pins latest supported api version on newer servers', () async {
    final response = await sessionManager.client.get('/api/saved_views/');

    expect(
      adapter.requests.last.headers[HttpHeaders.acceptHeader],
      'application/json; version=9',
    );
    final view = SavedView.fromJson(response.data[0]);
    expect(view.showOnDashboard, isTrue);
    expect(view.showInSidebar, isTrue);
  });

  test('resolves api version only once', () async {
    await Future.wait([
      sessionManager.client.get('/api/saved_views/'),
      sessionManager.client.get('/api/saved_views/'),
    ]);
    await sessionManager.client.get('/api/saved_views/');

    expect(
      adapter.requests.where((r) => r.path == '/api/schema/'),
      hasLength(1),
    );
    expect(await sessionManager.getApiVersion(), 10);
  });

  test('parses saved views without legacy fields (API v10)', () {
    final view = SavedView.fromJson({
      'id': 1,
      'name': 'Inbox',
      'filter_rules': [],
      'user_can_change': true,
    });
    expect(view.showOnDashboard, isFalse);
    expect(view.showInSidebar, isFalse);
  });
}
