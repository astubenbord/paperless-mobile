import 'package:dio/dio.dart';
import 'package:paperless_mobile/api/models/models.dart';
import 'package:paperless_mobile/api/modules/base_crud_api_impl_mixin.dart';
import 'package:paperless_mobile/api/modules/crud_api.dart';

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

  @override
  Future<List<SavedView>> getAll([GetFilterOptions? options]) async {
    final views = await super.getAll(options);
    final visibility = await _readVisibility();
    return views.map((view) => _applyVisibility(view, visibility)).toList();
  }

  @override
  Future<SavedView?> get(int id) async {
    final view = await super.get(id);
    if (view == null) return null;
    return _applyVisibility(view, await _readVisibility());
  }

  @override
  Future<SavedView> create(SavedViewRequest item) async {
    final view = await super.create(item);
    final visibility = await _updateVisibility(
      view.id,
      showOnDashboard: item.showOnDashboard,
      showInSidebar: item.showInSidebar,
    );
    return _applyVisibility(view, visibility);
  }

  @override
  Future<SavedView> put(int id, SavedViewRequest item) async {
    final view = await super.put(id, item);
    final visibility = await _updateVisibility(
      view.id,
      showOnDashboard: item.showOnDashboard,
      showInSidebar: item.showInSidebar,
    );
    return _applyVisibility(view, visibility);
  }

  @override
  Future<SavedView> patch(int id, PatchedSavedViewRequest item) async {
    final view = await super.patch(id, item);
    final visibility = await _updateVisibility(
      view.id,
      showOnDashboard: item.showOnDashboard?.value,
      showInSidebar: item.showInSidebar?.value,
    );
    return _applyVisibility(view, visibility);
  }

  @override
  Future<int> delete(int id) async {
    final deletedId = await super.delete(id);
    await _updateVisibility(id, remove: true);
    return deletedId;
  }

  SavedView _applyVisibility(SavedView view, _SavedViewVisibility visibility) {
    if (!visibility.isV10) return view;
    return view.copyWith(
      showOnDashboard:
          visibility.dashboardIds?.contains(view.id) ?? view.showOnDashboard,
      showInSidebar:
          visibility.sidebarIds?.contains(view.id) ?? view.showInSidebar,
    );
  }

  Future<_SavedViewVisibility> _readVisibility() async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/ui_settings/',
    );
    if (response.data?.containsKey('user') ?? false) {
      return const _SavedViewVisibility(isV10: false);
    }
    final settings = response.data?['settings'];
    if (settings is! Map) return const _SavedViewVisibility();
    final savedViews = settings['saved_views'];
    if (savedViews is! Map) return const _SavedViewVisibility();

    return _SavedViewVisibility(
      dashboardIds: _parseIds(savedViews['dashboard_views_visible_ids']),
      sidebarIds: _parseIds(savedViews['sidebar_views_visible_ids']),
    );
  }

  Future<_SavedViewVisibility> _updateVisibility(
    int id, {
    bool? showOnDashboard,
    bool? showInSidebar,
    bool remove = false,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/ui_settings/',
    );
    if (response.data?.containsKey('user') ?? false) {
      return const _SavedViewVisibility(isV10: false);
    }
    final currentSettings = _copyMap(response.data?['settings']);
    final savedViews = _copyMap(currentSettings['saved_views']);
    final dashboardIds = _parseIds(savedViews['dashboard_views_visible_ids']);
    final sidebarIds = _parseIds(savedViews['sidebar_views_visible_ids']);
    var changed = false;

    if (showOnDashboard != null) {
      changed = _setVisibility(dashboardIds, id, showOnDashboard) || changed;
      savedViews['dashboard_views_visible_ids'] = dashboardIds.toList()..sort();
    }
    if (showInSidebar != null) {
      changed = _setVisibility(sidebarIds, id, showInSidebar) || changed;
      savedViews['sidebar_views_visible_ids'] = sidebarIds.toList()..sort();
    }
    if (remove) {
      changed = dashboardIds.remove(id) || changed;
      changed = sidebarIds.remove(id) || changed;
      if (savedViews.containsKey('dashboard_views_visible_ids')) {
        savedViews['dashboard_views_visible_ids'] = dashboardIds.toList()
          ..sort();
      }
      if (savedViews.containsKey('sidebar_views_visible_ids')) {
        savedViews['sidebar_views_visible_ids'] = sidebarIds.toList()..sort();
      }
    }

    if (changed) {
      currentSettings['saved_views'] = savedViews;
      await client.post(
        '/api/ui_settings/',
        data: {'settings': currentSettings},
      );
    }

    return _SavedViewVisibility(
      isV10: true,
      dashboardIds: savedViews.containsKey('dashboard_views_visible_ids')
          ? dashboardIds
          : null,
      sidebarIds: savedViews.containsKey('sidebar_views_visible_ids')
          ? sidebarIds
          : null,
    );
  }

  static bool _setVisibility(Set<int> ids, int id, bool visible) {
    return visible ? ids.add(id) : ids.remove(id);
  }

  static Set<int> _parseIds(dynamic value) {
    if (value is! List) return {};
    return value.map((id) => int.tryParse('$id')).whereType<int>().toSet();
  }

  static Map<String, dynamic> _copyMap(dynamic value) {
    if (value is! Map) return {};
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
}

class _SavedViewVisibility {
  final bool isV10;
  final Set<int>? dashboardIds;
  final Set<int>? sidebarIds;

  const _SavedViewVisibility({
    this.isV10 = true,
    this.dashboardIds,
    this.sidebarIds,
  });
}
