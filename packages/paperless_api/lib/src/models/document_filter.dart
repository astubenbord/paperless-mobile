import 'package:equatable/equatable.dart';
import 'package:paperless_api/src/constants.dart';
import 'package:paperless_api/src/models/query_parameters/asn_query.dart';
import 'package:paperless_api/src/models/query_parameters/correspondent_query.dart';
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
  final DateTime? addedDateAfter;
  final DateTime? addedDateBefore;
  final DateTime? createdDateAfter;
  final DateTime? createdDateBefore;
  final QueryType queryType;
  final String? queryText;

  const DocumentFilter({
    this.createdDateAfter,
    this.createdDateBefore,
    this.documentType = const DocumentTypeQuery.unset(),
    this.correspondent = const CorrespondentQuery.unset(),
    this.storagePath = const StoragePathQuery.unset(),
    this.asnQuery = const AsnQuery.unset(),
    this.tags = const IdsTagsQuery(),
    this.sortField = SortField.created,
    this.sortOrder = SortOrder.descending,
    this.page = 1,
    this.pageSize = 25,
    this.addedDateAfter,
    this.addedDateBefore,
    this.queryType = QueryType.titleAndContent,
    this.queryText,
  });

  String toQueryString() {
    final StringBuffer sb = StringBuffer("page=$page&page_size=$pageSize");
    sb.write(documentType.toQueryParameter());
    sb.write(correspondent.toQueryParameter());
    sb.write(tags.toQueryParameter());
    sb.write(storagePath.toQueryParameter());
    sb.write(asnQuery.toQueryParameter());

    if (queryText?.isNotEmpty ?? false) {
      sb.write("&${queryType.queryParam}=$queryText");
    }

    sb.write("&ordering=${sortOrder.queryString}${sortField.queryString}");

    // Add/subtract one day in the following because paperless uses gt/lt not gte/lte
    if (addedDateAfter != null) {
      sb.write(
          "&added__date__gt=${apiDateFormat.format(addedDateAfter!.subtract(_oneDay))}");
    }

    if (addedDateBefore != null) {
      sb.write(
          "&added__date__lt=${apiDateFormat.format(addedDateBefore!.add(_oneDay))}");
    }

    if (createdDateAfter != null) {
      sb.write(
          "&created__date__gt=${apiDateFormat.format(createdDateAfter!.subtract(_oneDay))}");
    }

    if (createdDateBefore != null) {
      sb.write(
          "&created__date__lt=${apiDateFormat.format(createdDateBefore!.add(_oneDay))}");
    }

    return sb.toString();
  }

  @override
  String toString() {
    return toQueryString();
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
    DateTime? addedDateAfter,
    DateTime? addedDateBefore,
    DateTime? createdDateBefore,
    DateTime? createdDateAfter,
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
      addedDateAfter: addedDateAfter ?? this.addedDateAfter,
      addedDateBefore: addedDateBefore ?? this.addedDateBefore,
      queryType: queryType ?? this.queryType,
      queryText: queryText ?? this.queryText,
      createdDateBefore: createdDateBefore ?? this.createdDateBefore,
      createdDateAfter: createdDateAfter ?? this.createdDateAfter,
      asnQuery: asnQuery ?? this.asnQuery,
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
        (addedDateAfter != initial.addedDateAfter ||
            addedDateBefore != initial.addedDateBefore),
        (createdDateAfter != initial.createdDateAfter ||
            createdDateBefore != initial.createdDateBefore),
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
        addedDateAfter,
        addedDateBefore,
        createdDateAfter,
        createdDateBefore,
        queryType,
        queryText,
      ];
}
