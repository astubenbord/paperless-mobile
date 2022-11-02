import 'package:equatable/equatable.dart';
import 'package:paperless_mobile/core/type/json.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/correspondent_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/document_type_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/query_type.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/storage_path_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/tags_query.dart';
import 'package:paperless_mobile/util.dart';

class FilterRule with EquatableMixin {
  static const int titleRule = 0;
  static const int asnRule = 2;
  static const int correspondentRule = 3;
  static const int documentTypeRule = 4;
  static const int tagRule = 6;
  static const int createdBeforeRule = 8;
  static const int createdAfterRule = 9;
  static const int addedBeforeRule = 13;
  static const int addedAfterRule = 14;
  static const int titleAndContentRule = 19;
  static const int extendedRule = 20;
  static const int storagePathRule = 25;
  // Currently unsupported view optiosn:
  static const int _content = 1;
  static const int _isInInbox = 5;
  static const int _hasAnyTag = 7;
  static const int _createdYearIs = 10;
  static const int _createdMonthIs = 11;
  static const int _createdDayIs = 12;
  static const int _modifiedBefore = 15;
  static const int _modifiedAfter = 16;
  static const int _doesNotHaveTag = 17;
  static const int _doesNotHaveAsn = 18;
  static const int _moreLikeThis = 21;
  static const int _hasTagsIn = 22;
  static const int _asnGreaterThan = 23;
  static const int _asnLessThan = 24;

  final int ruleType;
  final String? value;

  FilterRule(this.ruleType, this.value);

  FilterRule.fromJson(JSON json)
      : ruleType = json['rule_type'],
        value = json['value'];

  JSON toJson() {
    return {
      'rule_type': ruleType,
      'value': value,
    };
  }

  DocumentFilter applyToFilter(final DocumentFilter filter) {
    //TODO: Check in profiling mode if this is inefficient enough to cause stutters...
    switch (ruleType) {
      case titleRule:
        return filter.copyWith(queryText: value, queryType: QueryType.title);
      case documentTypeRule:
        return filter.copyWith(
          documentType: value == null
              ? const DocumentTypeQuery.notAssigned()
              : DocumentTypeQuery.fromId(int.parse(value!)),
        );
      case correspondentRule:
        return filter.copyWith(
          correspondent: value == null
              ? const CorrespondentQuery.notAssigned()
              : CorrespondentQuery.fromId(int.parse(value!)),
        );
      case storagePathRule:
        return filter.copyWith(
          storagePath: value == null
              ? const StoragePathQuery.notAssigned()
              : StoragePathQuery.fromId(int.parse(value!)),
        );
      case tagRule:
        return filter.copyWith(
          tags: value == null
              ? const TagsQuery.notAssigned()
              : TagsQuery.fromIds([...filter.tags.ids, int.parse(value!)]),
        );
      case createdBeforeRule:
        return filter.copyWith(createdDateBefore: value == null ? null : DateTime.parse(value!));
      case createdAfterRule:
        return filter.copyWith(createdDateAfter: value == null ? null : DateTime.parse(value!));
      case addedBeforeRule:
        return filter.copyWith(addedDateBefore: value == null ? null : DateTime.parse(value!));
      case addedAfterRule:
        return filter.copyWith(addedDateAfter: value == null ? null : DateTime.parse(value!));
      case titleAndContentRule:
        return filter.copyWith(queryText: value, queryType: QueryType.titleAndContent);
      case extendedRule:
        return filter.copyWith(queryText: value, queryType: QueryType.extended);
      //TODO: Add currently unused rules
      default:
        return filter;
    }
  }

  ///
  /// Converts a [DocumentFilter] to a list of [FilterRule]s.
  ///
  static List<FilterRule> fromFilter(final DocumentFilter filter) {
    List<FilterRule> filterRules = [];
    if (filter.correspondent.onlyNotAssigned) {
      filterRules.add(FilterRule(correspondentRule, null));
    }
    if (filter.correspondent.isSet) {
      filterRules.add(FilterRule(correspondentRule, filter.correspondent.id!.toString()));
    }
    if (filter.documentType.onlyNotAssigned) {
      filterRules.add(FilterRule(documentTypeRule, null));
    }
    if (filter.documentType.isSet) {
      filterRules.add(FilterRule(documentTypeRule, filter.documentType.id!.toString()));
    }
    if (filter.storagePath.onlyNotAssigned) {
      filterRules.add(FilterRule(storagePathRule, null));
    }
    if (filter.storagePath.isSet) {
      filterRules.add(FilterRule(storagePathRule, filter.storagePath.id!.toString()));
    }
    if (filter.tags.onlyNotAssigned) {
      filterRules.add(FilterRule(tagRule, null));
    }
    if (filter.tags.isSet) {
      filterRules.addAll(filter.tags.ids.map((id) => FilterRule(tagRule, id.toString())));
    }

    if (filter.queryText != null) {
      switch (filter.queryType) {
        case QueryType.title:
          filterRules.add(FilterRule(titleRule, filter.queryText!));
          break;
        case QueryType.titleAndContent:
          filterRules.add(FilterRule(titleAndContentRule, filter.queryText!));
          break;
        case QueryType.extended:
          filterRules.add(FilterRule(extendedRule, filter.queryText!));
          break;
        case QueryType.asn:
          filterRules.add(FilterRule(asnRule, filter.queryText!));
          break;
      }
    }
    if (filter.createdDateAfter != null) {
      filterRules.add(FilterRule(createdAfterRule, dateFormat.format(filter.createdDateAfter!)));
    }
    if (filter.createdDateBefore != null) {
      filterRules.add(FilterRule(createdBeforeRule, dateFormat.format(filter.createdDateBefore!)));
    }
    if (filter.addedDateAfter != null) {
      filterRules.add(FilterRule(addedAfterRule, dateFormat.format(filter.addedDateAfter!)));
    }
    if (filter.addedDateBefore != null) {
      filterRules.add(FilterRule(addedBeforeRule, dateFormat.format(filter.addedDateBefore!)));
    }
    return filterRules;
  }

  @override
  List<Object?> get props => [ruleType, value];
}
