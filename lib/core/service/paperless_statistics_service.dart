import 'dart:convert';

import 'package:http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/model/paperless_statistics.dart';
import 'package:paperless_mobile/core/type/types.dart';

abstract class PaperlessStatisticsService {
  Future<PaperlessStatistics> getStatistics();
}

@Injectable(as: PaperlessStatisticsService)
class PaperlessStatisticsServiceImpl extends PaperlessStatisticsService {
  final BaseClient client;

  PaperlessStatisticsServiceImpl(@Named('timeoutClient') this.client);

  @override
  Future<PaperlessStatistics> getStatistics() async {
    final response = await client.get(Uri.parse('/api/statistics/'));
    if (response.statusCode == 200) {
      return PaperlessStatistics.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as JSON,
      );
    }
    throw const ErrorMessage.unknown();
  }
}
