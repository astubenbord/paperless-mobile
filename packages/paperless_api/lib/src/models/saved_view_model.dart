import 'package:equatable/equatable.dart';
import 'package:paperless_api/src/models/document_filter.dart';
import 'package:paperless_api/src/models/filter_rule_model.dart';
import 'package:paperless_api/src/models/query_parameters/sort_field.dart';
import 'package:paperless_api/src/models/query_parameters/sort_order.dart';

class SavedView with EquatableMixin {
  final int? id;
  final String name;

  final bool showOnDashboard;
  final bool showInSidebar;

  final SortField sortField;
  final bool sortReverse;
  final List<FilterRule> filterRules;

  SavedView({
    this.id,
    required this.name,
    required this.showOnDashboard,
    required this.showInSidebar,
    required this.sortField,
    required this.sortReverse,
    required this.filterRules,
  }) {
    filterRules.sort(
      (a, b) => (a.ruleType.compareTo(b.ruleType) != 0
          ? a.ruleType.compareTo(b.ruleType)
          : a.value?.compareTo(b.value ?? "") ?? -1),
    );
  }

  @override
  List<Object?> get props => [
        name,
        showOnDashboard,
        showInSidebar,
        sortField,
        sortReverse,
        filterRules
      ];

  SavedView.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id'],
          name: json['name'],
          showOnDashboard: json['show_on_dashboard'],
          showInSidebar: json['show_in_sidebar'],
          sortField: SortField.values
              .where((order) => order.queryString == json['sort_field'])
              .first,
          sortReverse: json['sort_reverse'],
          filterRules: (json['filter_rules'] as List)
              .cast<Map<String, dynamic>>()
              .map(FilterRule.fromJson)
              .toList(),
        );

  DocumentFilter toDocumentFilter() {
    return filterRules.fold(
      DocumentFilter(
        sortOrder: sortReverse ? SortOrder.descending : SortOrder.ascending,
        sortField: sortField,
      ),
      (filter, filterRule) => filterRule.applyToFilter(filter),
    );
  }

  SavedView.fromDocumentFilter(
    DocumentFilter filter, {
    required String name,
    required bool showInSidebar,
    required bool showOnDashboard,
  }) : this(
          id: null,
          name: name,
          filterRules: FilterRule.fromFilter(filter),
          sortField: filter.sortField,
          showInSidebar: showInSidebar,
          showOnDashboard: showOnDashboard,
          sortReverse: filter.sortOrder == SortOrder.descending,
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'show_on_dashboard': showOnDashboard,
      'show_in_sidebar': showInSidebar,
      'sort_reverse': sortReverse,
      'sort_field': sortField.queryString,
      'filter_rules': filterRules.map((rule) => rule.toJson()).toList(),
    };
  }
}
