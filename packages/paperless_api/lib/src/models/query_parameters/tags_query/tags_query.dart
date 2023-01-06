import 'package:equatable/equatable.dart';

abstract class TagsQuery extends Equatable {
  const TagsQuery();
  Map<String, String> toQueryParameter();
  Map<String, dynamic> toJson();
}
