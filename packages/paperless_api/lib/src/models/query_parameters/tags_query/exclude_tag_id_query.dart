import 'package:paperless_api/src/models/query_parameters/tags_query/tag_id_query.dart';

import 'include_tag_id_query.dart';

class ExcludeTagIdQuery extends TagIdQuery {
  const ExcludeTagIdQuery(super.id);

  @override
  String get methodName => 'exclude';

  @override
  TagIdQuery toggle() {
    return IncludeTagIdQuery(id);
  }
}
