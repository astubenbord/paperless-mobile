import 'package:json_annotation/json_annotation.dart';

part 'share_link_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ShareLink {
  final int? id;
  final String? slug;
  final int document;
  final String fileVersion;
  final DateTime? expiration;
  final DateTime? created;

  const ShareLink({
    this.id,
    this.slug,
    required this.document,
    this.fileVersion = 'archive',
    this.expiration,
    this.created,
  });

  String buildUrl(String serverUrl) {
    return '$serverUrl/share/$slug';
  }

  factory ShareLink.fromJson(Map<String, dynamic> json) =>
      _$ShareLinkFromJson(json);

  Map<String, dynamic> toJson() => _$ShareLinkToJson(this);
}
