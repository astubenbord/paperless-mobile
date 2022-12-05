import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/model/document_processing_status.dart';
import 'package:injectable/injectable.dart';

@prod
@test
@lazySingleton
class DocumentStatusCubit extends Cubit<DocumentProcessingStatus?> {
  DocumentStatusCubit() : super(null);

  void updateStatus(DocumentProcessingStatus? status) => emit(status);
}
