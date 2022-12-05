import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:injectable/injectable.dart';

@prod
@test
@lazySingleton
class CorrespondentCubit extends LabelCubit<Correspondent> {
  CorrespondentCubit(super.metaDataService);

  @override
  Future<void> initialize() async {
    return labelsApi.getCorrespondents().then(loadFrom);
  }

  @override
  Future<Correspondent> save(Correspondent item) =>
      labelsApi.saveCorrespondent(item);

  @override
  Future<Correspondent> update(Correspondent item) =>
      labelsApi.updateCorrespondent(item);

  @override
  Future<int> delete(Correspondent item) => labelsApi.deleteCorrespondent(item);
}
