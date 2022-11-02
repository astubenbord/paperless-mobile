import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/service/connectivity_status.service.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:injectable/injectable.dart';

@injectable
class ConnectionStateInterceptor implements InterceptorContract {
  final AuthenticationCubit authenticationCubit;
  final ConnectivityStatusService connectivityStatusService;
  ConnectionStateInterceptor(this.authenticationCubit, this.connectivityStatusService);

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    if (!(await connectivityStatusService.isConnectedToInternet())) {
      throw const ErrorMessage(ErrorCode.deviceOffline);
    }
    final isServerReachable = await connectivityStatusService.isServerReachable(request.url.origin);
    if (!isServerReachable) {
      throw const ErrorMessage(ErrorCode.serverUnreachable);
    }
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({required BaseResponse response}) async => response;
}
