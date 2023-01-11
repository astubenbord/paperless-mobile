import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inbox_state.g.dart';

@JsonSerializable()
class InboxState with EquatableMixin {
  @JsonKey(ignore: true)
  final bool isLoaded;

  @JsonKey(ignore: true)
  final Iterable<int> inboxTags;

  @JsonKey(ignore: true)
  final Iterable<DocumentModel> inboxItems;

  final bool isHintAcknowledged;

  const InboxState({
    this.isLoaded = false,
    this.inboxTags = const [],
    this.inboxItems = const [],
    this.isHintAcknowledged = false,
  });

  @override
  List<Object?> get props => [
        isLoaded,
        inboxTags,
        inboxItems,
        isHintAcknowledged,
      ];

  InboxState copyWith({
    bool? isLoaded,
    Iterable<int>? inboxTags,
    Iterable<DocumentModel>? inboxItems,
    bool? isHintAcknowledged,
  }) {
    return InboxState(
      isLoaded: isLoaded ?? this.isLoaded,
      inboxItems: inboxItems ?? this.inboxItems,
      inboxTags: inboxTags ?? this.inboxTags,
      isHintAcknowledged: isHintAcknowledged ?? this.isHintAcknowledged,
    );
  }

  factory InboxState.fromJson(Map<String, dynamic> json) =>
      _$InboxStateFromJson(json);

  Map<String, dynamic> toJson() => _$InboxStateToJson(this);
}
