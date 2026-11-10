part of 'document_chat_cubit.dart';

@freezed
abstract class DocumentChatState with _$DocumentChatState {
  const DocumentChatState._();
  const factory DocumentChatState({
    @Default([]) List<DocumentChatMessage> messages,
  }) = _DocumentChatState;

  bool get isAnswering => messages.lastOrNull?.isStreaming ?? false;
}
