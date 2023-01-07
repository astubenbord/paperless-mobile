import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paperless_mobile/core/repository/state/repository_state.dart';
import 'package:rxdart/subjects.dart';

///
/// Base repository class which all repositories should implement
///
abstract class BaseRepository<State extends RepositoryState, Type>
    extends Cubit<State> with HydratedMixin {
  final State _initialState;

  BaseRepository(this._initialState) : super(_initialState) {
    hydrate();
  }

  Stream<State?> get values =>
      BehaviorSubject.seeded(state)..addStream(super.stream);

  State? get current => state;

  bool get isInitialized => state.hasLoaded;

  Future<Type> create(Type object);
  Future<Type?> find(int id);
  Future<Iterable<Type>> findAll([Iterable<int>? ids]);
  Future<Type> update(Type object);
  Future<int> delete(Type object);

  @override
  Future<void> clear() async {
    await super.clear();
    emit(_initialState);
  }
}
