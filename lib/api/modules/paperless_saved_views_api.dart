import 'package:dio/dio.dart';
import 'package:paperless_mobile/api/models/models.dart';
import 'package:paperless_mobile/api/modules/base_crud_api_impl_mixin.dart';
import 'package:paperless_mobile/api/modules/crud_api.dart';
import 'package:paperless_mobile/api/utils/request_utils.dart';
import 'package:paperless_mobile/api/utils/unsafe_to_json.dart';

abstract class PaperlessSavedViewsApi
    extends
        CrudApi<
          SavedView,
          SavedViewRequest,
          PatchedSavedViewRequest,
          GetFilterOptions
        > {}

class PaperlessSavedViewsApiImpl extends PaperlessSavedViewsApi
    with
        BaseCrudApiImplMixin<
          SavedView,
          SavedViewRequest,
          PatchedSavedViewRequest,
          GetFilterOptions
        > {
  @override
  final Dio client;

  PaperlessSavedViewsApiImpl(this.client);

  @override
  String get path => "/api/saved_views";

  @override
  GetFilterOptions defaultFilterOptions = const GetFilterOptions();

  @override
  SavedView parse(Map<String, dynamic> json) => SavedView.fromJson(json);

  @override
  Future<List<SavedView>> getAll([GetFilterOptions? options]) async {
    final views = await getCollection(
      '$path/',
      parse,
      listErrorCode,
      client: client,
      queryParams: removeNullValues(
        unsafeToJson(options ?? defaultFilterOptions),
      ),
    );

    try {
      final response = await client.get('/api/ui_settings/');
      final uiSettings = UiSettingsView.fromJson(response.data!);

      final savedViewSettings = uiSettings.settings?.savedViews;

      final dashboardIds =
          savedViewSettings?.dashboardViewsVisibleIds ?? const <int>[];

      final sidebarIds =
          savedViewSettings?.sidebarViewsVisibleIds ?? const <int>[];

      final mergedViews = views
          .map(
            (view) => view.copyWith(
              showOnDashboard: dashboardIds.contains(view.id),
              showInSidebar: sidebarIds.contains(view.id),
            ),
          )
          .toList();

      return mergedViews;
    } catch (_) {
      return views;
    }
  }

  @override
  ErrorCode get createErrorCode => ErrorCode.createSavedViewError;

  @override
  ErrorCode get deleteErrorCode => ErrorCode.deleteSavedViewError;

  @override
  ErrorCode get getErrorCode => ErrorCode.loadSavedViewsError;

  @override
  ErrorCode get listErrorCode => ErrorCode.loadSavedViewsError;

  @override
  ErrorCode get patchErrorCode => ErrorCode.updateSavedViewError;

  @override
  ErrorCode get putErrorCode => ErrorCode.updateSavedViewError;
}
