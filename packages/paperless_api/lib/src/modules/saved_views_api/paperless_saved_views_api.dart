import 'package:paperless_api/src/models/saved_view_model.dart';

abstract class PaperlessSavedViewsApi {
  Future<List<SavedView>> getAll();

  Future<SavedView> save(SavedView view);
  Future<int> delete(SavedView view);
}
