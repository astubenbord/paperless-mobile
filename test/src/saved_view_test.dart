import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/model/filter_rule.model.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/document_type_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/query_type.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/sort_order.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/storage_path_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/tags_query.dart';
import 'package:paperless_mobile/features/documents/model/saved_view.model.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/correspondent_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/sort_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validate parsing logic from [SavedView] to [DocumentFilter]:', () {
    test('Values are correctly parsed if set.', () {
      expect(
        SavedView.fromJson({
          "id": 1,
          "name": "test_name",
          "show_on_dashboard": false,
          "show_in_sidebar": false,
          "sort_field": SortField.created.name,
          "sort_reverse": true,
          "filter_rules": [
            {
              'rule_type': FilterRule.correspondentRule,
              'value': "42",
            },
            {
              'rule_type': FilterRule.documentTypeRule,
              'value': "69",
            },
            {
              'rule_type': FilterRule.includeTagsRule,
              'value': "1",
            },
            {
              'rule_type': FilterRule.includeTagsRule,
              'value': "2",
            },
            {
              'rule_type': FilterRule.excludeTagsRule,
              'value': "3",
            },
            {
              'rule_type': FilterRule.excludeTagsRule,
              'value': "4",
            },
            {
              'rule_type': FilterRule.extendedRule,
              'value': "Never gonna give you up",
            },
            {
              'rule_type': FilterRule.storagePathRule,
              'value': "14",
            },
            {
              'rule_type': FilterRule.createdBeforeRule,
              'value': "2022-10-27",
            },
            {
              'rule_type': FilterRule.createdAfterRule,
              'value': "2022-09-27",
            },
            {
              'rule_type': FilterRule.addedBeforeRule,
              'value': "2022-09-26",
            },
            {
              'rule_type': FilterRule.addedAfterRule,
              'value': "2000-01-01",
            }
          ]
        }).toDocumentFilter(),
        equals(
          DocumentFilter.initial.copyWith(
            correspondent: const CorrespondentQuery.fromId(42),
            documentType: const DocumentTypeQuery.fromId(69),
            storagePath: const StoragePathQuery.fromId(14),
            tags: IdsTagsQuery(
              [
                IncludeTagIdQuery(1),
                IncludeTagIdQuery(2),
                ExcludeTagIdQuery(3),
                ExcludeTagIdQuery(4),
              ],
            ),
            createdDateBefore: DateTime.parse("2022-10-27"),
            createdDateAfter: DateTime.parse("2022-09-27"),
            addedDateBefore: DateTime.parse("2022-09-26"),
            addedDateAfter: DateTime.parse("2000-01-01"),
            sortField: SortField.created,
            sortOrder: SortOrder.descending,
            queryText: "Never gonna give you up",
            queryType: QueryType.extended,
          ),
        ),
      );
    });

    test('Values are correctly parsed if unset.', () {
      expect(
        SavedView.fromJson({
          "id": 1,
          "name": "test_name",
          "show_on_dashboard": false,
          "show_in_sidebar": false,
          "sort_field": SortField.created.name,
          "sort_reverse": true,
          "filter_rules": [],
        }).toDocumentFilter(),
        equals(DocumentFilter.initial),
      );
    });

    test('Values are correctly parsed if not assigned.', () {
      expect(
        SavedView.fromJson({
          "id": 1,
          "name": "test_name",
          "show_on_dashboard": false,
          "show_in_sidebar": false,
          "sort_field": SortField.created.name,
          "sort_reverse": true,
          "filter_rules": [
            {
              'rule_type': FilterRule.correspondentRule,
              'value': null,
            },
            {
              'rule_type': FilterRule.documentTypeRule,
              'value': null,
            },
            {
              'rule_type': FilterRule.hasAnyTag,
              'value': false.toString(),
            },
            {
              'rule_type': FilterRule.storagePathRule,
              'value': null,
            },
          ],
        }).toDocumentFilter(),
        equals(DocumentFilter.initial.copyWith(
          correspondent: const CorrespondentQuery.notAssigned(),
          documentType: const DocumentTypeQuery.notAssigned(),
          storagePath: const StoragePathQuery.notAssigned(),
          tags: const OnlyNotAssignedTagsQuery(),
        )),
      );
    });
  });

  group('Validate parsing logic from [DocumentFilter] to [SavedView]:', () {
    test('Values are correctly parsed if set.', () {
      expect(
        SavedView.fromDocumentFilter(
          DocumentFilter(
            correspondent: const CorrespondentQuery.fromId(1),
            documentType: const DocumentTypeQuery.fromId(2),
            storagePath: const StoragePathQuery.fromId(3),
            tags: IdsTagsQuery([
              IncludeTagIdQuery(4),
              IncludeTagIdQuery(5),
              ExcludeTagIdQuery(6),
              ExcludeTagIdQuery(7),
              ExcludeTagIdQuery(8),
            ]),
            sortField: SortField.added,
            sortOrder: SortOrder.ascending,
            addedDateAfter: DateTime.parse("2020-01-01"),
            addedDateBefore: DateTime.parse("2020-03-01"),
            createdDateAfter: DateTime.parse("2020-02-01"),
            createdDateBefore: DateTime.parse("2020-04-01"),
            queryText: "Never gonna let you down",
            queryType: QueryType.title,
          ),
          name: "test_name",
          showInSidebar: false,
          showOnDashboard: false,
        ),
        equals(
          SavedView(
            name: "test_name",
            showOnDashboard: false,
            showInSidebar: false,
            sortField: SortField.added,
            sortReverse: false,
            filterRules: [
              FilterRule(FilterRule.correspondentRule, "1"),
              FilterRule(FilterRule.documentTypeRule, "2"),
              FilterRule(FilterRule.storagePathRule, "3"),
              FilterRule(FilterRule.includeTagsRule, "4"),
              FilterRule(FilterRule.includeTagsRule, "5"),
              FilterRule(FilterRule.excludeTagsRule, "6"),
              FilterRule(FilterRule.excludeTagsRule, "7"),
              FilterRule(FilterRule.excludeTagsRule, "8"),
              FilterRule(FilterRule.addedAfterRule, "2020-01-01"),
              FilterRule(FilterRule.addedBeforeRule, "2020-03-01"),
              FilterRule(FilterRule.createdAfterRule, "2020-02-01"),
              FilterRule(FilterRule.createdBeforeRule, "2020-04-01"),
              FilterRule(FilterRule.titleRule, "Never gonna let you down"),
            ],
          ),
        ),
      );
    });

    test('Values are correctly parsed if unset.', () {
      expect(
        SavedView.fromDocumentFilter(
          const DocumentFilter(
            correspondent: CorrespondentQuery.unset(),
            documentType: DocumentTypeQuery.unset(),
            storagePath: StoragePathQuery.unset(),
            tags: IdsTagsQuery(),
            sortField: SortField.created,
            sortOrder: SortOrder.descending,
            addedDateAfter: null,
            addedDateBefore: null,
            createdDateAfter: null,
            createdDateBefore: null,
            queryText: null,
          ),
          name: "test_name",
          showInSidebar: false,
          showOnDashboard: false,
        ),
        equals(
          SavedView(
            name: "test_name",
            showOnDashboard: false,
            showInSidebar: false,
            sortField: SortField.created,
            sortReverse: true,
            filterRules: [],
          ),
        ),
      );
    });

    test('Values are correctly parsed if not assigned.', () {
      expect(
        SavedView.fromDocumentFilter(
          const DocumentFilter(
            correspondent: CorrespondentQuery.notAssigned(),
            documentType: DocumentTypeQuery.notAssigned(),
            storagePath: StoragePathQuery.notAssigned(),
            tags: OnlyNotAssignedTagsQuery(),
            sortField: SortField.created,
            sortOrder: SortOrder.ascending,
          ),
          name: "test_name",
          showInSidebar: false,
          showOnDashboard: false,
        ),
        equals(
          SavedView(
            name: "test_name",
            showOnDashboard: false,
            showInSidebar: false,
            sortField: SortField.created,
            sortReverse: false,
            filterRules: [
              FilterRule(FilterRule.correspondentRule, null),
              FilterRule(FilterRule.documentTypeRule, null),
              FilterRule(FilterRule.storagePathRule, null),
              FilterRule(FilterRule.hasAnyTag, false.toString()),
            ],
          ),
        ),
      );
    });
  });
}
