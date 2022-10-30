import 'package:equatable/equatable.dart';

abstract class IdsQueryParameter with EquatableMixin {
  final List<int> _ids;
  final bool onlyNotAssigned;

  const IdsQueryParameter.fromIds(List<int> ids)
      : onlyNotAssigned = false,
        _ids = ids;

  const IdsQueryParameter.notAssigned()
      : onlyNotAssigned = true,
        _ids = const [];

  const IdsQueryParameter.unset()
      : onlyNotAssigned = false,
        _ids = const [];

  bool get isUnset => _ids.isEmpty && onlyNotAssigned == false;

  bool get isSet => _ids.isNotEmpty && onlyNotAssigned == false;

  List<int> get ids => _ids;

  String toQueryParameter();

  @override
  List<Object?> get props => [onlyNotAssigned, _ids];
}
