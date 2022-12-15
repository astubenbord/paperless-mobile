import 'package:equatable/equatable.dart';
import 'package:paperless_api/src/constants.dart';
import 'package:paperless_api/src/models/query_parameters/asn_query.dart';
import 'package:paperless_api/src/models/query_parameters/correspondent_query.dart';
import 'package:paperless_api/src/models/query_parameters/date_range_query.dart';
import 'package:paperless_api/src/models/query_parameters/document_type_query.dart';
import 'package:paperless_api/src/models/query_parameters/query_type.dart';
import 'package:paperless_api/src/models/query_parameters/sort_field.dart';
import 'package:paperless_api/src/models/query_parameters/sort_order.dart';
import 'package:paperless_api/src/models/query_parameters/storage_path_query.dart';
import 'package:paperless_api/src/models/query_parameters/tags_query.dart';

class DocumentFilter extends Equatable {
  static const _oneDay = Duration(days: 1);
  static const DocumentFilter initial = DocumentFilter();

  static const DocumentFilter latestDocument = DocumentFilter(
    sortField: SortField.added,
    sortOrder: SortOrder.descending,
    pageSize: 1,
    page: 1,
  );

  final int pageSize;
  final int page;
  final DocumentTypeQuery documentType;
  final CorrespondentQuery correspondent;
  final StoragePathQuery storagePath;
  final AsnQuery asnQuery;
  final TagsQuery tags;
  final SortField sortField;
  final SortOrder sortOrder;
  final DateRangeQuery added;
  final DateRangeQuery created;
  final QueryType queryType;
  final String? queryText;

  const DocumentFilter({
    this.documentType = const DocumentTypeQuery.unset(),
    this.correspondent = const CorrespondentQuery.unset(),
    this.storagePath = const StoragePathQuery.unset(),
    this.asnQuery = const AsnQuery.unset(),
    this.tags = const IdsTagsQuery(),
    this.sortField = SortField.created,
    this.sortOrder = SortOrder.descending,
    this.page = 1,
    this.pageSize = 25,
    this.queryType = QueryType.titleAndContent,
    this.queryText,
    this.added = const UnsetDateRangeQuery(),
    this.created = const UnsetDateRangeQuery(),
  });

  Map<String, String> toQueryParameters() {
    Map<String, String> params = {
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    params.addAll(documentType.toQueryParameter());
    params.addAll(correspondent.toQueryParameter());
    params.addAll(tags.toQueryParameter());
    params.addAll(storagePath.toQueryParameter());
    params.addAll(asnQuery.toQueryParameter());
    params.addAll(added.toQueryParameter());
    params.addAll(created.toQueryParameter());
    //TODO: Rework when implementing extended queries.
    if (queryText?.isNotEmpty ?? false) {
      params.putIfAbsent(queryType.queryParam, () => queryText!);
    }
    // Reverse ordering can also be encoded using &reverse=1
    params.putIfAbsent(
        'ordering', () => '${sortOrder.queryString}${sortField.queryString}');

    return params;
  }

  @override
  String toString() {
    return toQueryParameters().toString();
  }

  DocumentFilter copyWith({
    int? pageSize,
    int? page,
    bool? onlyNoDocumentType,
    DocumentTypeQuery? documentType,
    CorrespondentQuery? correspondent,
    StoragePathQuery? storagePath,
    AsnQuery? asnQuery,
    TagsQuery? tags,
    SortField? sortField,
    SortOrder? sortOrder,
    DateRangeQuery? added,
    DateRangeQuery? created,
    QueryType? queryType,
    String? queryText,
  }) {
    return DocumentFilter(
      pageSize: pageSize ?? this.pageSize,
      page: page ?? this.page,
      documentType: documentType ?? this.documentType,
      correspondent: correspondent ?? this.correspondent,
      storagePath: storagePath ?? this.storagePath,
      tags: tags ?? this.tags,
      sortField: sortField ?? this.sortField,
      sortOrder: sortOrder ?? this.sortOrder,
      added: added ?? this.added,
      queryType: queryType ?? this.queryType,
      queryText: queryText ?? this.queryText,
      asnQuery: asnQuery ?? this.asnQuery,
      created: created ?? this.created,
    );
  }

  String? get titleOnlyMatchString {
    if (queryType == QueryType.title) {
      return queryText?.isEmpty ?? true ? null : queryText;
    }
    return null;
  }

  String? get titleAndContentMatchString {
    if (queryType == QueryType.titleAndContent) {
      return queryText?.isEmpty ?? true ? null : queryText;
    }
    return null;
  }

  String? get extendedMatchString {
    if (queryType == QueryType.extended) {
      return queryText?.isEmpty ?? true ? null : queryText;
    }
    return null;
  }

  int get appliedFiltersCount => [
        documentType != initial.documentType,
        correspondent != initial.correspondent,
        storagePath != initial.storagePath,
        tags != initial.tags,
        (added != initial.added),
        (created != initial.created),
        asnQuery != initial.asnQuery,
        (queryType != initial.queryType || queryText != initial.queryText),
      ].fold(0, (previousValue, element) => previousValue += element ? 1 : 0);

  @override
  List<Object?> get props => [
        pageSize,
        page,
        documentType,
        correspondent,
        storagePath,
        asnQuery,
        tags,
        sortField,
        sortOrder,
        added,
        created,
        queryType,
        queryText,
      ];
}
