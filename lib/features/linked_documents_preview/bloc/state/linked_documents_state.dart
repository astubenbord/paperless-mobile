import 'package:paperless_api/paperless_api.dart';

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
