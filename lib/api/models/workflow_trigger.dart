import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/schedule_date_field_enum.dart';
import 'package:paperless_mobile/api/models/sources_enum.dart';
import 'package:paperless_mobile/api/models/workflow_trigger_matching_algorithm_enum.dart';
import 'package:paperless_mobile/api/models/workflow_trigger_type_enum.dart';

part 'workflow_trigger.freezed.dart';
part 'workflow_trigger.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class WorkflowTrigger with _$WorkflowTrigger {
  factory WorkflowTrigger({
    int? id,
    List<SourcesEnum>? sources,
    required WorkflowTriggerTypeEnum type,

    /// Only consume documents with a path that matches this if specified. Wildcards specified as * are allowed. Case insensitive.
    String? filterPath,

    /// Only consume documents which entirely match this filename if specified. Wildcards such as *.pdf or *invoice* are allowed. Case insensitive.
    String? filterFilename,
    int? filterMailrule,
    String? filterCustomFieldQuery,
    // minimum: 0.0
    // maximum: 2.147483647E9
    WorkflowTriggerMatchingAlgorithmEnum? matchingAlgorithm,
    String? match,
    bool? isInsensitive,
    List<int>? filterHasTags,
    List<int>? filterHasAllTags,
    List<int>? filterHasAnyCorrespondents,
    List<int>? filterHasAnyDocumentTypes,
    List<int>? filterHasAnyStoragePaths,
    List<int>? filterHasNotCorrespondents,
    List<int>? filterHasNotDocumentTypes,
    List<int>? filterHasNotStoragePaths,
    List<int>? filterHasNotTags,
    int? filterHasCorrespondent,
    int? filterHasDocumentType,
    int? filterHasStoragePath,

    /// The number of days to offset the schedule trigger by.
    // minimum: -2147483648
    // maximum: 2147483647
    int? scheduleOffsetDays,

    /// If the schedule should be recurring.
    bool? scheduleIsRecurring,

    /// The number of days between recurring schedule triggers.
    // minimum: 1
    // maximum: 2147483647
    int? scheduleRecurringIntervalDays,

    /// The field to check for a schedule trigger.  * `added` - Added * `created` - Created * `modified` - Modified * `custom_field` - Custom Field
    ScheduleDateFieldEnum? scheduleDateField,
    int? scheduleDateCustomField,
  }) = _WorkflowTrigger;

  factory WorkflowTrigger.fromJson(Map<String, dynamic> json) =>
      _$WorkflowTriggerFromJson(json);
}
