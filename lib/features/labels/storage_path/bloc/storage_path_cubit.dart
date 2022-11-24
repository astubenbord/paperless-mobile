import 'package:injectable/injectable.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:paperless_mobile/features/labels/storage_path/model/storage_path.model.dart';

@singleton
class StoragePathCubit extends LabelCubit<StoragePath> {
  StoragePathCubit(super.metaDataService);

  @override
  Future<void> initialize() async {
    return labelRepository.getStoragePaths().then(loadFrom);
  }

  @override
  Future<StoragePath> save(StoragePath item) =>
      labelRepository.saveStoragePath(item);

  @override
  Future<StoragePath> update(StoragePath item) =>
      labelRepository.updateStoragePath(item);

  @override
  Future<int> delete(StoragePath item) =>
      labelRepository.deleteStoragePath(item);
}
