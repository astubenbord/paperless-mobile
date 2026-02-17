import 'dart:async';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_app_state.dart';
import 'package:paperless_mobile/core/extensions/document_extensions.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/paging/cubit/document_paging_bloc_mixin.dart';
import 'package:paperless_mobile/core/paging/cubit/paged_documents_state.dart';
import 'package:paperless_mobile/core/model/view_type.dart';

part 'documents_state.dart';

class DocumentsCubit extends Cubit<DocumentsState>
    with DocumentPagingBlocMixin {
  @override
  final PaperlessDocumentsApi api;

  @override
  final ConnectivityStatusService connectivityStatusService;

  @override
  final DocumentChangedNotifier notifier;

  final LocalUserAppState _userState;

  DocumentsCubit(
    this.api,
    this.notifier,
    this._userState,
    this.connectivityStatusService,
  ) : super(DocumentsState(
          filter: _userState.currentDocumentFilter,
          viewType: _userState.documentsPageViewType,
        )) {
    notifier.addListener(
      this,
      onUpdated: (document) {
        replace(document);
        emit(
          state.copyWith(
              selection:
                  state.selection.withDocumentreplaced(document).toList()),
        );
      },
      onDeleted: (document) {
        remove(document);
        emit(
          state.copyWith(
            selection: state.selection.withDocumentRemoved(document).toList(),
          ),
        );
      },
    );
  }

  Future<void> bulkDelete(List<DocumentModel> documents) async {
    await api.bulkAction(
      BulkDeleteAction(documents.map((doc) => doc.id)),
    );
    for (final deletedDoc in documents) {
      notifier.notifyDeleted(deletedDoc);
    }
    await reload();
  }

  void toggleDocumentSelection(DocumentModel model) {
    if (state.selectedIds.contains(model.id)) {
      emit(
        state.copyWith(
          selection: state.selection
              .where((element) => element.id != model.id)
              .toList(),
        ),
      );
    } else {
      emit(state.copyWith(selection: [...state.selection, model]));
    }
  }

  void resetSelection() {
    emit(state.copyWith(selection: []));
  }

  void reset() {
    emit(const DocumentsState());
  }

  Future<Iterable<String>> autocomplete(String query) async {
    final res = await api.autocomplete(query);
    return res;
  }

  @override
  Future<void> close() {
    notifier.removeListener(this);
    return super.close();
  }

  void setViewType(ViewType viewType) {
    emit(state.copyWith(viewType: viewType));
    _userState
      ..documentsPageViewType = viewType
      ..save();
  }

  @override
  Future<void> onFilterUpdated(DocumentFilter filter) async {
    _userState.currentDocumentFilter = filter;
    await _userState.save();
  }

  // @override
  // DocumentsState? fromJson(Map<String, dynamic> json) {
  //   return DocumentsState.fromJson(json);
  // }

  // @override
  // Map<String, dynamic>? toJson(DocumentsState state) {
  //   return state.toJson();
  // }
}
