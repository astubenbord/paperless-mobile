import 'package:bloc/bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/logging/logger.dart';
import 'package:paperless_mobile/features/paged_document_view/cubit/document_paging_bloc_mixin.dart';
import 'package:paperless_mobile/features/paged_document_view/cubit/paged_documents_state.dart';

part 'similar_documents_state.dart';

class SimilarDocumentsCubit extends Cubit<SimilarDocumentsState>
    with DocumentPagingBlocMixin {
  final int documentId;
  @override
  final ConnectivityStatusService connectivityStatusService;

  @override
  final PaperlessDocumentsApi api;

  @override
  final DocumentChangedNotifier notifier;

  SimilarDocumentsCubit(
    this.api,
    this.notifier,
    this.connectivityStatusService, {
    required this.documentId,
  }) : super(const SimilarDocumentsState(filter: DocumentFilter())) {
    notifier.addListener(
      this,
      onDeleted: remove,
      onUpdated: replace,
    );
  }

  @override
  Future<void> initialize() async {
    if (!state.hasLoaded) {
      try {
        await updateFilter(
          filter: state.filter.copyWith(
            moreLike: () => documentId,
            sortField: SortField.score,
          ),
        );
        emit(state.copyWith(error: null));
      } on PaperlessApiException catch (e, stackTrace) {
        logger.fe(
          "An error occurred while loading similar documents for document $documentId",
          className: "SimilarDocumentsCubit",
          methodName: "initialize",
          error: e.details,
          stackTrace: stackTrace,
        );
        emit(state.copyWith(error: e.code));
      }
    }
  }

  @override
  Future<void> close() {
    notifier.removeListener(this);
    return super.close();
  }

  @override
  Future<void> onFilterUpdated(DocumentFilter filter) async {}
}
