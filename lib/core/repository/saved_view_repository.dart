import 'package:paperless_api/paperless_api.dart';

abstract class SavedViewRepository {
  Stream<Map<int, SavedView>> get savedViews;

  Future<SavedView> create(SavedView view);
  Future<SavedView?> find(int id);
  Future<Iterable<SavedView>> findAll([Iterable<int>? ids]);
  Future<int> delete(SavedView view);

  void clear();
}
