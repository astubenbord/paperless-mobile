import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_version_info.freezed.dart';
part 'document_version_info.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class DocumentVersionInfo with _$DocumentVersionInfo {
  factory DocumentVersionInfo({
    required int id,
    required DateTime added,
    String? versionLabel,
    String? checksum,
    required bool isRoot,
  }) = _DocumentVersionInfo;

  factory DocumentVersionInfo.fromJson(Map<String, dynamic> json) =>
      _$DocumentVersionInfoFromJson(json);
}
