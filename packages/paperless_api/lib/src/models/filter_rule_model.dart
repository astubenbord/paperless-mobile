import 'package:equatable/equatable.dart';
import 'package:paperless_api/src/constants.dart';
import 'package:paperless_api/src/models/document_filter.dart';
import 'package:paperless_api/src/models/query_parameters/correspondent_query.dart';
import 'package:paperless_api/src/models/query_parameters/date_range_query.dart';
import 'package:paperless_api/src/models/query_parameters/document_type_query.dart';
import 'package:paperless_api/src/models/query_parameters/query_type.dart';
import 'package:paperless_api/src/models/query_parameters/storage_path_query.dart';
import 'package:paperless_api/src/models/query_parameters/tags_query.dart';

class FilterRule with EquatableMixin {
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
  // Currently unsupported view options:
  static const int _content = 1;
  static const int _isInInbox = 5;
  static const int _createdYearIs = 10;
  static const int _createdMonthIs = 11;
  static const int _createdDayIs = 12;
  static const int _doesNotHaveAsn = 18;
  static const int _moreLikeThis = 21;
  static const int _hasTagsIn = 22;
  static const int _asnGreaterThan = 23;
  static const int _asnLessThan = 24;

  static const String _lastNDateRangeQueryRegex =
      r"(?<field>created|added|modified):\[(?<n>-?\d+) (?<unit>day|week|month|year) to now\]";

  final int ruleType;
  final String? value;

  FilterRule(this.ruleType, this.value);

  FilterRule.fromJson(Map<String, dynamic> json)
      : ruleType = json['rule_type'],
        value = json['value'];

  Map<String, dynamic> toJson() {
    return {
      'rule_type': ruleType,
      'value': value,
    };
  }

  DocumentFilter applyToFilter(final DocumentFilter filter) {
    if (value == null) {
      return filter;
    }
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
      case hasAnyTag:
        return filter.copyWith(
          tags: value == "true"
              ? const AnyAssignedTagsQuery()
              : const OnlyNotAssignedTagsQuery(),
        );
      case includeTagsRule:
        assert(filter.tags is IdsTagsQuery);
        return filter.copyWith(
          tags: (filter.tags as IdsTagsQuery)
              .withIdQueriesAdded([IncludeTagIdQuery(int.parse(value!))]),
        );
      case excludeTagsRule:
        assert(filter.tags is IdsTagsQuery);
        return filter.copyWith(
          tags: (filter.tags as IdsTagsQuery)
              .withIdQueriesAdded([ExcludeTagIdQuery(int.parse(value!))]),
        );
      case createdBeforeRule:
        if (filter.created is FixedDateRangeQuery) {
          return filter.copyWith(
            created: (filter.created as FixedDateRangeQuery)
                .copyWith(before: DateTime.parse(value!)),
          );
        } else {
          return filter.copyWith(
            created:
                FixedDateRangeQuery.created(before: DateTime.parse(value!)),
          );
        }
      case createdAfterRule:
        if (filter.created is FixedDateRangeQuery) {
          return filter.copyWith(
            created: (filter.created as FixedDateRangeQuery)
                .copyWith(after: DateTime.parse(value!)),
          );
        } else {
          return filter.copyWith(
            created: FixedDateRangeQuery.created(after: DateTime.parse(value!)),
          );
        }
      case addedBeforeRule:
        if (filter.added is FixedDateRangeQuery) {
          return filter.copyWith(
            added: (filter.added as FixedDateRangeQuery)
                .copyWith(before: DateTime.parse(value!)),
          );
        } else {
          return filter.copyWith(
            added: FixedDateRangeQuery.added(before: DateTime.parse(value!)),
          );
        }
      case addedAfterRule:
        if (filter.added is FixedDateRangeQuery) {
          return filter.copyWith(
            added: (filter.added as FixedDateRangeQuery)
                .copyWith(after: DateTime.parse(value!)),
          );
        } else {
          return filter.copyWith(
            added: FixedDateRangeQuery.added(after: DateTime.parse(value!)),
          );
        }
      case titleAndContentRule:
        return filter.copyWith(
          queryText: value,
          queryType: QueryType.titleAndContent,
        );
      case extendedRule:
        _parseExtendedRule(filter);
        return filter.copyWith(queryText: value, queryType: QueryType.extended);
      default:
        return filter;
    }
  }

  DocumentFilter _parseExtendedRule(final DocumentFilter filter) {
    DocumentFilter newFilter = filter;
    assert(value != null);
    final dateRangeRegExp = RegExp(_lastNDateRangeQueryRegex);
    if (dateRangeRegExp.hasMatch(value!)) {
      final matches = dateRangeRegExp.allMatches(value!);
      for (final match in matches) {
        final field = match.namedGroup('field')!;
        final n = int.parse(match.namedGroup('n')!);
        final unit = match.namedGroup('unit')!;
        switch (field) {
          case 'created':
            newFilter = newFilter.copyWith(
              created: LastNDateRangeQuery.created(
                n,
                DateRangeUnit.values.byName(unit),
              ),
            );
            break;
          case 'added':
            newFilter = newFilter.copyWith(
              created: LastNDateRangeQuery.added(
                n,
                DateRangeUnit.values.byName(unit),
              ),
            );
            break;
          case 'modified':
            newFilter = newFilter.copyWith(
              created: LastNDateRangeQuery.modified(
                n,
                DateRangeUnit.values.byName(unit),
              ),
            );
            break;
        }
      }
      return newFilter;
    } else {
      // Match other extended query types... currently not supported!
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
      filterRules.add(
          FilterRule(correspondentRule, filter.correspondent.id!.toString()));
    }
    if (filter.documentType.onlyNotAssigned) {
      filterRules.add(FilterRule(documentTypeRule, null));
    }
    if (filter.documentType.isSet) {
      filterRules.add(
          FilterRule(documentTypeRule, filter.documentType.id!.toString()));
    }
    if (filter.storagePath.onlyNotAssigned) {
      filterRules.add(FilterRule(storagePathRule, null));
    }
    if (filter.storagePath.isSet) {
      filterRules
          .add(FilterRule(storagePathRule, filter.storagePath.id!.toString()));
    }
    if (filter.tags is OnlyNotAssignedTagsQuery) {
      filterRules.add(FilterRule(hasAnyTag, false.toString()));
    }
    if (filter.tags is AnyAssignedTagsQuery) {
      filterRules.add(FilterRule(hasAnyTag, true.toString()));
    }
    if (filter.tags is IdsTagsQuery) {
      filterRules.addAll((filter.tags as IdsTagsQuery)
          .includedIds
          .map((id) => FilterRule(includeTagsRule, id.toString())));
      filterRules.addAll((filter.tags as IdsTagsQuery)
          .excludedIds
          .map((id) => FilterRule(excludeTagsRule, id.toString())));
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

    // Parse created at
    final created = filter.created;
    if (created is FixedDateRangeQuery) {
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
    } else if (created is LastNDateRangeQuery) {
      filterRules.add(
        FilterRule(extendedRule, created.toQueryParameter().values.first),
      );
    }

    // Parse added at
    final added = filter.added;
    if (added is FixedDateRangeQuery) {
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
    } else if (added is LastNDateRangeQuery) {
      filterRules.add(
        FilterRule(extendedRule, added.toQueryParameter().values.first),
      );
    }

    // Parse modified at
    final modified = filter.added;
    if (modified is FixedDateRangeQuery) {
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
    } else if (modified is LastNDateRangeQuery) {
      filterRules.add(
        FilterRule(extendedRule, modified.toQueryParameter().values.first),
      );
    }

    return filterRules;
  }

  @override
  List<Object?> get props => [ruleType, value];
}
