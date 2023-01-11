import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/paperless_server_information_state.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';

class PaperlessServerInformationCubit
    extends Cubit<PaperlessServerInformationState> {
  final PaperlessServerStatsApi _api;

  PaperlessServerInformationCubit(this._api)
      : super(PaperlessServerInformationState());

  Future<void> updateInformtion() async {
    final information = await _api.getServerInformation();
    emit(PaperlessServerInformationState(
      isLoaded: true,
      information: information,
    ));
  }
}
