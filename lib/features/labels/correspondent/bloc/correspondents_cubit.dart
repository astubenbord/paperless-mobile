import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:paperless_mobile/features/labels/correspondent/model/correspondent.model.dart';
import 'package:injectable/injectable.dart';

@singleton
class CorrespondentCubit extends LabelCubit<Correspondent> {
  CorrespondentCubit(super.metaDataService);

  @override
  Future<void> initialize() async {
    return labelRepository.getCorrespondents().then(loadFrom);
  }

  @override
  Future<Correspondent> save(Correspondent item) =>
      labelRepository.saveCorrespondent(item);

  @override
  Future<Correspondent> update(Correspondent item) =>
      labelRepository.updateCorrespondent(item);

  @override
  Future<int> delete(Correspondent item) =>
      labelRepository.deleteCorrespondent(item);
}
