import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/tag_repository_state.dart';
import 'package:paperless_mobile/features/inbox/bloc/state/inbox_state.dart';

class InboxCubit extends HydratedCubit<InboxState> {
  final LabelRepository<Tag, TagRepositoryState> _tagsRepository;
  final PaperlessDocumentsApi _documentsApi;

  InboxCubit(this._tagsRepository, this._documentsApi)
      : super(const InboxState());

  ///
  /// Fetches inbox tag ids and loads the inbox items (documents).
  ///
  Future<void> initializeInbox() async {
    if (state.isLoaded) return;
    final inboxTags = await _tagsRepository.findAll().then(
          (tags) => tags.where((t) => t.isInboxTag ?? false).map((t) => t.id!),
        );
    if (inboxTags.isEmpty) {
      // no inbox tags = no inbox items.
      return emit(
        state.copyWith(
          isLoaded: true,
          inboxItems: [],
          inboxTags: [],
        ),
      );
    }
    final inboxDocuments = await _documentsApi
        .findAll(DocumentFilter(
          tags: AnyAssignedTagsQuery(tagIds: inboxTags),
          sortField: SortField.added,
        ))
        .then((psr) => psr.results);
    final newState = state.copyWith(
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
      state.copyWith(
        isLoaded: true,
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
    emit(state.copyWith(
      isLoaded: true,
      inboxItems: [...state.inboxItems, updatedDoc]
        ..sort((d1, d2) => d2.added.compareTo(d1.added)),
    ));
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
    emit(state.copyWith(
      isLoaded: true,
      inboxItems: [],
    ));
  }

  void replaceUpdatedDocument(DocumentModel document) {
    if (document.tags.any((id) => state.inboxTags.contains(id))) {
      // If replaced document still has inbox tag assigned:
      emit(state.copyWith(
        inboxItems:
            state.inboxItems.map((e) => e.id == document.id ? document : e),
      ));
    } else {
      // Remove tag from inbox.
      emit(
        state.copyWith(
            inboxItems:
                state.inboxItems.where((element) => element.id != document.id)),
      );
    }
  }

  void acknowledgeHint() {
    emit(state.copyWith(isHintAcknowledged: true));
  }

  @override
  InboxState fromJson(Map<String, dynamic> json) {
    return InboxState.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(InboxState state) {
    return state.toJson();
  }
}
