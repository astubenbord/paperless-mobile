import 'package:bloc/bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/document_extensions.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';

part 'saved_view_preview_state.dart';

class SavedViewPreviewCubit extends Cubit<SavedViewPreviewState> {
  final PaperlessDocumentsApi _api;
  final SavedView view;
  final ConnectivityStatusService _connectivityStatusService;
  final DocumentChangedNotifier _changedNotifier;
  SavedViewPreviewCubit(
    this._api,
    this._connectivityStatusService,
    this._changedNotifier, {
    required this.view,
  }) : super(const InitialSavedViewPreviewState()) {
    _changedNotifier.addListener(
      this,
      onDeleted: (document) {
        final s = state;
        if (s is! LoadedSavedViewPreviewState) {
          return;
        }
        if (!s.documents.containsDocument(document)) {
          return;
        }
        emit(
          LoadedSavedViewPreviewState(
            documents: s.documents.withDocumentRemoved(document).toList(),
          ),
        );
      },
      onUpdated: (document) {
        final s = state;
        if (s is! LoadedSavedViewPreviewState) {
          return;
        }
        if (!s.documents.containsDocument(document)) {
          return;
        }

        final shouldRemainInFilter = view.toDocumentFilter().matches(document);
        if (!shouldRemainInFilter) {
          emit(
            LoadedSavedViewPreviewState(
              documents: s.documents.withDocumentRemoved(document).toList(),
            ),
          );
        } else {
          emit(
            LoadedSavedViewPreviewState(
              documents: s.documents.withDocumentreplaced(document).toList(),
            ),
          );
        }
      },
    );
  }

  Future<void> initialize() async {
    final isConnected =
        await _connectivityStatusService.isConnectedToInternet();
    if (!isConnected) {
      emit(const OfflineSavedViewPreviewState());
      return;
    }
    emit(const LoadingSavedViewPreviewState());
    try {
      final documents = await _api.findAll(
        view.toDocumentFilter().copyWith(
              page: 1,
              pageSize: 5,
            ),
      );
      emit(LoadedSavedViewPreviewState(documents: documents.results));
    } catch (e) {
      emit(const ErrorSavedViewPreviewState());
    }
  }
}
