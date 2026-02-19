// ignore_for_file: unused_field

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_api/src/constants.dart';
import 'package:paperless_api/src/converters/local_date_time_json_converter.dart';
import 'package:paperless_api/src/models/query_parameters/date_range_queries/date_range_query_field.dart';

part 'filter_rule_model.g.dart';

@JsonSerializable()
class FilterRule with EquatableMixin {
  static const _dateTimeConverter = LocalDateTimeJsonConverter();
  static const int titleRule = 0;
  static const int asnRule = 2;
  static const int correspondentRule = 3;
  static const int documentTypeRule = 4;
  static const int includeTagsRule = 6;
  static const int hasAnyTag = 7; // true = any tag, false = not assigned
  static const int createdBeforeRule = 8;
  static const int createdAfterRule = 9;
  static const int addedBeforeRule = 13;
  static const int addedAfterRule = 14;
  static const int modifiedBeforeRule = 15;
  static const int modifiedAfterRule = 16;
  static const int excludeTagsRule = 17;
  static const int titleAndContentRule = 19;
  static const int extendedRule = 20;
  static const int storagePathRule = 25;
  static const int ownerRule = 26;
  static const int hasStoragePathIn = 30;
  static const int hasCorrespondentIn = 31;
  static const int hasDocumentTypeIn = 32;
  static const int ownerIsnull = 33;
  // Currently unsupported view options:
  static const int _content = 1;
  static const int _isInInbox = 5;
  static const int _createdYearIs = 10;
  static const int _createdMonthIs = 11;
  static const int _createdDayIs = 12;
  static const int _doesNotHaveAsn = 18;
  static const int _moreLikeThis = 21;
  static const int hasTagsIn = 22;
  static const int _asnGreaterThan = 23;
  static const int _asnLessThan = 24;

  static const String _lastNDateRangeQueryRegex =
      r"(?<field>created|added|modified):\[-?(?<n>\d+) (?<unit>day|week|month|year) to now\]";

  @JsonKey(name: 'rule_type')
  final int ruleType;
  final String? value;

  FilterRule(this.ruleType, this.value);

  DocumentFilter applyToFilter(final DocumentFilter filter) {
    //TODO: Check in profiling mode if this is inefficient enough to cause stutters...
    switch (ruleType) {
      case titleRule:
        return filter.copyWith(query: TextQuery.title(value));
      case documentTypeRule:
        return filter.copyWith(
          documentType: value == null
              ? const NotAssignedIdQueryParameter()
              : SetIdQueryParameter(id: int.parse(value!)),
        );
      case correspondentRule:
        return filter.copyWith(
          correspondent: value == null
              ? const NotAssignedIdQueryParameter()
              : SetIdQueryParameter(id: int.parse(value!)),
        );
      case storagePathRule:
        return filter.copyWith(
          storagePath: value == null
              ? const NotAssignedIdQueryParameter()
              : SetIdQueryParameter(id: int.parse(value!)),
        );
      case hasAnyTag:
        return filter.copyWith(
          tags: value == "true"
              ? const AnyAssignedTagsQuery()
              : const NotAssignedTagsQuery(),
        );
      case includeTagsRule:
        return filter.copyWith(
          tags: switch (filter.tags) {
            IdsTagsQuery(include: var i, exclude: var e) => IdsTagsQuery(
                include: [...i, int.parse(value!)],
                exclude: e,
              ),
            _ => IdsTagsQuery(
                include: [int.parse(value!)],
              ),
          },
        );
      case excludeTagsRule:
        return filter.copyWith(
          tags: switch (filter.tags) {
            IdsTagsQuery(include: var i, exclude: var e) => IdsTagsQuery(
                include: i,
                exclude: [...e, int.parse(value!)],
              ),
            _ => IdsTagsQuery(
                exclude: [int.parse(value!)],
              ),
          },
        );
      case createdBeforeRule:
        if (filter.created is AbsoluteDateRangeQuery) {
          return filter.copyWith(
            created: (filter.created as AbsoluteDateRangeQuery)
                .copyWith(before: _dateTimeConverter.fromJson(value!)),
          );
        } else {
          return filter.copyWith(
            created: AbsoluteDateRangeQuery(
                before: _dateTimeConverter.fromJson(value!)),
          );
        }
      case createdAfterRule:
        if (filter.created is AbsoluteDateRangeQuery) {
          return filter.copyWith(
            created: (filter.created as AbsoluteDateRangeQuery)
                .copyWith(after: _dateTimeConverter.fromJson(value!)),
          );
        } else {
          return filter.copyWith(
            created: AbsoluteDateRangeQuery(
                after: _dateTimeConverter.fromJson(value!)),
          );
        }
      case addedBeforeRule:
        if (filter.added is AbsoluteDateRangeQuery) {
          return filter.copyWith(
            added: (filter.added as AbsoluteDateRangeQuery)
                .copyWith(before: _dateTimeConverter.fromJson(value!)),
          );
        } else {
          return filter.copyWith(
            added: AbsoluteDateRangeQuery(
                before: _dateTimeConverter.fromJson(value!)),
          );
        }
      case addedAfterRule:
        if (filter.added is AbsoluteDateRangeQuery) {
          return filter.copyWith(
            added: (filter.added as AbsoluteDateRangeQuery)
                .copyWith(after: _dateTimeConverter.fromJson(value!)),
          );
        } else {
          return filter.copyWith(
            added: AbsoluteDateRangeQuery(
                after: _dateTimeConverter.fromJson(value!)),
          );
        }
      case modifiedBeforeRule:
        if (filter.modified is AbsoluteDateRangeQuery) {
          return filter.copyWith(
            modified: (filter.modified as AbsoluteDateRangeQuery)
                .copyWith(before: _dateTimeConverter.fromJson(value!)),
          );
        } else {
          return filter.copyWith(
            modified: AbsoluteDateRangeQuery(
                before: _dateTimeConverter.fromJson(value!)),
          );
        }
      case modifiedAfterRule:
        if (filter.modified is AbsoluteDateRangeQuery) {
          return filter.copyWith(
            modified: (filter.modified as AbsoluteDateRangeQuery)
                .copyWith(after: _dateTimeConverter.fromJson(value!)),
          );
        } else {
          return filter.copyWith(
            modified: AbsoluteDateRangeQuery(
                after: _dateTimeConverter.fromJson(value!)),
          );
        }
      case titleAndContentRule:
        return filter.copyWith(query: TextQuery.titleAndContent(value));
      case extendedRule:
        return _parseExtendedRule(filter);
      case ownerRule:
        return filter.copyWith(
          owner: value == null
              ? const NotAssignedIdQueryParameter()
              : SetIdQueryParameter(id: int.parse(value!)),
        );
      case ownerIsnull:
        return filter.copyWith(
          owner: value == '1'
              ? const NotAssignedIdQueryParameter()
              : const AnyAssignedIdQueryParameter(),
        );
      case hasTagsIn:
        return filter.copyWith(
          tags: switch (filter.tags) {
            AnyAssignedTagsQuery(tagIds: var ids) => AnyAssignedTagsQuery(
                tagIds: [...ids, int.parse(value!)],
              ),
            _ => AnyAssignedTagsQuery(
                tagIds: [int.parse(value!)],
              ),
          },
        );
      case hasStoragePathIn:
        return filter.copyWith(
          storagePath: value == null
              ? const NotAssignedIdQueryParameter()
              : SetIdQueryParameter(id: int.parse(value!)),
        );
      case hasCorrespondentIn:
        return filter.copyWith(
          correspondent: value == null
              ? const NotAssignedIdQueryParameter()
              : SetIdQueryParameter(id: int.parse(value!)),
        );
      case hasDocumentTypeIn:
        return filter.copyWith(
          documentType: value == null
              ? const NotAssignedIdQueryParameter()
              : SetIdQueryParameter(id: int.parse(value!)),
        );
      default:
        return filter;
    }
  }

  DocumentFilter _parseExtendedRule(DocumentFilter filter) {
    assert(value != null);
    final extendedQueryValues = value!.split(",").reversed;

    for (final query in extendedQueryValues) {
      if (RegExp(_lastNDateRangeQueryRegex).hasMatch(query)) {
        filter = _parseRelativeDateRangeQuery(query, filter);
      } else {
        filter = filter.copyWith(query: TextQuery.extended(query));
      }
    }
    return filter;
  }

  DocumentFilter _parseRelativeDateRangeQuery(
    String query,
    final DocumentFilter filter,
  ) {
    DocumentFilter newFilter = filter;
    final matches = RegExp(_lastNDateRangeQueryRegex).allMatches(query);
    for (final match in matches) {
      final field = match.namedGroup('field')!;
      final n = int.parse(match.namedGroup('n')!);
      final unit = match.namedGroup('unit')!;
      switch (field) {
        case 'created':
          newFilter = newFilter.copyWith(
            created: RelativeDateRangeQuery(
              n,
              DateRangeUnit.values.byName(unit),
            ),
            query: newFilter.query.copyWith(queryType: QueryType.extended),
          );
          break;
        case 'added':
          newFilter = newFilter.copyWith(
            added: RelativeDateRangeQuery(
              n,
              DateRangeUnit.values.byName(unit),
            ),
            query: newFilter.query.copyWith(queryType: QueryType.extended),
          );
          break;
        case 'modified':
          newFilter = newFilter.copyWith(
            modified: RelativeDateRangeQuery(
              n,
              DateRangeUnit.values.byName(unit),
            ),
            query: newFilter.query.copyWith(queryType: QueryType.extended),
          );
          break;
      }
    }
    return newFilter;
  }

  ///
  /// Converts a [DocumentFilter] to a list of [FilterRule]s.
  ///
  static List<FilterRule> fromFilter(final DocumentFilter filter) {
    List<FilterRule> filterRules = [];
    final corrRule = switch (filter.correspondent) {
      NotAssignedIdQueryParameter() => FilterRule(correspondentRule, null),
      SetIdQueryParameter(id: var id) =>
        FilterRule(correspondentRule, id.toString()),
      _ => null,
    };
    if (corrRule != null) {
      filterRules.add(corrRule);
    }

    final docTypeRule = switch (filter.documentType) {
      NotAssignedIdQueryParameter() => FilterRule(documentTypeRule, null),
      SetIdQueryParameter(id: var id) =>
        FilterRule(documentTypeRule, id.toString()),
      _ => null,
    };

    if (docTypeRule != null) {
      filterRules.add(docTypeRule);
    }

    final sPathRule = switch (filter.storagePath) {
      NotAssignedIdQueryParameter() => FilterRule(storagePathRule, null),
      SetIdQueryParameter(id: var id) =>
        FilterRule(storagePathRule, id.toString()),
      _ => null,
    };

    if (sPathRule != null) {
      filterRules.add(sPathRule);
    }

    final ownerFilterRule = switch (filter.owner) {
      NotAssignedIdQueryParameter() => FilterRule(ownerRule, null),
      SetIdQueryParameter(id: var id) =>
        FilterRule(ownerRule, id.toString()),
      _ => null,
    };
    if (ownerFilterRule != null) {
      filterRules.add(ownerFilterRule);
    }

    final tagRules = switch (filter.tags) {
      NotAssignedTagsQuery() => [FilterRule(hasAnyTag, 'false')],
      AnyAssignedTagsQuery(tagIds: var ids) when ids.isNotEmpty => [
          FilterRule(hasAnyTag, 'true'),
          ...ids.map((id) => FilterRule(hasTagsIn, id.toString())),
        ],
      AnyAssignedTagsQuery() => [FilterRule(hasAnyTag, 'true')],
      IdsTagsQuery(include: var i, exclude: var e) => [
          ...i.map((id) => FilterRule(includeTagsRule, id.toString())),
          ...e.map((id) => FilterRule(excludeTagsRule, id.toString())),
        ],
    };

    filterRules.addAll(tagRules);

    if (filter.query.queryText != null) {
      switch (filter.query.queryType) {
        case QueryType.title:
          filterRules.add(FilterRule(titleRule, filter.query.queryText!));
          break;
        case QueryType.titleAndContent:
          filterRules
              .add(FilterRule(titleAndContentRule, filter.query.queryText!));
          break;
        case QueryType.extended:
          filterRules.add(FilterRule(extendedRule, filter.query.queryText!));
          break;
        case QueryType.asn:
          filterRules.add(FilterRule(asnRule, filter.query.queryText!));
          break;
      }
    }

    // Parse created at
    final created = filter.created;
    if (created is AbsoluteDateRangeQuery) {
      if (created.after != null) {
        filterRules.add(
          FilterRule(createdAfterRule, apiDateFormat.format(created.after!)),
        );
      }
      if (created.before != null) {
        filterRules.add(
          FilterRule(createdBeforeRule, apiDateFormat.format(created.before!)),
        );
      }
    } else if (created is RelativeDateRangeQuery) {
      filterRules.add(
        FilterRule(extendedRule,
            created.toQueryParameter(DateRangeQueryField.created).values.first),
      );
    }

    // Parse added at
    final added = filter.added;
    if (added is AbsoluteDateRangeQuery) {
      if (added.after != null) {
        filterRules.add(
          FilterRule(addedAfterRule, apiDateFormat.format(added.after!)),
        );
      }
      if (added.before != null) {
        filterRules.add(
          FilterRule(addedBeforeRule, apiDateFormat.format(added.before!)),
        );
      }
    } else if (added is RelativeDateRangeQuery) {
      filterRules.add(
        FilterRule(extendedRule,
            added.toQueryParameter(DateRangeQueryField.added).values.first),
      );
    }

    // Parse modified at
    final modified = filter.modified;
    if (modified is AbsoluteDateRangeQuery) {
      if (modified.after != null) {
        filterRules.add(
          FilterRule(modifiedAfterRule, apiDateFormat.format(modified.after!)),
        );
      }
      if (modified.before != null) {
        filterRules.add(
          FilterRule(
              modifiedBeforeRule, apiDateFormat.format(modified.before!)),
        );
      }
    } else if (modified is RelativeDateRangeQuery) {
      filterRules.add(
        FilterRule(
            extendedRule,
            modified
                .toQueryParameter(DateRangeQueryField.modified)
                .values
                .first),
      );
    }

    //Join values of all extended filter rules if exist
    if (filterRules
        .where((e) => e.ruleType == FilterRule.extendedRule)
        .isNotEmpty) {
      final mergedExtendedRule = filterRules
          .where((r) => r.ruleType == FilterRule.extendedRule)
          .map((e) => e.value)
          .join(",");
      filterRules
        ..removeWhere((element) => element.ruleType == extendedRule)
        ..add(FilterRule(FilterRule.extendedRule, mergedExtendedRule));
    }
    return filterRules;
  }

  FilterRule copyWith({int? ruleType, String? value}) {
    return FilterRule(
      ruleType ?? this.ruleType,
      value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [ruleType, value];

  Map<String, dynamic> toJson() => _$FilterRuleToJson(this);

  factory FilterRule.fromJson(Map<String, dynamic> json) =>
      _$FilterRuleFromJson(json);
}
