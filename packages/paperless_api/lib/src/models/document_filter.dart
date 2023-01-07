import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_api/src/converters/tags_query_json_converter.dart';

part 'document_filter.g.dart';

@TagsQueryJsonConverter()
@DateRangeQueryJsonConverter()
@JsonSerializable(explicitToJson: true)
class DocumentFilter extends Equatable {
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
  final TextQuery query;

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
    this.query = const TextQuery(),
    this.added = const UnsetDateRangeQuery(),
    this.created = const UnsetDateRangeQuery(),
    this.modified = const UnsetDateRangeQuery(),
  });

  bool get forceExtendedQuery {
    return added is RelativeDateRangeQuery ||
        created is RelativeDateRangeQuery ||
        modified is RelativeDateRangeQuery;
  }

  Map<String, dynamic> toQueryParameters() {
    List<MapEntry<String, dynamic>> params = [
      MapEntry('page', '$page'),
      MapEntry('page_size', '$pageSize'),
      MapEntry('ordering', '${sortOrder.queryString}${sortField.queryString}'),
      ...documentType.toQueryParameter('document_type').entries,
      ...correspondent.toQueryParameter('correspondent').entries,
      ...storagePath.toQueryParameter('storage_path').entries,
      ...asnQuery.toQueryParameter('archive_serial_number').entries,
      ...tags.toQueryParameter().entries,
      ...added.toQueryParameter(DateRangeQueryField.added).entries,
      ...created.toQueryParameter(DateRangeQueryField.created).entries,
      ...modified.toQueryParameter(DateRangeQueryField.modified).entries,
      ...query.toQueryParameter().entries,
    ];
    // Reverse ordering can also be encoded using &reverse=1
    // Merge query params
    final queryParams = groupBy(params, (e) => e.key).map(
      (key, entries) => MapEntry(
        key,
        entries.length == 1
            ? entries.first.value
            : entries.map((e) => e.value).join(","),
      ),
    );
    return queryParams;
  }

  @override
  String toString() => toQueryParameters().toString();

  DocumentFilter copyWith({
    int? pageSize,
    int? page,
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
    TextQuery? query,
    int? selectedViewId,
  }) {
    final newFilter = DocumentFilter(
      pageSize: pageSize ?? this.pageSize,
      page: page ?? this.page,
      documentType: documentType ?? this.documentType,
      correspondent: correspondent ?? this.correspondent,
      storagePath: storagePath ?? this.storagePath,
      tags: tags ?? this.tags,
      sortField: sortField ?? this.sortField,
      sortOrder: sortOrder ?? this.sortOrder,
      asnQuery: asnQuery ?? this.asnQuery,
      query: query ?? this.query,
      added: added ?? this.added,
      created: created ?? this.created,
      modified: modified ?? this.modified,
    );
    if (query?.queryType != QueryType.extended &&
        newFilter.forceExtendedQuery) {
      //Prevents infinite recursion
      return newFilter.copyWith(
        query: newFilter.query.copyWith(queryType: QueryType.extended),
      );
    }
    return newFilter;
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
        ((query.queryText ?? '') != (initial.query.queryText ?? '')),
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
        query,
      ];

  factory DocumentFilter.fromJson(Map<String, dynamic> json) =>
      _$DocumentFilterFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentFilterToJson(this);
}
