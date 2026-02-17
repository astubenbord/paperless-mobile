import 'dart:async';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/logging/logger.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/paging/cubit/document_paging_bloc_mixin.dart';
import 'package:paperless_mobile/core/paging/cubit/paged_documents_state.dart';

part 'inbox_cubit.g.dart';
part 'inbox_state.dart';

class InboxCubit extends HydratedCubit<InboxState>
    with DocumentPagingBlocMixin {
  final LabelRepository _labelRepository;

  final PaperlessDocumentsApi _documentsApi;

  @override
  final ConnectivityStatusService connectivityStatusService;

  @override
  final DocumentChangedNotifier notifier;

  final PaperlessServerStatsApi _statsApi;

  @override
  PaperlessDocumentsApi get api => _documentsApi;

  InboxCubit(
    this._documentsApi,
    this._statsApi,
    this._labelRepository,
    this.notifier,
    this.connectivityStatusService,
  ) : super(const InboxState()) {
    notifier.addListener(
      this,
      onDeleted: remove,
      onUpdated: (document) {
        final hasInboxTag = document.tags
            .toSet()
            .intersection(state.inboxTags.toSet())
            .isNotEmpty;
        final wasInInboxBeforeUpdate =
            state.documents.map((e) => e.id).contains(document.id);
        if (!hasInboxTag && wasInInboxBeforeUpdate) {
          remove(document);
          emit(state.copyWith(itemsInInboxCount: state.itemsInInboxCount - 1));
        } else if (hasInboxTag) {
          if (wasInInboxBeforeUpdate) {
            replace(document);
          } else {
            _addDocument(document);
            emit(
                state.copyWith(itemsInInboxCount: state.itemsInInboxCount + 1));
          }
        }
      },
    );
  }

  @override
  Future<void> initialize() async {
    await refreshItemsInInboxCount(false);
    await loadInbox();
  }

  Future<void> refreshItemsInInboxCount([bool shouldLoadInbox = true]) async {
    logger.fi(
      "Checking for new documents in inbox...",
      className: runtimeType.toString(),
      methodName: "refreshItemsInInboxCount",
    );
    final stats = await _statsApi.getServerStatistics();

    if (stats.documentsInInbox != state.itemsInInboxCount && shouldLoadInbox) {
      logger.fi(
        "New documents found in inbox, reloading.",
        className: runtimeType.toString(),
        methodName: "refreshItemsInInboxCount",
      );
      await loadInbox();
    } else {
      logger.fi(
        "No new documents found in inbox.",
        className: runtimeType.toString(),
        methodName: "refreshItemsInInboxCount",
      );
    }
    emit(state.copyWith(itemsInInboxCount: stats.documentsInInbox));
  }

  ///
  /// Fetches inbox tag ids and loads the inbox items (documents).
  ///
  Future<void> loadInbox() async {
    if (!isClosed) {
      final inboxTags = await _labelRepository.findAllTags().then(
            (tags) => tags.where((t) => t.isInboxTag).map((t) => t.id!),
          );

      if (inboxTags.isEmpty) {
        // no inbox tags = no inbox items.
        return emit(
          state.copyWith(
            hasLoaded: true,
            value: [],
            inboxTags: [],
          ),
        );
      }
      if (!isClosed) {
        emit(state.copyWith(inboxTags: inboxTags));

        updateFilter(
          filter: DocumentFilter(
            sortField: SortField.added,
            tags: IdsTagsQuery(include: inboxTags.toList()),
          ),
        );
      }
    }
  }

  Future<void> _addDocument(DocumentModel document) async {
    emit(state.copyWith(
      value: [
        ...state.value,
        PagedSearchResult(
          count: 1,
          results: [document],
        ),
      ],
    ));
  }

  ///
  /// Fetches inbox tag ids and loads the inbox items (documents).
  ///
  Future<void> reloadInbox() async {
    final inboxTags = await _labelRepository.findAllTags().then(
          (tags) => tags.where((t) => t.isInboxTag).map((t) => t.id!),
        );

    if (inboxTags.isEmpty) {
      // no inbox tags = no inbox items.
      return emit(
        state.copyWith(
          hasLoaded: true,
          value: [],
          inboxTags: [],
        ),
      );
    }
    emit(state.copyWith(inboxTags: inboxTags));
    updateFilter(
      emitLoading: false,
      filter: DocumentFilter(
        sortField: SortField.added,
        tags: IdsTagsQuery(include: inboxTags.toList()),
      ),
    );
  }

  ///
  /// Updates the document with all inbox tags removed and removes the document
  /// from the inbox.
  ///
  Future<Iterable<int>> removeFromInbox(DocumentModel document) async {
    final tagsToRemove =
        document.tags.toSet().intersection(state.inboxTags.toSet());

    final updatedTags = {...document.tags}..removeAll(tagsToRemove);
    final updatedDocument = await api.update(
      document.copyWith(tags: updatedTags),
    );
    // Remove first so document is not replaced first.
    // remove(document);
    notifier.notifyUpdated(updatedDocument);
    return tagsToRemove;
  }

  ///
  /// Adds the previously removed tags to the document and performs an update.
  ///
  Future<void> undoRemoveFromInbox(
    DocumentModel document,
    Iterable<int> removedTags,
  ) async {
    final updatedDocument = await _documentsApi.update(
      document.copyWith(
        tags: {...document.tags, ...removedTags},
      ),
    );
    notifier.notifyUpdated(updatedDocument);
    emit(state.copyWith(itemsInInboxCount: state.itemsInInboxCount + 1));
    return reload();
  }

  ///
  /// Removes inbox tags from all documents in the inbox.
  ///
  Future<void> clearInbox() async {
    emit(state.copyWith(isLoading: true));
    try {
      await _documentsApi.bulkAction(
        BulkModifyTagsAction.removeTags(
          state.documents.map((e) => e.id),
          state.inboxTags,
        ),
      );
      emit(state.copyWith(
        hasLoaded: true,
        value: [],
        itemsInInboxCount: 0,
      ));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> assignAsn(DocumentModel document) async {
    if (document.archiveSerialNumber == null) {
      final int asn = await _documentsApi.findNextAsn();
      final updatedDocument = await _documentsApi
          .update(document.copyWith(archiveSerialNumber: () => asn));

      replace(updatedDocument);
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

  @override
  Future<void> onFilterUpdated(DocumentFilter filter) async {}
}
