import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

abstract class IdQueryParameter extends Equatable {
  final bool _onlyNotAssigned;
  final int? _id;

  const IdQueryParameter.notAssigned()
      : _onlyNotAssigned = true,
        _id = null;

  const IdQueryParameter.fromId(int? id)
      : _onlyNotAssigned = false,
        _id = id;

  const IdQueryParameter.unset() : this.fromId(null);

  bool get isUnset => _id == null && _onlyNotAssigned == false;

  bool get isSet => _id != null && _onlyNotAssigned == false;

  bool get onlyNotAssigned => _onlyNotAssigned;

  int? get id => _id;

  @protected
  String get queryParameterKey;

  String toQueryParameter() {
    if (onlyNotAssigned) {
      return "&${queryParameterKey}__isnull=1";
    }

    return isUnset ? "" : "&${queryParameterKey}__id=$id";
  }

  @override
  List<Object?> get props => [_onlyNotAssigned, _id];
}
