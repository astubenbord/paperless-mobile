import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:injectable/injectable.dart';

@singleton
class TagCubit extends LabelCubit<Tag> {
  TagCubit(super.metaDataService);

  @override
  Future<void> initialize() async {
    return labelsApi.getTags().then(loadFrom);
  }

  @override
  Future<Tag> save(Tag item) => labelsApi.saveTag(item);

  @override
  Future<Tag> update(Tag item) => labelsApi.updateTag(item);

  @override
  Future<int> delete(Tag item) => labelsApi.deleteTag(item);
}
