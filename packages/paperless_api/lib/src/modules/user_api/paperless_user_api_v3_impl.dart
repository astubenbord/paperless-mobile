import 'package:dio/dio.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_api/src/extensions/dio_exception_extension.dart';

class PaperlessUserApiV3Impl implements PaperlessUserApi, PaperlessUserApiV3 {
  final Dio dio;

  PaperlessUserApiV3Impl(this.dio);

  @override
  Future<UserModelV3> find(int id) async {
    try {
      final response = await dio.get(
        "/api/users/$id/",
        options: Options(validateStatus: (status) => status == 200),
      );
      return UserModelV3.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.userNotFound),
      );
    }
  }

  @override
  Future<Iterable<UserModelV3>> findWhere({
    String startsWith = '',
    String endsWith = '',
    String contains = '',
    String username = '',
  }) async {
    try {
      final response = await dio.get(
        "/api/users/",
        queryParameters: {
          "username__istartswith": startsWith,
          "username__iendswith": endsWith,
          "username__icontains": contains,
          "username__iexact": username,
        },
        options: Options(validateStatus: (status) => status == 200),
      );
      return PagedSearchResult<UserModelV3>.fromJson(
        response.data,
        UserModelV3.fromJson as UserModelV3 Function(Object?),
      ).results;
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.userNotFound),
      );
    }
  }

  @override
  Future<int> findCurrentUserId() async {
    try {
      final response = await dio.get(
        "/api/ui_settings/",
        options: Options(validateStatus: (status) => status == 200),
      );
      final data = response.data;
      if (data is! Map) {
        throw FormatException(
            'Invalid API response. Expected Map, got ${data.runtimeType}. Content: $data');
      }
      return data['user']['id'];
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.userNotFound),
      );
    }
  }

  @override
  Future<Iterable<UserModelV3>> findAll() async {
    try {
      final response = await dio.get(
        "/api/users/",
        options: Options(validateStatus: (status) => status == 200),
      );
      return PagedSearchResult<UserModelV3>.fromJson(
        response.data,
        (json) => UserModelV3.fromJson(json as dynamic),
      ).results;
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.userNotFound),
      );
    }
  }

  @override
  Future<UserModel> findCurrentUser() async {
    final id = await findCurrentUserId();
    return find(id);
  }
}
