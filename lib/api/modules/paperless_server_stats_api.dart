import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:paperless_mobile/api/models/exception/exception.dart';
import 'package:paperless_mobile/api/models/paperless_server_information_model.dart';
import 'package:paperless_mobile/api/models/paperless_server_statistics_model.dart';
import 'package:paperless_mobile/api/utils/request_utils.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';

///
/// API for retrieving information about paperless server state,
/// such as version number, and statistics including documents in
/// inbox and total number of documents.
///
abstract class PaperlessServerStatsApi {
  Future<PaperlessServerInformationModel> getServerInformation();
  Future<PaperlessServerStatisticsModel> getServerStatistics();
}

class PaperlessServerStatsApiImpl implements PaperlessServerStatsApi {
  final Dio client;
  static const _fallbackVersion = '0.0.0';
  PaperlessServerStatsApiImpl(this.client);

  @override
  Future<PaperlessServerInformationModel> getServerInformation() async {
    try {
      final response = await client.get(
        "/api/remote_version/",
        options: Options(
          validateStatus: (status) => status == 200,
          receiveTimeout: 5.seconds,
          sendTimeout: 5.seconds,
        ),
      );
      final latestVersion = response.data["version"] as String;
      final version =
          response.headers.value(
            PaperlessServerInformationModel.versionHeader,
          ) ??
          _fallbackVersion;
      final updateAvailable = response.data["update_available"] as bool;
      return PaperlessServerInformationModel(
        latestVersion: latestVersion,
        version: version,
        isUpdateAvailable: updateAvailable,
      );
    } on DioException catch (exception, stackTrace) {
      logger.fe(
        'Could not retrieve server information via /api/remote_version/. Does your instance have access to the internet?',
        error: exception,
        stackTrace: stackTrace,
        className: runtimeType.toString(),
        methodName: 'getServerInformation',
      );
      return PaperlessServerInformationModel(
        version: _fallbackVersion,
        isUpdateAvailable: false,
        latestVersion: _fallbackVersion,
      );
    }
  }

  @override
  Future<PaperlessServerStatisticsModel> getServerStatistics() async {
    final result = await getSingleResult(
      '/api/statistics/',
      PaperlessServerStatisticsModel.fromJson,
      ErrorCode.serverStatisticsLoadFailed,
      client: client,
    );
    if (result == null) {
      throw const PaperlessApiException(ErrorCode.serverStatisticsLoadFailed);
    }
    return result;
  }
}
