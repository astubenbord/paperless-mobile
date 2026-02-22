import 'package:paperless_api/paperless_api.dart';

abstract interface class PaperlessTrashApi {
  Future<PagedSearchResult<DocumentModel>> findTrashed({
    int page = 1,
    int pageSize = 25,
  });
  Future<void> restoreDocument(int id);
  Future<void> emptyTrash();
}
