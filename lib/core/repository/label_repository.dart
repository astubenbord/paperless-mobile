import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/base_repository.dart';
import 'package:paperless_mobile/core/repository/state/repository_state.dart';

abstract class LabelRepository<T extends Label, State extends RepositoryState>
    extends BaseRepository<State, T> {
  LabelRepository(State initial) : super(initial);
}
