import 'package:dio/dio.dart';
import 'package:paperless_mobile/api/models/models.dart';
import 'package:paperless_mobile/api/extensions/extensions.dart';
import 'package:paperless_mobile/api/modules/base_crud_api_impl_mixin.dart';
import 'package:paperless_mobile/api/modules/crud_api.dart';

abstract class PaperlessUserApi
    extends CrudApi<User, UserRequest, PatchedUserRequest, UserFilterOptions> {
  Future<User?> getCurrentUser();
  Future<String> deactivateTotp(int id);
  Future<Profile> getProfile();
  Future<UiSettingsView> getUiSettings();
}

class PaperlessUserApiImpl extends PaperlessUserApi
    with
        BaseCrudApiImplMixin<
          User,
          UserRequest,
          PatchedUserRequest,
          UserFilterOptions
        > {
  @override
  final Dio client;

  PaperlessUserApiImpl(this.client);

  @override
  String get path => "/api/users";
  @override
  UserFilterOptions defaultFilterOptions = const UserFilterOptions();

  @override
  User parse(Map<String, dynamic> json) => User.fromJson(json);

  @override
  ErrorCode get createErrorCode => ErrorCode.userCreateError;
  @override
  ErrorCode get deleteErrorCode => ErrorCode.userDeleteError;
  @override
  ErrorCode get getErrorCode => ErrorCode.userGetError;
  @override
  ErrorCode get listErrorCode => ErrorCode.userListError;
  @override
  ErrorCode get patchErrorCode => ErrorCode.userUpdateError;
  @override
  ErrorCode get putErrorCode => ErrorCode.userUpdateError;

  @override
  Future<User?> getCurrentUser() async {
    try {
      final response = await client.get('/api/ui_settings/');

      final uiSettings = UiSettingsView.fromJson(response.data!);
      if (uiSettings.user.id == null) {
        throw PaperlessApiException(
          ErrorCode.userGetError,
          details: "Could not retrieve current user from UI settings.",
        );
      }
      return get(uiSettings.user.id!);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.userGetError),
      );
    }
  }

  @override
  Future<String> deactivateTotp(int id) {
    try {
      return client
          .post<Map<String, dynamic>>('/api/users/$id/deactivate_totp/')
          .then((response) => response.data!['detail'] as String);
    } catch (e) {
      throw PaperlessApiException(
        ErrorCode.userUpdateError,
        details: "Could not deactivate TOTP for user with id $id: $e",
      );
    }
  }

  @override
  Future<Profile> getProfile() async {
    try {
      final response = await client.get('/api/profile/');
      return Profile.fromJson(response.data!);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.profileGetError),
      );
    }
  }

  @override
  Future<UiSettingsView> getUiSettings() async {
    try {
      final response = await client.get('/api/ui_settings/');
      final data = Map<String, dynamic>.from(response.data!);
      if (!data.containsKey('user')) {
        throw PaperlessApiException(
          ErrorCode.uiSettingsLoadFailed,
          details:
              'The v10 UI settings response omits user identity required by the current UI.',
        );
      }
      return UiSettingsView.fromJson(data);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.uiSettingsLoadFailed),
      );
    }
  }
}
