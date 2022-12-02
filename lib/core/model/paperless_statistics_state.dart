import 'package:paperless_api/paperless_api.dart';

class PaperlessStatisticsState {
  final bool isLoaded;
  final PaperlessServerStatisticsModel? statistics;

  PaperlessStatisticsState({
    required this.isLoaded,
    this.statistics,
  });
}
