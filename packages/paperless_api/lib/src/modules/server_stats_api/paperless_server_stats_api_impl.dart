import 'dart:convert';

import 'package:dio/dio.dart';
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
  final Dio client;

  PaperlessServerStatsApiImpl(this.client);

  @override
  Future<PaperlessServerInformationModel> getServerInformation() async {
    final response = await client.get("/api/ui_settings/");
    final version = response
            .headers[PaperlessServerInformationModel.versionHeader]?.first ??
        'unknown';
    final apiVersion = int.tryParse(response
            .headers[PaperlessServerInformationModel.apiVersionHeader]?.first ??
        '1');
    final String username = response.data['username'];
    final String host = response
            .headers[PaperlessServerInformationModel.hostHeader]?.first ??
        response.headers[PaperlessServerInformationModel.hostHeader]?.first ??
        ('${response.requestOptions.uri.host}:${response.requestOptions.uri.port}');
    return PaperlessServerInformationModel(
      username: username,
      version: version,
      apiVersion: apiVersion,
      host: host,
    );
  }

  @override
  Future<PaperlessServerStatisticsModel> getServerStatistics() async {
    final response = await client.get('/api/statistics/');
    if (response.statusCode == 200) {
      return PaperlessServerStatisticsModel.fromJson(response.data);
    }
    throw const PaperlessServerException.unknown();
  }
}
