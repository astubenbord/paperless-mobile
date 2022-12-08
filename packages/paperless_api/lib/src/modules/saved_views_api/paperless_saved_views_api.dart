import 'package:paperless_api/src/models/saved_view_model.dart';

abstract class PaperlessSavedViewsApi {
  Future<SavedView> find(int id);
  Future<Iterable<SavedView>> findAll([Iterable<int>? ids]);

  Future<SavedView> save(SavedView view);
  Future<int> delete(SavedView view);
}
