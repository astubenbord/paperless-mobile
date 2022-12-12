import 'package:http_interceptor/http_interceptor.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';

@prod
@injectable
class BaseUrlInterceptor implements InterceptorContract {
  final LocalVault _localVault;

  BaseUrlInterceptor(this._localVault);
  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    final auth = await _localVault.loadAuthenticationInformation();
    if (auth == null) {
      throw Exception(
        "Authentication information not available, cannot perform request!",
      );
    }
    return request.copyWith(
      url: Uri.parse(auth.serverUrl + request.url.toString()),
    );
  }

  @override
  Future<BaseResponse> interceptResponse(
          {required BaseResponse response}) async =>
      response;

  @override
  Future<bool> shouldInterceptRequest() async => true;

  @override
  Future<bool> shouldInterceptResponse() async => true;
}
