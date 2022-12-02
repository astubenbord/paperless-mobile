import 'package:injectable/injectable.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';

@singleton
class StoragePathCubit extends LabelCubit<StoragePath> {
  StoragePathCubit(super.metaDataService);

  @override
  Future<void> initialize() async {
    return labelsApi.getStoragePaths().then(loadFrom);
  }

  @override
  Future<StoragePath> save(StoragePath item) => labelsApi.saveStoragePath(item);

  @override
  Future<StoragePath> update(StoragePath item) =>
      labelsApi.updateStoragePath(item);

  @override
  Future<int> delete(StoragePath item) => labelsApi.deleteStoragePath(item);
}
