import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/base_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/saved_view_repository_state.dart';

abstract class SavedViewRepository
    extends BaseRepository<SavedViewRepositoryState, SavedView> {
  SavedViewRepository(super.initialState);
}
