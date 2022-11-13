import 'package:paperless_mobile/core/bloc/label_cubit.dart';
import 'package:paperless_mobile/features/labels/tags/model/tag.model.dart';
import 'package:injectable/injectable.dart';

@singleton
class TagCubit extends LabelCubit<Tag> {
  TagCubit(super.metaDataService);

  @override
  Future<void> initialize() async {
    return labelRepository.getTags().then(loadFrom);
  }

  @override
  Future<Tag> save(Tag item) => labelRepository.saveTag(item);

  @override
  Future<Tag> update(Tag item) => labelRepository.updateTag(item);

  @override
  Future<int> delete(Tag item) => labelRepository.deleteTag(item);
}
