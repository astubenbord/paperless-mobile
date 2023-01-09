import 'package:json_annotation/json_annotation.dart';

part 'open_created_document_notification_payload.g.dart';

@JsonSerializable()
class CreateDocumentSuccessNotificationResponsePayload {
  final int documentId;

  CreateDocumentSuccessNotificationResponsePayload(this.documentId);

  factory CreateDocumentSuccessNotificationResponsePayload.fromJson(
          Map<String, dynamic> json) =>
      _$CreateDocumentSuccessNotificationResponsePayloadFromJson(json);

  Map<String, dynamic> toJson() =>
      _$CreateDocumentSuccessNotificationResponsePayloadToJson(this);
}
