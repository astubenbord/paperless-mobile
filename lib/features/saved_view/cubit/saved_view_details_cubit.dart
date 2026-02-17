import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_app_state.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/paging/cubit/paged_documents_state.dart';
import 'package:paperless_mobile/core/paging/cubit/document_paging_bloc_mixin.dart';
import 'package:paperless_mobile/core/model/view_type.dart';

part 'saved_view_details_state.dart';

class SavedViewDetailsCubit extends Cubit<SavedViewDetailsState>
    with DocumentPagingBlocMixin {
  @override
  final PaperlessDocumentsApi api;

  final LabelRepository _labelRepository;
  @override
  final ConnectivityStatusService connectivityStatusService;
  @override
  final DocumentChangedNotifier notifier;

  final SavedView savedView;

  final LocalUserAppState _userState;

  SavedViewDetailsCubit(
    this.api,
    this.notifier,
    this._labelRepository,
    this._userState,
    this.connectivityStatusService, {
    required this.savedView,
    int initialCount = 25,
  }) : super(
          SavedViewDetailsState(viewType: _userState.savedViewsViewType),
        ) {
    notifier.addListener(
      this,
      onDeleted: remove,
      onUpdated: replace,
    );
    updateFilter(
      filter: savedView.toDocumentFilter().copyWith(
            page: 1,
            pageSize: initialCount,
          ),
    );
  }

  void setViewType(ViewType viewType) {
    emit(state.copyWith(viewType: viewType));
    _userState
      ..savedViewsViewType = viewType
      ..save();
  }

  @override
  Future<void> onFilterUpdated(DocumentFilter filter) async {}
}
