import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/api/paperless_api.dart';

/// Responds to every request with the given [chunks] and records the request.
class _FakeAdapter implements HttpClientAdapter {
  final int statusCode;
  final List<List<int>> chunks;
  RequestOptions? request;

  _FakeAdapter({this.statusCode = 200, this.chunks = const []});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody(
      Stream.fromIterable(chunks.map(Uint8List.fromList)),
      statusCode,
    );
  }

  @override
  void close({bool force = false}) {}
}

const metadataDelimiter = '\n\n__PAPERLESS_CHAT_METADATA__';

void main() {
  late _FakeAdapter adapter;
  late PaperlessChatApi api;

  void setUpApi(_FakeAdapter fakeAdapter) {
    adapter = fakeAdapter;
    api = PaperlessChatApiImpl(Dio()..httpClientAdapter = adapter);
  }

  test('posts the question about a single document', () async {
    setUpApi(_FakeAdapter(chunks: [utf8.encode('Answer')]));

    await api.chat('When is it due?', documentId: 3).drain<void>();

    expect(adapter.request!.method, 'POST');
    expect(adapter.request!.path, '/api/documents/chat/');
    expect(adapter.request!.data, {'q': 'When is it due?', 'document_id': 3});
  });

  test('omits the document id when asking about all documents', () async {
    setUpApi(_FakeAdapter(chunks: [utf8.encode('Answer')]));

    await api.chat('When is it due?').drain<void>();

    expect(adapter.request!.data, {'q': 'When is it due?'});
  });

  test('emits the answer received so far', () async {
    setUpApi(
      _FakeAdapter(chunks: [utf8.encode('It is due '), utf8.encode('today.')]),
    );

    final responses = await api.chat('When is it due?').toList();

    expect(responses.map((response) => response.content), [
      'It is due ',
      'It is due today.',
    ]);
  });

  test('decodes characters split across chunks', () async {
    final bytes = utf8.encode('Fällig am 1. März');
    setUpApi(_FakeAdapter(chunks: [bytes.sublist(0, 2), bytes.sublist(2)]));

    final response = await api.chat('Wann?').last;

    expect(response.content, 'Fällig am 1. März');
  });

  test('splits off the references from the answer', () async {
    setUpApi(
      _FakeAdapter(
        chunks: [
          utf8.encode('It is due today.'),
          utf8.encode('$metadataDelimiter{"references":[{"id":1,'),
          utf8.encode('"title":"Invoice"},{"id":42,"title":"Reminder"}]}'),
        ],
      ),
    );

    final responses = await api.chat('When is it due?').toList();

    expect(responses[1], DocumentChatResponse(content: 'It is due today.'));
    expect(
      responses[2],
      DocumentChatResponse(
        content: 'It is due today.',
        references: [
          DocumentChatReference(id: 1, title: 'Invoice'),
          DocumentChatReference(id: 42, title: 'Reminder'),
        ],
      ),
    );
  });

  test('throws a chat error if the server rejects the request', () async {
    setUpApi(
      _FakeAdapter(
        statusCode: 400,
        chunks: [utf8.encode('AI is required for this feature')],
      ),
    );

    await expectLater(
      api.chat('When is it due?').drain<void>(),
      throwsA(
        isA<PaperlessApiException>().having(
          (e) => e.code,
          'code',
          ErrorCode.documentChatFailed,
        ),
      ),
    );
  });
}
