import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/features/document_chat/cubit/document_chat_cubit.dart';
import 'package:paperless_mobile/features/document_chat/model/document_chat_message.dart';

class _FakeChatApi implements PaperlessChatApi {
  final answer = StreamController<DocumentChatResponse>();
  String? question;
  int? documentId;

  @override
  Stream<DocumentChatResponse> chat(String question, {int? documentId}) {
    this.question = question;
    this.documentId = documentId;
    return answer.stream;
  }
}

void main() {
  late _FakeChatApi api;
  late DocumentChatCubit cubit;

  setUp(() {
    api = _FakeChatApi();
    cubit = DocumentChatCubit(api, documentId: 7);
  });

  tearDown(() => cubit.close());

  test('streams the answer into an assistant message', () async {
    final done = cubit.ask('When is it due?');

    expect(api.question, 'When is it due?');
    expect(api.documentId, 7);
    expect(cubit.state.isAnswering, isTrue);
    expect(cubit.state.messages.first.role, DocumentChatRole.user);
    expect(cubit.state.messages.first.content, 'When is it due?');

    api.answer.add(DocumentChatResponse(content: 'It is due '));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.messages.last.content, 'It is due ');

    api.answer.add(
      DocumentChatResponse(
        content: 'It is due tomorrow.',
        references: [DocumentChatReference(id: 7, title: 'Invoice')],
      ),
    );
    await api.answer.close();
    await done;

    final answer = cubit.state.messages.last;
    expect(cubit.state.isAnswering, isFalse);
    expect(answer.role, DocumentChatRole.assistant);
    expect(answer.content, 'It is due tomorrow.');
    expect(answer.references, [DocumentChatReference(id: 7, title: 'Invoice')]);
    expect(answer.error, isNull);
  });

  test('ignores questions while an answer is streamed', () async {
    unawaited(cubit.ask('First question'));
    await cubit.ask('Second question');

    expect(api.question, 'First question');
    expect(cubit.state.messages, hasLength(2));
  });

  test('marks the answer as failed on error', () async {
    final done = cubit.ask('When is it due?');

    api.answer.addError(
      const PaperlessApiException(ErrorCode.documentChatFailed),
    );
    await done;

    final answer = cubit.state.messages.last;
    expect(cubit.state.isAnswering, isFalse);
    expect(answer.error, isA<PaperlessApiException>());
  });
}
