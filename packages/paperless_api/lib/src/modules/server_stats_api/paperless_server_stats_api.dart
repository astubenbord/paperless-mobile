import 'package:paperless_api/src/models/paperless_server_information_model.dart';
import 'package:paperless_api/src/models/paperless_server_statistics_model.dart';

abstract class PaperlessServerStatsApi {
  Future<PaperlessServerInformationModel> getServerInformation();
  Future<PaperlessServerStatisticsModel> getServerStatistics();
}
