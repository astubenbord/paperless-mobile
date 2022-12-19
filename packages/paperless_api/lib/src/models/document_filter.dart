import 'package:equatable/equatable.dart';
import 'package:paperless_api/paperless_api.dart';

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
  final IdQueryParameter documentType;
  final IdQueryParameter correspondent;
  final IdQueryParameter storagePath;
  final IdQueryParameter asnQuery;
  final TagsQuery tags;
  final SortField sortField;
  final SortOrder sortOrder;
  final DateRangeQuery created;
  final DateRangeQuery added;
  final DateRangeQuery modified;
  final QueryType queryType;
  final String? queryText;

  const DocumentFilter({
    this.documentType = const IdQueryParameter.unset(),
    this.correspondent = const IdQueryParameter.unset(),
    this.storagePath = const IdQueryParameter.unset(),
    this.asnQuery = const IdQueryParameter.unset(),
    this.tags = const IdsTagsQuery(),
    this.sortField = SortField.created,
    this.sortOrder = SortOrder.descending,
    this.page = 1,
    this.pageSize = 25,
    this.queryType = QueryType.titleAndContent,
    this.queryText,
    this.added = const UnsetDateRangeQuery(),
    this.created = const UnsetDateRangeQuery(),
    this.modified = const UnsetDateRangeQuery(),
  });

  Map<String, String> toQueryParameters() {
    Map<String, String> params = {
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    params.addAll(documentType.toQueryParameter('document_type'));
    params.addAll(correspondent.toQueryParameter('correspondent'));
    params.addAll(storagePath.toQueryParameter('storage_path'));
    params.addAll(asnQuery.toQueryParameter('archive_serial_number'));
    params.addAll(tags.toQueryParameter());
    params.addAll(added.toQueryParameter(DateRangeQueryField.added));
    params.addAll(created.toQueryParameter(DateRangeQueryField.created));
    params.addAll(modified.toQueryParameter(DateRangeQueryField.modified));
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
    IdQueryParameter? documentType,
    IdQueryParameter? correspondent,
    IdQueryParameter? storagePath,
    IdQueryParameter? asnQuery,
    TagsQuery? tags,
    SortField? sortField,
    SortOrder? sortOrder,
    DateRangeQuery? added,
    DateRangeQuery? created,
    DateRangeQuery? modified,
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
      queryType: queryType ?? this.queryType,
      queryText: queryText ?? this.queryText,
      asnQuery: asnQuery ?? this.asnQuery,
      added: added ?? this.added,
      created: created ?? this.created,
      modified: modified ?? this.modified,
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
        added != initial.added,
        created != initial.created,
        modified != initial.modified,
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
        modified,
        queryType,
        queryText,
      ];
}
