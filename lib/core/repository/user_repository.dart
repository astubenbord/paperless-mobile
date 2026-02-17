import 'package:equatable/equatable.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/persistent_repository.dart';
import 'package:paperless_mobile/core/logging/logger.dart';

part 'user_repository_state.dart';

class UserRepository extends PersistentRepository<UserRepositoryState> {
  final PaperlessUserApi _userApi;

  UserRepository(this._userApi) : super(const UserRepositoryState());

  Future<void> initialize() async {
    await findAll();
  }

  Future<Iterable<UserModel>> findAll() async {
    if (_userApi is PaperlessUserApiV3Impl) {
      final users = await _userApi.findAll();
      emit(state.copyWith(users: {for (var e in users) e.id: e}));
      return users;
    }
    logger.fw(
      "Tried to access API v3 features while using an older API version.",
      className: 'UserRepository',
      methodName: 'findAll',
    );
    return [];
  }

  Future<UserModel?> find(int id) async {
    if (_userApi is PaperlessUserApiV3Impl) {
      final user = await _userApi.find(id);
      emit(state.copyWith(users: state.users..[id] = user));
      return user;
    }
    logger.fw(
      "Tried to access API v3 features while using an older API version.",
      className: 'UserRepository',
      methodName: 'findAll',
    );
    return null;
  }

  // @override
  // UserRepositoryState? fromJson(Map<String, dynamic> json) {
  //   return UserRepositoryState.fromJson(json);
  // }

  // @override
  // Map<String, dynamic>? toJson(UserRepositoryState state) {
  //   return state.toJson();
  // }
}
