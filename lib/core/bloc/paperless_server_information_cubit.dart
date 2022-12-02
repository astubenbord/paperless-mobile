import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/paperless_server_information_state.dart';

@singleton
class PaperlessServerInformationCubit
    extends Cubit<PaperlessServerInformationState> {
  final PaperlessServerStatsApi service;

  PaperlessServerInformationCubit(this.service)
      : super(PaperlessServerInformationState());

  Future<void> updateInformtion() async {
    final information = await service.getServerInformation();
    emit(PaperlessServerInformationState(
      isLoaded: true,
      information: information,
    ));
  }
}
