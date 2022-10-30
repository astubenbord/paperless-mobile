import 'package:flutter_paperless_mobile/features/documents/model/query_parameters/ids_query_parameter.dart';

class TagsQuery extends IdsQueryParameter {
  const TagsQuery.fromIds(super.ids) : super.fromIds();
  const TagsQuery.unset() : super.unset();
  const TagsQuery.notAssigned() : super.notAssigned();

  @override
  String toQueryParameter() {
    if (onlyNotAssigned) {
      return '&is_tagged=false';
    }
    return isUnset ? "" : '&tags__id__all=${ids.join(',')}';
  }
}
