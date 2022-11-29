import 'package:paperless_mobile/core/type/types.dart';

abstract class BulkAction {
  final Iterable<int> documentIds;

  BulkAction(this.documentIds);

  JSON toJson();
}

class BulkDeleteAction extends BulkAction {
  BulkDeleteAction(super.documents);

  @override
  JSON toJson() {
    return {
      'documents': documentIds.toList(),
      'method': 'delete',
      'parameters': {},
    };
  }
}

class BulkModifyTagsAction extends BulkAction {
  final Iterable<int> removeTags;
  final Iterable<int> addTags;

  BulkModifyTagsAction(
    super.documents, {
    this.removeTags = const [],
    this.addTags = const [],
  });

  BulkModifyTagsAction.addTags(super.documents, this.addTags)
      : removeTags = const [];

  BulkModifyTagsAction.removeTags(super.documents, Iterable<int> tags)
      : addTags = const [],
        removeTags = tags;

  @override
  JSON toJson() {
    return {
      'documents': documentIds.toList(),
      'method': 'modify_tags',
      'parameters': {
        'add_tags': addTags.toList(),
        'remove_tags': removeTags.toList(),
      }
    };
  }
}
