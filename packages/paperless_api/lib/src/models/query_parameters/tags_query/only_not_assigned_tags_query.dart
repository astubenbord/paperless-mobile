import 'tags_query.dart';

class OnlyNotAssignedTagsQuery extends TagsQuery {
  const OnlyNotAssignedTagsQuery();
  @override
  Map<String, String> toQueryParameter() {
    return {'is_tagged': '0'};
  }

  @override
  List<Object?> get props => [];

  @override
  Map<String, dynamic> toJson() {
    return {};
  }
}
