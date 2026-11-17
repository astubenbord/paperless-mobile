import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/paperless_api.dart';

part 'document_chat_message.freezed.dart';

enum DocumentChatRole { user, assistant }

@freezed
abstract class DocumentChatMessage with _$DocumentChatMessage {
  const factory DocumentChatMessage({
    required DocumentChatRole role,
    required String content,
    @Default([]) List<DocumentChatReference> references,
    @Default(false) bool isStreaming,
    Object? error,
  }) = _DocumentChatMessage;
}
