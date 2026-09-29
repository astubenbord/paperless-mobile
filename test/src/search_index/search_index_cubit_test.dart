import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logger/logger.dart';
import 'package:paperless_mobile/api/paperless_api.dart' hide Storage;
import 'package:paperless_mobile/core/store/local_store.dart';
import 'package:paperless_mobile/core/store/slices/local_user_data.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/search_index/cubit/search_index_cubit.dart';
import 'package:paperless_mobile/features/search_index/search_index_channel.dart';

const _userId = 'user@https://paperless.example.com';

class _MemoryStorage implements Storage {
  final _data = <String, dynamic>{};

  @override
  dynamic read(String key) => _data[key];

  @override
  Future<void> write(String key, dynamic value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();

  @override
  Future<void> close() async {}
}

class _FakeDocumentsApi implements PaperlessDocumentsApi {
  final List<PaginatedResultList<Document>> pages;
  Object? error;
  int errorPage = 1;
  void Function(int page)? onRequest;
  final requests = <(DocumentFilter?, bool)>[];

  _FakeDocumentsApi(this.pages);

  @override
  Future<PaginatedResultList<Document>> getAll(
    DocumentFilter? options, {
    bool truncateContent = true,
  }) async {
    requests.add((options, truncateContent));
    onRequest?.call(options!.page);
    if (error != null && options!.page == errorPage) throw error!;
    return pages[options!.page - 1];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeChannel implements SearchIndexChannel {
  int indexed;
  final puts = <List<int>>[];
  final retained = <List<int>>[];
  final calls = <String>[];

  _FakeChannel({this.indexed = 0});

  @override
  Future<void> put(String userId, List<Document> documents) async {
    puts.add(documents.map((d) => d.id).toList());
    indexed += documents.length;
  }

  @override
  Future<void> retainOnly(String userId, List<int> ids) async =>
      retained.add(ids);

  @override
  Future<void> clear(String userId) async {
    calls.add('clear($userId)');
    indexed = 0;
  }

  @override
  Future<int> count(String userId) async => indexed;

  @override
  Future<void> setActiveUser(String? userId) async =>
      calls.add('setActiveUser($userId)');

  @override
  Future<int?> takePendingDocumentId() async => null;

  @override
  void setOpenDocumentHandler(void Function(int documentId) onOpenDocument) {}
}

Document _doc(int id, DateTime? modified) =>
    Document(id: id, title: 'Doc $id', modified: modified);

DateTime _day(int d) => DateTime.utc(2026, 1, d);

LocalStore _store({bool enabled = true, DateTime? lastModified}) =>
    LocalStore('en')..setUserData(
      _userId,
      LocalUserData(
        userId: _userId,
        serverUrl: 'https://paperless.example.com',
        username: 'user',
        searchIndexingEnabled: enabled,
        searchIndexLastModified: lastModified,
      ),
    );

void main() {
  setUpAll(() => logger = Logger(level: Level.off));
  setUp(() => HydratedBloc.storage = _MemoryStorage());

  test('incremental sync stops at the stored lastModified', () async {
    final api = _FakeDocumentsApi([
      PaginatedResultList(
        count: 5,
        next: 'page2',
        all: [1, 2, 3, 4, 5],
        results: [_doc(5, _day(5)), _doc(4, _day(4))],
      ),
      PaginatedResultList(
        count: 5,
        next: 'page3',
        results: [_doc(3, _day(3)), _doc(1, _day(1))],
      ),
    ]);
    final channel = _FakeChannel(indexed: 3);
    final store = _store(lastModified: _day(2));
    final cubit = SearchIndexCubit(api, store, _userId, channel);

    await cubit.sync();

    expect(api.requests.map((r) => r.$1!.page), [1, 2]);
    expect(api.requests.every((r) => r.$2 == false), isTrue);
    expect(api.requests.first.$1!.sortField, SortField.modified);
    expect(api.requests.first.$1!.sortOrder, SortOrder.descending);
    expect(channel.puts, [
      [5, 4],
      [3],
    ]);
    final userData = store.state.localUserData[_userId]!;
    expect(userData.searchIndexLastModified, _day(5));
    expect(userData.searchIndexLastSync, isNotNull);
    expect(cubit.state.syncing, isFalse);
    expect(cubit.state.indexedCount, 6);
    await cubit.close();
  });

  test('retainOnly receives all ids from the first page', () async {
    final api = _FakeDocumentsApi([
      PaginatedResultList(
        count: 2,
        all: [7, 8],
        results: [_doc(8, _day(8)), _doc(7, _day(7))],
      ),
    ]);
    final channel = _FakeChannel();
    final cubit = SearchIndexCubit(api, _store(), _userId, channel);

    await cubit.sync();

    expect(channel.retained, [
      [7, 8],
    ]);
    expect(channel.puts, [
      [8, 7],
    ]);
    await cubit.close();
  });

  test('setEnabled(false) clears the index and the active user', () async {
    final channel = _FakeChannel(indexed: 4);
    final store = _store(lastModified: _day(3));
    final cubit = SearchIndexCubit(
      _FakeDocumentsApi([]),
      store,
      _userId,
      channel,
    );

    await cubit.setEnabled(false);

    expect(channel.calls, ['clear($_userId)', 'setActiveUser(null)']);
    final userData = store.state.localUserData[_userId]!;
    expect(userData.searchIndexingEnabled, isFalse);
    expect(userData.searchIndexLastModified, isNull);
    expect(cubit.state.indexedCount, 0);
    await cubit.close();
  });

  test('empty index ignores stored lastModified and syncs fully', () async {
    final api = _FakeDocumentsApi([
      PaginatedResultList(
        count: 2,
        results: [_doc(3, _day(3)), _doc(2, _day(2))],
      ),
    ]);
    final channel = _FakeChannel();
    final store = _store(lastModified: _day(5));
    final cubit = SearchIndexCubit(api, store, _userId, channel);

    await cubit.sync();

    expect(channel.puts, [
      [3, 2],
    ]);
    expect(
      store.state.localUserData[_userId]!.searchIndexLastModified,
      _day(3),
    );
    await cubit.close();
  });

  test('failure on page 2 does not advance lastModified', () async {
    final api =
        _FakeDocumentsApi([
            PaginatedResultList(
              count: 4,
              next: 'page2',
              results: [_doc(5, _day(5)), _doc(4, _day(4))],
            ),
          ])
          ..error = Exception('boom')
          ..errorPage = 2;
    final channel = _FakeChannel(indexed: 3);
    final store = _store(lastModified: _day(1));
    final cubit = SearchIndexCubit(api, store, _userId, channel);

    await cubit.sync();

    expect(channel.puts, [
      [5, 4],
    ]);
    expect(
      store.state.localUserData[_userId]!.searchIndexLastModified,
      _day(1),
    );
    expect(cubit.state.lastError, contains('boom'));
    await cubit.close();
  });

  test(
    'modified equal to lastModified stops, null modified counts as changed',
    () async {
      final api = _FakeDocumentsApi([
        PaginatedResultList(
          count: 3,
          next: 'page2',
          results: [_doc(5, null), _doc(4, _day(3))],
        ),
      ]);
      final channel = _FakeChannel(indexed: 3);
      final cubit = SearchIndexCubit(
        api,
        _store(lastModified: _day(3)),
        _userId,
        channel,
      );

      await cubit.sync();

      expect(api.requests.map((r) => r.$1!.page), [1]);
      expect(channel.puts, [
        [5],
      ]);
      await cubit.close();
    },
  );

  test('syncIfEnabled when disabled deactivates without API calls', () async {
    final api = _FakeDocumentsApi([]);
    final channel = _FakeChannel();
    final cubit = SearchIndexCubit(
      api,
      _store(enabled: false),
      _userId,
      channel,
    );

    await cubit.syncIfEnabled();

    expect(channel.calls, ['setActiveUser(null)']);
    expect(api.requests, isEmpty);
    await cubit.close();
  });

  test('setEnabled(false) mid-sync stops further puts', () async {
    final api = _FakeDocumentsApi([
      PaginatedResultList(
        count: 2,
        next: 'page2',
        results: [_doc(2, _day(2)), _doc(1, _day(1))],
      ),
    ]);
    final channel = _FakeChannel();
    final store = _store();
    final cubit = SearchIndexCubit(api, store, _userId, channel);
    api.onRequest = (_) => cubit.setEnabled(false);

    await cubit.sync();
    await pumpEventQueue();

    expect(channel.puts, isEmpty);
    expect(store.state.localUserData[_userId]!.searchIndexLastModified, isNull);
    expect(cubit.state.syncing, isFalse);
    await cubit.close();
  });

  test('API error is exposed as lastError without throwing', () async {
    final api = _FakeDocumentsApi([])..error = Exception('boom');
    final cubit = SearchIndexCubit(api, _store(), _userId, _FakeChannel());

    await cubit.sync();

    expect(cubit.state.syncing, isFalse);
    expect(cubit.state.lastError, contains('boom'));
    await cubit.close();
  });
}
