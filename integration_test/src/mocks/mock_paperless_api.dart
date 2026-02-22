import 'package:dio/src/dio.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/factory/paperless_api_factory.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([
  MockSpec<PaperlessAuthenticationApi>(),
  MockSpec<PaperlessDocumentsApi>(),
  MockSpec<PaperlessLabelsApi>(),
  MockSpec<PaperlessUserApi>(),
  MockSpec<PaperlessServerStatsApi>(),
  MockSpec<PaperlessSavedViewsApi>(),
  MockSpec<PaperlessTasksApi>(),
  MockSpec<CustomFieldsApi>(),
  MockSpec<PaperlessShareLinksApi>(),
  MockSpec<PaperlessTrashApi>(),
])
import 'mock_paperless_api.mocks.dart';

class MockPaperlessApiFactory implements PaperlessApiFactory {
  final PaperlessAuthenticationApi authenticationApi =
      MockPaperlessAuthenticationApi();
  final PaperlessDocumentsApi documentApi = MockPaperlessDocumentsApi();
  final PaperlessLabelsApi labelsApi = MockPaperlessLabelsApi();
  final PaperlessUserApi userApi = MockPaperlessUserApi();
  final PaperlessSavedViewsApi savedViewsApi = MockPaperlessSavedViewsApi();
  final PaperlessServerStatsApi serverStatsApi = MockPaperlessServerStatsApi();
  final PaperlessTasksApi tasksApi = MockPaperlessTasksApi();
  final CustomFieldsApi customFieldsApi = MockCustomFieldsApi();
  final PaperlessShareLinksApi shareLinksApi = MockPaperlessShareLinksApi();
  final PaperlessTrashApi trashApi = MockPaperlessTrashApi();

  @override
  PaperlessAuthenticationApi createAuthenticationApi(Dio dio) {
    return authenticationApi;
  }

  @override
  PaperlessDocumentsApi createDocumentsApi(Dio dio, {required int apiVersion}) {
    return documentApi;
  }

  @override
  PaperlessLabelsApi createLabelsApi(Dio dio, {required int apiVersion}) {
    return labelsApi;
  }

  @override
  PaperlessSavedViewsApi createSavedViewsApi(
    Dio dio, {
    required int apiVersion,
  }) {
    return savedViewsApi;
  }

  @override
  PaperlessServerStatsApi createServerStatsApi(Dio dio,
      {required int apiVersion}) {
    return serverStatsApi;
  }

  @override
  PaperlessTasksApi createTasksApi(Dio dio, {required int apiVersion}) {
    return tasksApi;
  }

  @override
  PaperlessUserApi createUserApi(Dio dio, {required int apiVersion}) {
    return userApi;
  }

  @override
  CustomFieldsApi createCustomFieldsApi(Dio dio) {
    return customFieldsApi;
  }

  @override
  PaperlessShareLinksApi createShareLinksApi(Dio dio) {
    return shareLinksApi;
  }

  @override
  PaperlessTrashApi createTrashApi(Dio dio) {
    return trashApi;
  }
}
