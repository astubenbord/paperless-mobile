import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthenticationCubit extends Cubit<LocalAuthenticationState> {
  LocalAuthenticationCubit() : super(LocalAuthenticationState(false));

  Future<void> authorize(String localizedMessage) async {
    final isAuthenticationSuccessful = await getIt<LocalAuthentication>()
        .authenticate(localizedReason: localizedMessage);
    if (isAuthenticationSuccessful) {
      emit(LocalAuthenticationState(true));
    } else {
      throw const PaperlessServerException(
          ErrorCode.biometricAuthenticationFailed);
    }
  }
}

class LocalAuthenticationState {
  final bool isAuthorized;

  LocalAuthenticationState(this.isAuthorized);
}
