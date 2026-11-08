// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/assign_correspondent_from_enum.dart';
import 'package:paperless_mobile/api/models/assign_title_from_enum.dart';
import 'package:paperless_mobile/api/models/attachment_type_enum.dart';
import 'package:paperless_mobile/api/models/consumption_scope_enum.dart';
import 'package:paperless_mobile/api/models/mail_rule_action_enum.dart';
import 'package:paperless_mobile/api/models/pdf_layout_enum.dart';

part 'mail_rule.freezed.dart';
part 'mail_rule.g.dart';

@Freezed(toJson: false, fromJson: true)
abstract class MailRule with _$MailRule {
  factory MailRule({
    required int id,
    required String name,
    required int account,
    bool? enabled,

    /// Subfolders must be separated by a delimiter, often a dot ('.') or slash ('/'), but it varies by mail server.
    String? folder,
    String? filterFrom,
    String? filterTo,
    String? filterSubject,
    String? filterBody,

    /// Only consume documents which entirely match this filename if specified. Wildcards such as *.pdf or *invoice* are allowed. Case insensitive.
    String? filterAttachmentFilenameInclude,

    /// Do not consume documents which entirely match this filename if specified. Wildcards such as *.pdf or *invoice* are allowed. Case insensitive.
    String? filterAttachmentFilenameExclude,

    /// Specified in days.
    // minimum: 0
    // maximum: 2147483647
    int? maximumAge,
    // minimum: 0.0
    // maximum: 2.147483647E9
    MailRuleActionEnum? action,
    @JsonKey(includeIfNull: false) @Default('') String? actionParameter,
    // minimum: 0.0
    // maximum: 2.147483647E9
    AssignTitleFromEnum? assignTitleFrom,
    List<int>? assignTags,
    // minimum: 0.0
    // maximum: 2.147483647E9
    AssignCorrespondentFromEnum? assignCorrespondentFrom,
    int? assignCorrespondent,
    int? assignDocumentType,
    bool? assignOwnerFromRule,
    int? order,

    /// Inline attachments include embedded images, so it's best to combine this option with a filename filter.  * `1` - Only process attachments. * `2` - Process all files, including 'inline' attachments.
    // minimum: 0.0
    // maximum: 2.147483647E9
    AttachmentTypeEnum? attachmentType,
    // minimum: 0.0
    // maximum: 2.147483647E9
    ConsumptionScopeEnum? consumptionScope,
    // minimum: 0.0
    // maximum: 2.147483647E9
    PdfLayoutEnum? pdfLayout,
    bool? stopProcessing,
    int? owner,
    required bool userCanChange,
  }) = _MailRule;

  factory MailRule.fromJson(Map<String, dynamic> json) =>
      _$MailRuleFromJson(json);
}
