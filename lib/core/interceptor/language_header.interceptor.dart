import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:injectable/injectable.dart';

@injectable
class LanguageHeaderInterceptor implements InterceptorContract {
  final ApplicationSettingsCubit appSettingsCubit;

  LanguageHeaderInterceptor(this.appSettingsCubit);

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    late String languages;
    if (appSettingsCubit.state.preferredLocaleSubtag == "en") {
      languages = "en";
    } else {
      languages = appSettingsCubit.state.preferredLocaleSubtag +
          ",en;q=0.7,en-US;q=0.6";
    }
    request.headers.addAll({"Accept-Language": languages});
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse(
          {required BaseResponse response}) async =>
      response;
}
