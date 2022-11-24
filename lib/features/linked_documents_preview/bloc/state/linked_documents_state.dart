import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/model/paged_search_result.dart';

class LinkedDocumentsState {
  final bool isLoaded;
  final PagedSearchResult<DocumentModel>? documents;
  final DocumentFilter? filter;

  LinkedDocumentsState({
    this.filter,
    this.isLoaded = false,
    this.documents,
  });
}
