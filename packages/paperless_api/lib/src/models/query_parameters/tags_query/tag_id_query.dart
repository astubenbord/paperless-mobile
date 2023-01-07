import 'package:equatable/equatable.dart';
import 'package:paperless_api/paperless_api.dart';

abstract class TagIdQuery extends Equatable {
  final int id;

  const TagIdQuery(this.id);

  String get methodName;

  @override
  List<Object?> get props => [id, methodName];

  TagIdQuery toggle();

  Map<String, dynamic> toJson() {
    return {
      'type': methodName,
      'id': id,
    };
  }

  factory TagIdQuery.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    var id = json['id'];
    switch (type) {
      case 'include':
        return IncludeTagIdQuery(id);
      case 'exclude':
        return ExcludeTagIdQuery(id);
      default:
        throw Exception('Error parsing TagIdQuery: Unknown type $type');
    }
  }
}
