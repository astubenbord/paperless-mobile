import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_state.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';

extension AddressableHydratedStorage on Storage {
  ApplicationSettingsState get settings {
    return ApplicationSettingsState.fromJson(read('ApplicationSettingsCubit'));
  }

  AuthenticationState get authentication {
    return AuthenticationState.fromJson(read('AuthenticationCubit'));
  }
}
