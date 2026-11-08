import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/workflow_action_email.dart';
import 'package:paperless_mobile/api/models/workflow_action_type_enum.dart';
import 'package:paperless_mobile/api/models/workflow_action_webhook.dart';

part 'workflow_action.freezed.dart';
part 'workflow_action.g.dart';

@Freezed(toJson: false, fromJson: true)
abstract class WorkflowAction with _$WorkflowAction {
  factory WorkflowAction({
    int? id,
    // minimum: 0.0
    // maximum: 2.147483647E9
    WorkflowActionTypeEnum? type,

    /// Assign a document title, must be a Jinja2 template, see documentation.
    String? assignTitle,
    List<int>? assignTags,
    int? assignCorrespondent,
    int? assignDocumentType,
    int? assignStoragePath,
    int? assignOwner,
    List<int>? assignViewUsers,
    List<int>? assignViewGroups,
    List<int>? assignChangeUsers,
    List<int>? assignChangeGroups,
    List<int>? assignCustomFields,

    /// Optional values to assign to the custom fields.
    Object? assignCustomFieldsValues,
    bool? removeAllTags,
    List<int>? removeTags,
    bool? removeAllCorrespondents,
    List<int>? removeCorrespondents,
    bool? removeAllDocumentTypes,
    List<int>? removeDocumentTypes,
    bool? removeAllStoragePaths,
    List<int>? removeStoragePaths,
    List<int>? removeCustomFields,
    bool? removeAllCustomFields,
    bool? removeAllOwners,
    List<int>? removeOwners,
    bool? removeAllPermissions,
    List<int>? removeViewUsers,
    List<int>? removeViewGroups,
    List<int>? removeChangeUsers,
    List<int>? removeChangeGroups,
    WorkflowActionEmail? email,
    WorkflowActionWebhook? webhook,
    List<String>? passwords,
    List<String>? aiSuggestionFields,
    bool? aiCreateMissing,
    bool? aiOverwriteExisting,
  }) = _WorkflowAction;

  factory WorkflowAction.fromJson(Map<String, dynamic> json) =>
      _$WorkflowActionFromJson(json);
}
