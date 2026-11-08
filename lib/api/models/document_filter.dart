import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/api/models/query_parameters/asn_query_parameter.dart';

part 'document_filter.freezed.dart';
part 'document_filter.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class DocumentFilter with _$DocumentFilter {
  const DocumentFilter._();

  static const DocumentFilter initial = DocumentFilter();

  static const DocumentFilter latestDocument = DocumentFilter(
    sortField: SortField.added,
    sortOrder: SortOrder.descending,
    pageSize: 1,
    page: 1,
  );

  const factory DocumentFilter({
    @Default(IdQueryParameter.unset()) IdQueryParameter documentType,
    @Default(IdQueryParameter.unset()) IdQueryParameter correspondent,
    @Default(IdQueryParameter.unset()) IdQueryParameter storagePath,
    AsnQueryParameter? archiveSerialNumber,
    @Default(IdsTagsQuery()) TagsQuery tags,
    @Default(SortField.created) SortField? sortField,
    @Default(SortOrder.descending) SortOrder sortOrder,
    @Default(1) int page,
    @Default(25) int pageSize,
    @Default(TextQuery()) TextQuery query,
    @Default(UnsetDateRangeQuery()) DateRangeQuery added,
    @Default(UnsetDateRangeQuery()) DateRangeQuery created,
    @Default(UnsetDateRangeQuery()) DateRangeQuery modified,
    @Default(IdQueryParameter.unset()) IdQueryParameter owner,
    int? moreLike,
    int? selectedView,
    List<String>? fields,
    List<int>? documentIds,
    bool? hasDuplicates,
  }) = _DocumentFilter;

  bool get forceExtendedQuery {
    debugPrint(
      'forceExtendedQuery called ${added.runtimeType}, ${created.runtimeType}, ${modified.runtimeType}',
    );
    return added is RelativeDateRangeQuery ||
        created is RelativeDateRangeQuery ||
        modified is RelativeDateRangeQuery;
  }

  Map<String, dynamic> toQueryParameters() {
    List<MapEntry<String, dynamic>> params = [
      MapEntry('page', page),
      MapEntry('page_size', pageSize),
      ...documentType.toQueryParameter('document_type').entries,
      ...correspondent.toQueryParameter('correspondent').entries,
      ...storagePath.toQueryParameter('storage_path').entries,
      ...(archiveSerialNumber != null
          ? archiveSerialNumber!.toQueryParameter().entries
          : []),
      ...tags.toQueryParameter().entries,
      ...added.toQueryParameter(DateRangeQueryField.added).entries,
      ...created.toQueryParameter(DateRangeQueryField.created).entries,
      ...modified.toQueryParameter(DateRangeQueryField.modified).entries,
      ...owner.toQueryParameter('owner').entries,
      ...query.toQueryParameter().entries,
      if (sortField != null)
        MapEntry('ordering', '${sortOrder.queryString}${sortField!.value}'),
      if (moreLike != null) MapEntry('more_like_id', moreLike),
      if (fields?.isNotEmpty ?? false) MapEntry('fields', fields!.join(",")),
      if (documentIds?.isNotEmpty ?? false)
        MapEntry('id__in', documentIds!.join(",")),
      if (hasDuplicates != null) MapEntry('has_duplicates', hasDuplicates),
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

  int get appliedFiltersCount => [
    switch (documentType) {
      UnsetIdQueryParameter() => 0,
      _ => 1,
    },
    switch (correspondent) {
      UnsetIdQueryParameter() => 0,
      _ => 1,
    },
    switch (storagePath) {
      UnsetIdQueryParameter() => 0,
      _ => 1,
    },
    switch (tags) {
      NotAssignedTagsQuery() => 1,
      AnyAssignedTagsQuery(tagIds: var tags) => tags.length,
      IdsTagsQuery(include: var i, exclude: var e) => e.length + i.length,
    },
    switch (added) {
      UnsetDateRangeQuery() => 0,
      _ => 1,
    },
    switch (created) {
      UnsetDateRangeQuery() => 0,
      _ => 1,
    },
    switch (modified) {
      UnsetDateRangeQuery() => 0,
      _ => 1,
    },
    switch (archiveSerialNumber) {
      null => 0,
      _ => 1,
    },
    switch (owner) {
      UnsetIdQueryParameter() => 0,
      _ => 1,
    },
    (query.queryText?.isNotEmpty ?? false) ? 1 : 0,
    hasDuplicates == null ? 0 : 1,
  ].fold(0, (previousValue, element) => previousValue + element);

  factory DocumentFilter.fromJson(Map<String, dynamic> json) =>
      _$DocumentFilterFromJson(json);
}
