import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/linked_documents_preview/bloc/state/linked_documents_state.dart';

class LinkedDocumentsCubit extends Cubit<LinkedDocumentsState> {
  final PaperlessDocumentsApi _api;

  LinkedDocumentsCubit(this._api, DocumentFilter filter)
      : super(LinkedDocumentsState(filter: filter)) {
    _initialize();
  }

  Future<void> _initialize() async {
    final documents = await _api.findAll(
      state.filter.copyWith(
        pageSize: 100,
      ),
    );
    emit(LinkedDocumentsState(
      isLoaded: true,
      documents: documents,
      filter: state.filter,
    ));
  }
}
