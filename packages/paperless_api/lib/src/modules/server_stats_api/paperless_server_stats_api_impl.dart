import 'dart:convert';

import 'package:http/http.dart';
import 'package:paperless_api/src/models/paperless_server_exception.dart';
import 'package:paperless_api/src/models/paperless_server_information_model.dart';
import 'package:paperless_api/src/models/paperless_server_statistics_model.dart';

import 'paperless_server_stats_api.dart';

///
/// API for retrieving information about paperless server state,
/// such as version number, and statistics including documents in
/// inbox and total number of documents.
///
class PaperlessServerStatsApiImpl implements PaperlessServerStatsApi {
  final BaseClient client;

  PaperlessServerStatsApiImpl(this.client);

  @override
  Future<PaperlessServerInformationModel> getServerInformation() async {
    final response = await client.get(Uri.parse("/api/ui_settings/"));
    final version =
        response.headers[PaperlessServerInformationModel.versionHeader] ??
            'unknown';
    final apiVersion = int.tryParse(
        response.headers[PaperlessServerInformationModel.apiVersionHeader] ??
            '1');
    final String username =
        jsonDecode(utf8.decode(response.bodyBytes))['username'];
    final String host = response
            .headers[PaperlessServerInformationModel.hostHeader] ??
        response.request?.headers[PaperlessServerInformationModel.hostHeader] ??
        ('${response.request?.url.host}:${response.request?.url.port}');
    return PaperlessServerInformationModel(
      username: username,
      version: version,
      apiVersion: apiVersion,
      host: host,
    );
  }

  @override
  Future<PaperlessServerStatisticsModel> getServerStatistics() async {
    final response = await client.get(Uri.parse('/api/statistics/'));
    if (response.statusCode == 200) {
      return PaperlessServerStatisticsModel.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw const PaperlessServerException.unknown();
  }
}
