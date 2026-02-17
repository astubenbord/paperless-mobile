import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/features/paged_document_view/cubit/paged_documents_state.dart';
import 'package:paperless_mobile/features/paged_document_view/cubit/document_paging_bloc_mixin.dart';
import 'package:paperless_mobile/core/model/view_type.dart';
part 'linked_documents_state.dart';

part 'linked_documents_cubit.g.dart';

class LinkedDocumentsCubit extends HydratedCubit<LinkedDocumentsState>
    with DocumentPagingBlocMixin {
  @override
  final PaperlessDocumentsApi api;
  @override
  final ConnectivityStatusService connectivityStatusService;
  @override
  final DocumentChangedNotifier notifier;
  LinkedDocumentsCubit(
    DocumentFilter filter,
    this.api,
    this.notifier,
    this.connectivityStatusService,
  ) : super(LinkedDocumentsState(filter: filter)) {
    updateFilter(filter: filter);
    notifier.addListener(
      this,
      onUpdated: replace,
      onDeleted: remove,
    );
  }

  @override
  Future<void> update(DocumentModel document) async {
    final updated = await api.update(document);
    if (!state.filter.matches(updated)) {
      remove(document);
    } else {
      replace(document);
    }
  }

  void setViewType(ViewType type) {
    emit(state.copyWith(viewType: type));
  }

  @override
  LinkedDocumentsState? fromJson(Map<String, dynamic> json) {
    return LinkedDocumentsState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(LinkedDocumentsState state) {
    return state.toJson();
  }

  @override
  Future<void> onFilterUpdated(DocumentFilter filter) async {}
}
