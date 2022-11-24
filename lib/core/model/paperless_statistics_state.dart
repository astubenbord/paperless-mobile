import 'package:paperless_mobile/core/model/paperless_statistics.dart';

class PaperlessStatisticsState {
  final bool isLoaded;
  final PaperlessStatistics? statistics;

  PaperlessStatisticsState({
    required this.isLoaded,
    this.statistics,
  });
}
