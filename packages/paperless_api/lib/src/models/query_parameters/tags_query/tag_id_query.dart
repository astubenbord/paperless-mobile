import 'package:equatable/equatable.dart';

abstract class TagIdQuery extends Equatable {
  final int id;

  const TagIdQuery(this.id);

  String get methodName;

  @override
  List<Object?> get props => [id, methodName];

  TagIdQuery toggle();
}
