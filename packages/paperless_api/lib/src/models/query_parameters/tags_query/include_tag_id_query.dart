import 'package:paperless_api/src/models/query_parameters/tags_query/tag_id_query.dart';

import 'exclude_tag_id_query.dart';

class IncludeTagIdQuery extends TagIdQuery {
  const IncludeTagIdQuery(super.id);

  @override
  String get methodName => 'include';

  @override
  TagIdQuery toggle() {
    return ExcludeTagIdQuery(id);
  }
}
