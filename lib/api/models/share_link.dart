import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/file_version_enum.dart';

part 'share_link.freezed.dart';
part 'share_link.g.dart';

@Freezed(toJson: false, fromJson: true)
abstract class ShareLink with _$ShareLink {
  factory ShareLink({
    required int id,
    required DateTime created,
    DateTime? expiration,
    required String slug,
    int? document,
    String? documentTitle,
    FileVersionEnum? fileVersion,
  }) = _ShareLink;

  factory ShareLink.fromJson(Map<String, dynamic> json) =>
      _$ShareLinkFromJson(json);
}
