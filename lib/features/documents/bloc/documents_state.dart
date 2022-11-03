import 'package:equatable/equatable.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/model/paged_search_result.dart';

class DocumentsState extends Equatable {
  final bool isLoaded;
  final DocumentFilter filter;
  final List<PagedSearchResult> value;
  final List<DocumentModel> selection;

  const DocumentsState({
    required this.isLoaded,
    required this.value,
    required this.filter,
    this.selection = const [],
  });

  static const DocumentsState initial = DocumentsState(
    isLoaded: false,
    value: [],
    filter: DocumentFilter.initial,
    selection: [],
  );

  int get currentPageNumber {
    return filter.page;
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
    if (!isLoaded) {
      return false;
    }
    if (value.isNotEmpty) {
      return value.last.next == null;
    }
    return true;
  }

  int inferPageCount({required int pageSize}) {
    if (!isLoaded) {
      return 100000;
    }
    if (value.isEmpty) {
      return 0;
    }
    return value.first.inferPageCount(pageSize: pageSize);
  }

  List<DocumentModel> get documents {
    return value.fold(
        [], (previousValue, element) => [...previousValue, ...element.results]);
  }

  DocumentsState copyWith({
    bool overwrite = false,
    bool? isLoaded,
    List<PagedSearchResult>? value,
    DocumentFilter? filter,
    List<DocumentModel>? selection,
  }) {
    return DocumentsState(
      isLoaded: isLoaded ?? this.isLoaded,
      value: value ?? this.value,
      filter: filter ?? this.filter,
      selection: selection ?? this.selection,
    );
  }

  @override
  List<Object?> get props => [isLoaded, filter, value, selection];
}
