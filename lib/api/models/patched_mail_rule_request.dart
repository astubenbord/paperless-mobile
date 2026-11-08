import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/assign_correspondent_from_enum.dart';
import 'package:paperless_mobile/api/models/assign_title_from_enum.dart';
import 'package:paperless_mobile/api/models/attachment_type_enum.dart';
import 'package:paperless_mobile/api/models/consumption_scope_enum.dart';
import 'package:paperless_mobile/api/models/correspondent_request_set_permissions.dart';
import 'package:paperless_mobile/api/models/mail_rule_action_enum.dart';
import 'package:paperless_mobile/api/models/pdf_layout_enum.dart';
import 'package:paperless_mobile/api/utils/patched_value.dart';

part 'patched_mail_rule_request.g.dart';

@JsonSerializable(
  createFactory: false,
  createToJson: true,
  includeIfNull: false,
)
class PatchedMailRuleRequest {
  final PatchedValue<String?>? name;
  final PatchedValue<int?>? account;
  final PatchedValue<bool?>? enabled;

  /// Subfolders must be separated by a delimiter, often a dot ('.') or slash ('/'), but it varies by mail server.
  final PatchedValue<String?>? folder;
  final PatchedValue<String?>? filterFrom;
  final PatchedValue<String?>? filterTo;
  final PatchedValue<String?>? filterSubject;
  final PatchedValue<String?>? filterBody;

  /// Only consume documents which entirely match this filename if specified. Wildcards such as *.pdf or *invoice* are allowed. Case insensitive.
  final PatchedValue<String?>? filterAttachmentFilenameInclude;

  /// Do not consume documents which entirely match this filename if specified. Wildcards such as *.pdf or *invoice* are allowed. Case insensitive.
  final PatchedValue<String?>? filterAttachmentFilenameExclude;

  /// Specified in days.
  // minimum: 0
  // maximum: 2147483647
  final PatchedValue<int?>? maximumAge;

  // minimum: 0.0
  // maximum: 2.147483647E9
  final PatchedValue<MailRuleActionEnum?>? action;
  final PatchedValue<String?>? actionParameter;

  // minimum: 0.0
  // maximum: 2.147483647E9
  final PatchedValue<AssignTitleFromEnum?>? assignTitleFrom;
  final PatchedValue<List<int>?>? assignTags;

  // minimum: 0.0
  // maximum: 2.147483647E9
  final PatchedValue<AssignCorrespondentFromEnum?>? assignCorrespondentFrom;
  final PatchedValue<int?>? assignCorrespondent;
  final PatchedValue<int?>? assignDocumentType;
  final PatchedValue<bool?>? assignOwnerFromRule;
  final PatchedValue<int?>? order;

  /// Inline attachments include embedded images, so it's best to combine this option with a filename filter.  * `1` - Only process attachments. * `2` - Process all files, including 'inline' attachments.
  // minimum: 0.0
  // maximum: 2.147483647E9
  final PatchedValue<AttachmentTypeEnum?>? attachmentType;

  // minimum: 0.0
  // maximum: 2.147483647E9
  final PatchedValue<ConsumptionScopeEnum?>? consumptionScope;

  // minimum: 0.0
  // maximum: 2.147483647E9
  final PatchedValue<PdfLayoutEnum?>? pdfLayout;
  final PatchedValue<bool?>? stopProcessing;
  final PatchedValue<int?>? owner;
  final PatchedValue<CorrespondentRequestSetPermissions?>? setPermissions;

  PatchedMailRuleRequest({
    this.name,
    this.account,
    this.enabled,
    this.folder,
    this.filterFrom,
    this.filterTo,
    this.filterSubject,
    this.filterBody,
    this.filterAttachmentFilenameInclude,
    this.filterAttachmentFilenameExclude,
    this.maximumAge,
    this.action,
    this.actionParameter,
    this.assignTitleFrom,
    this.assignTags,
    this.assignCorrespondentFrom,
    this.assignCorrespondent,
    this.assignDocumentType,
    this.assignOwnerFromRule,
    this.order,
    this.attachmentType,
    this.consumptionScope,
    this.pdfLayout,
    this.stopProcessing,
    this.owner,
    this.setPermissions,
  });

  Map<String, dynamic> toJson() =>
      processPatchedValueJson(_$PatchedMailRuleRequestToJson(this));
}
