abstract class BulkAction {
  final Iterable<int> documentIds;

  BulkAction(this.documentIds);

  Map<String, dynamic> toJson();
}

class BulkDeleteAction extends BulkAction {
  BulkDeleteAction(super.documents);

  @override
  Map<String, dynamic> toJson() {
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
  Map<String, dynamic> toJson() {
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
