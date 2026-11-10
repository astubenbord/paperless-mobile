import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/document_chat_reference.dart';

part 'document_chat_response.freezed.dart';

@freezed
abstract class DocumentChatResponse with _$DocumentChatResponse {
  factory DocumentChatResponse({
    required String content,
    @Default([]) List<DocumentChatReference> references,
  }) = _DocumentChatResponse;
}
