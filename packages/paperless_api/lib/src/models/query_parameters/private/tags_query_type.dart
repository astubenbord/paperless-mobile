import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum TagsQueryType {
  notAssigned,
  anyAssigned,
  ids,
  id,
  include,
  exclude;
}
