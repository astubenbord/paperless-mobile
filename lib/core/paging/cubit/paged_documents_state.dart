import 'package:equatable/equatable.dart';
import 'package:paperless_api/paperless_api.dart';

///
/// Base state for all blocs/cubits using a paged view of documents.
/// [T] is the return type of the API call.
///
abstract class DocumentPagingState extends Equatable {
  final bool hasLoaded;
  final bool isLoading;
  final List<PagedSearchResult<DocumentModel>> value;
  final DocumentFilter filter;

  const DocumentPagingState({
    this.value = const [],
    this.hasLoaded = false,
    this.isLoading = false,
    this.filter = const DocumentFilter(),
  });

  List<DocumentModel> get documents {
    return value.fold(
      [],
      (previousValue, element) => [
        ...previousValue,
        ...element.results,
      ],
    );
  }

  int get currentPageNumber {
    assert(value.isNotEmpty);
    return value.last.pageKey;
  }

  int? get nextPageNumber {
    return isLastPageLoaded ? null : currentPageNumber + 1;
  }

  int get count {
    if (value.isEmpty) {
      return 0;
    }
    return value.first.count;
  }

  bool get isLastPageLoaded {
    if (!hasLoaded) {
      return false;
    }
    if (value.isNotEmpty) {
      return value.last.next == null;
    }
    return true;
  }

  int inferPageCount({required int pageSize}) {
    if (!hasLoaded) {
      return 100000;
    }
    if (value.isEmpty) {
      return 0;
    }
    return value.first.inferPageCount(pageSize: pageSize);
  }

  // Return type has to be dynamic
  dynamic copyWithPaged({
    bool? hasLoaded,
    bool? isLoading,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
  });

  @override
  List<Object?> get props => [
        filter,
        value,
        hasLoaded,
        isLoading,
      ];
}
