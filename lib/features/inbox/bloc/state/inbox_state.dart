import 'package:equatable/equatable.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';

class InboxState with EquatableMixin {
  final bool isLoaded;
  final Iterable<int> inboxTags;
  final Iterable<DocumentModel> inboxItems;

  const InboxState({
    this.isLoaded = false,
    this.inboxTags = const [],
    this.inboxItems = const [],
  });

  @override
  List<Object?> get props => [isLoaded, inboxTags, inboxItems];
}
