import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/repository/document_repository.dart';
import 'package:paperless_mobile/features/linked_documents_preview/bloc/state/linked_documents_state.dart';

@injectable
class LinkedDocumentsCubit extends Cubit<LinkedDocumentsState> {
  final DocumentRepository _documentRepository;

  LinkedDocumentsCubit(this._documentRepository)
      : super(LinkedDocumentsState());

  Future<void> initialize(DocumentFilter filter) async {
    final documents = await _documentRepository.find(
      filter.copyWith(
        pageSize: 100,
      ),
    );
    emit(LinkedDocumentsState(
      isLoaded: true,
      documents: documents,
      filter: filter,
    ));
  }
}
