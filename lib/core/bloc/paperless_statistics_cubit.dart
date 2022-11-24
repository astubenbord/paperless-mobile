import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_mobile/core/model/paperless_statistics.dart';
import 'package:paperless_mobile/core/model/paperless_statistics_state.dart';
import 'package:paperless_mobile/core/service/paperless_statistics_service.dart';

@singleton
class PaperlessStatisticsCubit extends Cubit<PaperlessStatisticsState> {
  final PaperlessStatisticsService statisticsService;

  PaperlessStatisticsCubit(this.statisticsService)
      : super(PaperlessStatisticsState(isLoaded: false));

  Future<void> updateStatistics() async {
    final stats = await statisticsService.getStatistics();
    emit(PaperlessStatisticsState(isLoaded: true, statistics: stats));
  }

  void decrementInboxCount() {
    if (state.isLoaded) {
      emit(
        PaperlessStatisticsState(
          isLoaded: true,
          statistics: PaperlessStatistics(
            documentsInInbox: max(0, state.statistics!.documentsInInbox - 1),
            documentsTotal: state.statistics!.documentsTotal,
          ),
        ),
      );
    }
  }

  void incrementInboxCount() {
    if (state.isLoaded) {
      emit(
        PaperlessStatisticsState(
          isLoaded: true,
          statistics: PaperlessStatistics(
            documentsInInbox: state.statistics!.documentsInInbox + 1,
            documentsTotal: state.statistics!.documentsTotal,
          ),
        ),
      );
    }
  }

  void resetInboxCount() {
    if (state.isLoaded) {
      emit(
        PaperlessStatisticsState(
          isLoaded: true,
          statistics: PaperlessStatistics(
            documentsInInbox: 0,
            documentsTotal: state.statistics!.documentsTotal,
          ),
        ),
      );
    }
  }
}
