import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:injectable/injectable.dart';

@prod
@test
@lazySingleton
class DocumentTypeCubit extends LabelCubit<DocumentType> {
  DocumentTypeCubit(super.metaDataService);

  @override
  Future<void> initialize() async {
    labelsApi.getDocumentTypes().then(loadFrom);
  }

  @override
  Future<DocumentType> save(DocumentType item) =>
      labelsApi.saveDocumentType(item);

  @override
  Future<DocumentType> update(DocumentType item) =>
      labelsApi.updateDocumentType(item);

  @override
  Future<int> delete(DocumentType item) => labelsApi.deleteDocumentType(item);
}
