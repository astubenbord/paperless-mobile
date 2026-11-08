import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/workflow_action_email_request.dart';
import 'package:paperless_mobile/api/models/workflow_action_type_enum.dart';
import 'package:paperless_mobile/api/models/workflow_action_webhook_request.dart';
import 'package:paperless_mobile/api/utils/patched_value.dart';

part 'patched_workflow_action_request.g.dart';

@JsonSerializable(
  createFactory: false,
  createToJson: true,
  includeIfNull: false,
)
class PatchedWorkflowActionRequest {
  final PatchedValue<int?>? id;

  // minimum: 0.0
  // maximum: 2.147483647E9
  final PatchedValue<WorkflowActionTypeEnum?>? type;

  /// Assign a document title, must be a Jinja2 template, see documentation.
  final PatchedValue<String?>? assignTitle;
  final PatchedValue<List<int>?>? assignTags;
  final PatchedValue<int?>? assignCorrespondent;
  final PatchedValue<int?>? assignDocumentType;
  final PatchedValue<int?>? assignStoragePath;
  final PatchedValue<int?>? assignOwner;
  final PatchedValue<List<int>?>? assignViewUsers;
  final PatchedValue<List<int>?>? assignViewGroups;
  final PatchedValue<List<int>?>? assignChangeUsers;
  final PatchedValue<List<int>?>? assignChangeGroups;
  final PatchedValue<List<int>?>? assignCustomFields;

  /// Optional values to assign to the custom fields.
  final PatchedValue<Object?>? assignCustomFieldsValues;
  final PatchedValue<bool?>? removeAllTags;
  final PatchedValue<List<int>?>? removeTags;
  final PatchedValue<bool?>? removeAllCorrespondents;
  final PatchedValue<List<int>?>? removeCorrespondents;
  final PatchedValue<bool?>? removeAllDocumentTypes;
  final PatchedValue<List<int>?>? removeDocumentTypes;
  final PatchedValue<bool?>? removeAllStoragePaths;
  final PatchedValue<List<int>?>? removeStoragePaths;
  final PatchedValue<List<int>?>? removeCustomFields;
  final PatchedValue<bool?>? removeAllCustomFields;
  final PatchedValue<bool?>? removeAllOwners;
  final PatchedValue<List<int>?>? removeOwners;
  final PatchedValue<bool?>? removeAllPermissions;
  final PatchedValue<List<int>?>? removeViewUsers;
  final PatchedValue<List<int>?>? removeViewGroups;
  final PatchedValue<List<int>?>? removeChangeUsers;
  final PatchedValue<List<int>?>? removeChangeGroups;
  final PatchedValue<WorkflowActionEmailRequest?>? email;
  final PatchedValue<WorkflowActionWebhookRequest?>? webhook;
  final PatchedValue<List<String>?>? passwords;
  final PatchedValue<List<String>?>? aiSuggestionFields;
  final PatchedValue<bool?>? aiCreateMissing;
  final PatchedValue<bool?>? aiOverwriteExisting;

  PatchedWorkflowActionRequest({
    this.id,
    this.type,
    this.assignTitle,
    this.assignTags,
    this.assignCorrespondent,
    this.assignDocumentType,
    this.assignStoragePath,
    this.assignOwner,
    this.assignViewUsers,
    this.assignViewGroups,
    this.assignChangeUsers,
    this.assignChangeGroups,
    this.assignCustomFields,
    this.assignCustomFieldsValues,
    this.removeAllTags,
    this.removeTags,
    this.removeAllCorrespondents,
    this.removeCorrespondents,
    this.removeAllDocumentTypes,
    this.removeDocumentTypes,
    this.removeAllStoragePaths,
    this.removeStoragePaths,
    this.removeCustomFields,
    this.removeAllCustomFields,
    this.removeAllOwners,
    this.removeOwners,
    this.removeAllPermissions,
    this.removeViewUsers,
    this.removeViewGroups,
    this.removeChangeUsers,
    this.removeChangeGroups,
    this.email,
    this.webhook,
    this.passwords,
    this.aiSuggestionFields,
    this.aiCreateMissing,
    this.aiOverwriteExisting,
  });

  Map<String, dynamic> toJson() =>
      processPatchedValueJson(_$PatchedWorkflowActionRequestToJson(this));
}
