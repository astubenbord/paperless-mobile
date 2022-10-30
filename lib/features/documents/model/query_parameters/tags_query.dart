import 'package:equatable/equatable.dart';

class TagsQuery with EquatableMixin {
  final List<int> _ids;
  final bool? _isTagged;

  const TagsQuery.fromIds(List<int> ids)
      : _isTagged = null,
        _ids = ids;

  const TagsQuery.anyAssigned()
      : _isTagged = true,
        _ids = const [];

  const TagsQuery.notAssigned()
      : _isTagged = false,
        _ids = const [];

  const TagsQuery.unset() : this.fromIds(const []);

  bool get onlyNotAssigned => _isTagged == false;
  bool get onlyAssigned => _isTagged == true;

  bool get isUnset => _ids.isEmpty && _isTagged == null;
  bool get isSet => _ids.isNotEmpty && _isTagged == null;

  List<int> get ids => _ids;

  String toQueryParameter() {
    if (onlyNotAssigned || onlyAssigned) {
      return '&is_tagged=$_isTagged';
    }
    return isUnset ? "" : '&tags__id__all=${ids.join(',')}';
  }

  @override
  List<Object?> get props => [_isTagged, _ids];
}
