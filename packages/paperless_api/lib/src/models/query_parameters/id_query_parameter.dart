import 'package:equatable/equatable.dart';

class IdQueryParameter extends Equatable {
  final int? _assignmentStatus;
  final int? _id;

  const IdQueryParameter.notAssigned()
      : _assignmentStatus = 1,
        _id = null;

  const IdQueryParameter.anyAssigned()
      : _assignmentStatus = 0,
        _id = null;

  const IdQueryParameter.fromId(int? id)
      : _assignmentStatus = null,
        _id = id;

  const IdQueryParameter.unset() : this.fromId(null);

  bool get isUnset => _id == null && _assignmentStatus == null;

  bool get isSet => _id != null && _assignmentStatus == null;

  bool get onlyNotAssigned => _assignmentStatus == 1;

  bool get onlyAssigned => _assignmentStatus == 0;

  int? get id => _id;

  Map<String, String> toQueryParameter(String field) {
    final Map<String, String> params = {};
    if (onlyNotAssigned || onlyAssigned) {
      params.putIfAbsent(
          '${field}__isnull', () => _assignmentStatus!.toString());
    }
    if (isSet) {
      params.putIfAbsent("${field}__id", () => id!.toString());
    }
    return params;
  }

  @override
  List<Object?> get props => [_assignmentStatus, _id];
}
