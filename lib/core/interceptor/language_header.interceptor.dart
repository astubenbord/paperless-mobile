import 'package:dio/dio.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';

class LanguageHeaderInterceptor extends Interceptor {
  String preferredLocaleSubtag;
  LanguageHeaderInterceptor(this.preferredLocaleSubtag);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    late String languages;
    if (preferredLocaleSubtag == "en") {
      languages = "en";
    } else {
      languages = "$preferredLocaleSubtag,en;q=0.7,en-US;q=0.6";
    }
    options.headers.addAll({"Accept-Language": languages});
    handler.next(options);
  }
}
