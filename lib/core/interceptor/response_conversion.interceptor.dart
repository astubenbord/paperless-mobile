import 'package:http_interceptor/http_interceptor.dart';

const interceptedRoutes = ['thumb/'];

class ResponseConversionInterceptor implements InterceptorContract {
  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async =>
      request;

  @override
  Future<BaseResponse> interceptResponse(
      {required BaseResponse response}) async {
    final String requestUrl =
        response.request?.url.toString().split("?").first ?? '';
    if (response.request?.method == "GET" &&
        interceptedRoutes.any((element) => requestUrl.endsWith(element))) {
      final resp = response as Response;

      return StreamedResponse(
        Stream.value(resp.bodyBytes.toList()).asBroadcastStream(),
        resp.statusCode,
        contentLength: resp.contentLength,
        headers: resp.headers,
        isRedirect: resp.isRedirect,
        persistentConnection: false,
        reasonPhrase: resp.reasonPhrase,
        request: resp.request,
      );
    }
    return response;
  }

  @override
  Future<bool> shouldInterceptRequest() async => true;

  @override
  Future<bool> shouldInterceptResponse() async => true;
}
