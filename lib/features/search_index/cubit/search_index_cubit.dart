import 'package:bloc/bloc.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/store/local_store.dart';
import 'package:paperless_mobile/core/store/slices/local_user_data.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/search_index/search_index_channel.dart';

class SearchIndexState {
  final bool syncing;
  final int processed;
  final int? total;
  final int? indexedCount;
  final String? lastError;

  const SearchIndexState({
    this.syncing = false,
    this.processed = 0,
    this.total,
    this.indexedCount,
    this.lastError,
  });
}

Future<void> clearSearchIndex(
  SearchIndexChannel channel,
  LocalStore store,
  String userId,
) async {
  await channel.clear(userId);
  if (store.state.localUserData.containsKey(userId)) {
    store.updateUserData(
      userId,
      (s) =>
          s.copyWith(searchIndexLastModified: null, searchIndexLastSync: null),
    );
  }
}

class SearchIndexCubit extends Cubit<SearchIndexState> {
  static const _pageSize = 100;

  final PaperlessDocumentsApi _api;
  final LocalStore _store;
  final String _userId;
  final SearchIndexChannel _channel;

  SearchIndexCubit(this._api, this._store, this._userId, this._channel)
    : super(const SearchIndexState());

  bool get _enabled =>
      _store.state.localUserData[_userId]?.searchIndexingEnabled ?? false;

  bool get _stopped => isClosed || !_enabled;

  Future<void> syncIfEnabled() async {
    if (!_enabled) {
      await _channel.setActiveUser(null);
      return;
    }
    await _channel.setActiveUser(_userId);
    await sync();
  }

  Future<void> sync() async {
    if (state.syncing || _stopped) return;
    emit(SearchIndexState(syncing: true, indexedCount: state.indexedCount));
    try {
      // An empty index (fresh install, cleared on logout) needs a full sync.
      final lastModified = await _channel.count(_userId) == 0
          ? null
          : _store.state.localUserData[_userId]?.searchIndexLastModified;
      DateTime? maxModified = lastModified;
      var processed = 0;
      int? total;
      for (var page = 1; ; page++) {
        final result = await _api.getAll(
          DocumentFilter(
            page: page,
            pageSize: _pageSize,
            fields: const ['id', 'title', 'content', 'modified'],
            sortField: SortField.modified,
            sortOrder: SortOrder.descending,
          ),
          truncateContent: false,
        );
        if (page == 1) {
          total = result.count;
          if (result.all != null) {
            await _channel.retainOnly(_userId, result.all!);
          }
        }
        final changed = lastModified == null
            ? result.results
            : result.results
                  .where((d) => d.modified?.isAfter(lastModified) ?? true)
                  .toList();
        if (changed.isNotEmpty) {
          if (_stopped) return;
          await _channel.put(_userId, changed);
        }
        for (final d in changed) {
          if (d.modified != null &&
              (maxModified == null || d.modified!.isAfter(maxModified))) {
            maxModified = d.modified;
          }
        }
        processed += result.results.length;
        if (_stopped) return;
        emit(
          SearchIndexState(
            syncing: true,
            processed: processed,
            total: total,
            indexedCount: state.indexedCount,
          ),
        );
        if (result.next == null || changed.length < result.results.length) {
          break;
        }
      }
      if (_stopped) return;
      _store.updateUserData(
        _userId,
        (s) => s.copyWith(
          searchIndexLastModified: maxModified,
          searchIndexLastSync: DateTime.now(),
        ),
      );
      final indexedCount = await _channel.count(_userId);
      if (_stopped) return;
      emit(SearchIndexState(indexedCount: indexedCount));
    } catch (error, stackTrace) {
      logger.fe(
        'Search index sync failed.',
        className: runtimeType.toString(),
        methodName: 'sync',
        error: error,
        stackTrace: stackTrace,
      );
      if (_stopped) return;
      emit(
        SearchIndexState(
          indexedCount: state.indexedCount,
          lastError: error.toString(),
        ),
      );
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _store.updateUserData(
      _userId,
      (s) => s.copyWith(searchIndexingEnabled: enabled),
    );
    if (enabled) {
      await _channel.setActiveUser(_userId);
      await sync();
    } else {
      await clearIndex();
      await _channel.setActiveUser(null);
    }
  }

  Future<void> clearIndex() async {
    try {
      await clearSearchIndex(_channel, _store, _userId);
      emit(const SearchIndexState(indexedCount: 0));
    } catch (error, stackTrace) {
      logger.fe(
        'Search index clear failed.',
        className: runtimeType.toString(),
        methodName: 'clearIndex',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        SearchIndexState(
          indexedCount: state.indexedCount,
          lastError: error.toString(),
        ),
      );
    }
  }
}
