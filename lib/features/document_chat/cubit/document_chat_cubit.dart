import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/features/document_chat/model/document_chat_message.dart';

part 'document_chat_cubit.freezed.dart';
part 'document_chat_state.dart';

class DocumentChatCubit extends Cubit<DocumentChatState> {
  final PaperlessChatApi _api;
  final int? documentId;

  StreamSubscription<DocumentChatResponse>? _answerSubscription;

  DocumentChatCubit(this._api, {this.documentId})
    : super(const DocumentChatState());

  /// Completes once the answer has been fully received or failed.
  Future<void> ask(String question) {
    if (state.isAnswering || question.trim().isEmpty) {
      return Future.value();
    }
    final completer = Completer<void>();
    emit(
      state.copyWith(
        messages: [
          ...state.messages,
          DocumentChatMessage(role: DocumentChatRole.user, content: question),
          const DocumentChatMessage(
            role: DocumentChatRole.assistant,
            content: '',
            isStreaming: true,
          ),
        ],
      ),
    );
    _answerSubscription = _api
        .chat(question, documentId: documentId)
        .listen(
          (response) => _updateAnswer(
            (answer) => answer.copyWith(
              content: response.content,
              references: response.references,
            ),
          ),
          onError: (Object error) {
            _updateAnswer(
              (answer) => answer.copyWith(isStreaming: false, error: error),
            );
            completer.complete();
          },
          onDone: () {
            _updateAnswer((answer) => answer.copyWith(isStreaming: false));
            completer.complete();
          },
          cancelOnError: true,
        );
    return completer.future;
  }

  void _updateAnswer(
    DocumentChatMessage Function(DocumentChatMessage answer) update,
  ) {
    emit(
      state.copyWith(
        messages: [
          ...state.messages.take(state.messages.length - 1),
          update(state.messages.last),
        ],
      ),
    );
  }

  @override
  Future<void> close() async {
    await _answerSubscription?.cancel();
    return super.close();
  }
}
