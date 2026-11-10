import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_chat_reference.freezed.dart';
part 'document_chat_reference.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class DocumentChatReference with _$DocumentChatReference {
  factory DocumentChatReference({required int id, required String title}) =
      _DocumentChatReference;

  factory DocumentChatReference.fromJson(Map<String, dynamic> json) =>
      _$DocumentChatReferenceFromJson(json);
}
