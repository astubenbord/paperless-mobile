import 'package:paperless_api/paperless_api.dart';

class PaperlessServerInformationState {
  final bool isLoaded;
  final PaperlessServerInformationModel? information;

  PaperlessServerInformationState({
    this.isLoaded = false,
    this.information,
  });
}
