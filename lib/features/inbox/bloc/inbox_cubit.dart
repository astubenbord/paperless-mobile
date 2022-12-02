import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/inbox/bloc/state/inbox_state.dart';

@injectable
class InboxCubit extends Cubit<InboxState> {
  final PaperlessLabelsApi _labelApi;
  final PaperlessDocumentsApi _documentsApi;

  InboxCubit(this._labelApi, this._documentsApi) : super(const InboxState());

  ///
  /// Fetches inbox tag ids and loads the inbox items (documents).
  ///
  Future<void> loadInbox() async {
    final inboxTags = await _labelApi.getTags().then(
          (tags) => tags.where((t) => t.isInboxTag ?? false).map((t) => t.id!),
        );
    if (inboxTags.isEmpty) {
      // no inbox tags = no inbox items.
      return emit(const InboxState(
        isLoaded: true,
        inboxItems: [],
        inboxTags: [],
      ));
    }
    final inboxDocuments = await _documentsApi
        .find(DocumentFilter(
          tags: AnyAssignedTagsQuery(tagIds: inboxTags),
          sortField: SortField.added,
        ))
        .then((psr) => psr.results);
    final newState = InboxState(
      isLoaded: true,
      inboxItems: inboxDocuments,
      inboxTags: inboxTags,
    );
    emit(newState);
  }

  ///
  /// Updates the document with all inbox tags removed and removes the document
  /// from the currently loaded inbox documents.
  ///
  Future<Iterable<int>> remove(DocumentModel document) async {
    final tagsToRemove =
        document.tags.toSet().intersection(state.inboxTags.toSet());

    final updatedTags = {...document.tags}..removeAll(tagsToRemove);

    await _documentsApi.update(
      document.copyWith(
        tags: updatedTags,
        overwriteTags: true,
      ),
    );
    emit(
      InboxState(
        isLoaded: true,
        inboxTags: state.inboxTags,
        inboxItems: state.inboxItems.where((doc) => doc.id != document.id),
      ),
    );

    return tagsToRemove;
  }

  ///
  /// Adds the previously removed tags to the document and performs an update.
  ///
  Future<void> undoRemove(
    DocumentModel document,
    Iterable<int> removedTags,
  ) async {
    final updatedDoc = document.copyWith(
      tags: {...document.tags, ...removedTags},
      overwriteTags: true,
    );
    await _documentsApi.update(updatedDoc);
    emit(
      InboxState(
        isLoaded: true,
        inboxItems: [...state.inboxItems, updatedDoc]
          ..sort((d1, d2) => d2.added.compareTo(d1.added)),
        inboxTags: state.inboxTags,
      ),
    );
  }

  ///
  /// Removes inbox tags from all documents in the inbox.
  ///
  Future<void> clearInbox() async {
    await _documentsApi.bulkAction(
      BulkModifyTagsAction.removeTags(
        state.inboxItems.map((e) => e.id),
        state.inboxTags,
      ),
    );
    emit(
      InboxState(
        isLoaded: true,
        inboxTags: state.inboxTags,
        inboxItems: [],
      ),
    );
  }
}
