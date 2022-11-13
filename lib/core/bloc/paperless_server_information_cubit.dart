import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_mobile/core/model/paperless_server_information.dart';
import 'package:paperless_mobile/core/service/paperless_server_information_service.dart';

@singleton
class PaperlessServerInformationCubit
    extends Cubit<PaperlessServerInformation> {
  final PaperlessServerInformationService service;

  PaperlessServerInformationCubit(this.service)
      : super(PaperlessServerInformation());

  Future<void> updateStatus() async {
    emit(await service.getInformation());
  }
}
