import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/delegate/customizable_sliver_persistent_header_delegate.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/widgets/material/colored_tab_bar.dart';
import 'package:paperless_mobile/features/app_drawer/view/app_drawer.dart';
import 'package:paperless_mobile/features/document_search/view/sliver_search_bar.dart';
import 'package:paperless_mobile/features/labels/custom_fields/view/widgets/custom_field_tab_view.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_tab_view.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/connectivity_aware_action_wrapper.dart';
import 'package:paperless_mobile/routing/routes/custom_field_route.dart';
import 'package:paperless_mobile/routing/routes/labels_route.dart';

class LabelsPage extends StatefulWidget {
  const LabelsPage({super.key});

  @override
  State<LabelsPage> createState() => _LabelsPageState();
}

class _LabelsPageState extends State<LabelsPage> with TickerProviderStateMixin {
  final SliverOverlapAbsorberHandle searchBarHandle =
      SliverOverlapAbsorberHandle();
  final SliverOverlapAbsorberHandle tabBarHandle =
      SliverOverlapAbsorberHandle();

  TabController? _tabController;

  int _currentIndex = 0;

  int _calculateTabCount(BuildContext context) => [
    context.uiSettings.canViewCorrespondents,
    context.uiSettings.canViewDocumentTypes,
    context.uiSettings.canViewTags,
    context.uiSettings.canViewStoragePaths,
    context.uiSettings.canViewCustomFields,
  ].fold(0, (value, element) => value + (element ? 1 : 0));

  @override
  void initState() {
    super.initState();
    context.refetchLabels();
  }

  void onTabChangedListener() {
    setState(() => _currentIndex = _tabController!.index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newTabCount = _calculateTabCount(context);
    if (_tabController?.length != newTabCount) {
      _tabController?.removeListener(onTabChangedListener);
      _tabController?.dispose();
      _tabController = TabController(length: newTabCount, vsync: this)
        ..addListener(onTabChangedListener);
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(onTabChangedListener);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fabLabel = [
      if (context.uiSettings$.canViewCorrespondents)
        S.of(context)!.addCorrespondent,
      if (context.uiSettings$.canViewDocumentTypes)
        S.of(context)!.addDocumentType,
      if (context.uiSettings$.canViewTags) S.of(context)!.addTag,
      if (context.uiSettings$.canViewStoragePaths)
        S.of(context)!.addStoragePath,
      if (context.uiSettings$.canViewCustomFields)
        S.of(context)!.addCustomField,
    ][_currentIndex];
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, connectedState) {
        return SafeArea(
          child: Scaffold(
            drawer: const AppDrawer(),
            floatingActionButton: ConnectivityAwareActionWrapper(
              offlineBuilder: (context, child) => const SizedBox.shrink(),
              child: FloatingActionButton.extended(
                heroTag: "labels_page_fab",
                label: Text(fabLabel),
                icon: Icon(Icons.add),
                onPressed: [
                  if (context.uiSettings$.canViewCorrespondents)
                    () =>
                        CreateLabelRoute(LabelType.correspondent).push(context),
                  if (context.uiSettings$.canViewDocumentTypes)
                    () =>
                        CreateLabelRoute(LabelType.documentType).push(context),
                  if (context.uiSettings$.canViewTags)
                    () => CreateLabelRoute(LabelType.tag).push(context),
                  if (context.uiSettings$.canViewStoragePaths)
                    () => CreateLabelRoute(LabelType.storagePath).push(context),
                  if (context.uiSettings$.canViewCustomFields)
                    () => CreateCustomFieldRoute().push(context),
                ][_currentIndex],
              ),
            ),
            body: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverOverlapAbsorber(
                  handle: searchBarHandle,
                  sliver: SliverSearchBar(titleText: S.of(context)!.labels),
                ),
                SliverOverlapAbsorber(
                  handle: tabBarHandle,
                  sliver: SliverPersistentHeader(
                    pinned: true,
                    delegate: CustomizableSliverPersistentHeaderDelegate(
                      child: ColoredTabBar(
                        tabBar: TabBar(
                          controller: _tabController!,
                          tabs: [
                            if (context.uiSettings$.canViewCorrespondents)
                              Tab(
                                icon: Tooltip(
                                  message: S.of(context)!.correspondents,
                                  child: Icon(
                                    Icons.person_outline,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            if (context.uiSettings$.canViewDocumentTypes)
                              Tab(
                                icon: Tooltip(
                                  message: S.of(context)!.documentTypes,
                                  child: Icon(
                                    Icons.description_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            if (context.uiSettings$.canViewTags)
                              Tab(
                                icon: Tooltip(
                                  message: S.of(context)!.tags,
                                  child: Icon(
                                    Icons.label_outline,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            if (context.uiSettings$.canViewStoragePaths)
                              Tab(
                                icon: Tooltip(
                                  message: S.of(context)!.storagePaths,
                                  child: Icon(
                                    Icons.folder_open,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            if (context.uiSettings$.canViewCustomFields)
                              Tab(
                                icon: Tooltip(
                                  message: S.of(context)!.customFields,
                                  child: Icon(
                                    Icons.tune,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      minExtent: kTextTabBarHeight,
                      maxExtent: kTextTabBarHeight,
                    ),
                  ),
                ),
              ],
              body: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  final metrics = notification.metrics;
                  if (metrics.maxScrollExtent == 0) {
                    return true;
                  }
                  final desiredTab =
                      ((metrics.pixels / metrics.maxScrollExtent) *
                              (_tabController!.length - 1))
                          .round();

                  if (metrics.axis == Axis.horizontal &&
                      _currentIndex != desiredTab) {
                    setState(() => _currentIndex = desiredTab);
                  }
                  return true;
                },
                child: RefreshIndicator(
                  edgeOffset: kTextTabBarHeight,
                  notificationPredicate: (notification) =>
                      connectedState.isConnected,
                  onRefresh: () async {
                    try {
                      await [
                        if (context.uiSettings$.canViewCorrespondents)
                          context.correspondentRepository.getAllQuery().refetch,
                        if (context.uiSettings$.canViewDocumentTypes)
                          context.documentTypeRepository.getAllQuery().refetch,
                        if (context.uiSettings$.canViewTags)
                          context.tagRepository.getAllQuery().refetch,
                        if (context.uiSettings$.canViewStoragePaths)
                          context.storagePathRepository.getAllQuery().refetch,
                        if (context.uiSettings$.canViewCustomFields)
                          context.customFieldRepository.getAllQuery().refetch,
                      ][_currentIndex].call();
                    } catch (error, stackTrace) {
                      logger.fe(
                        "An error ocurred while reloading "
                        "${[if (context.uiSettings$.canViewCorrespondents) "correspondents", if (context.uiSettings$.canViewDocumentTypes) "document types", if (context.uiSettings$.canViewTags) "tags", if (context.uiSettings$.canViewStoragePaths) "storage paths", if (context.uiSettings$.canViewCustomFields) "custom fields"][_currentIndex]}.",
                        error: error,
                        stackTrace: stackTrace,
                        className: runtimeType.toString(),
                        methodName: 'onRefresh',
                      );
                    }
                  },
                  child: TabBarView(
                    controller: _tabController!,
                    children: [
                      if (context.uiSettings$.canViewCorrespondents)
                        _buildCorrespondentsView(),
                      if (context.uiSettings$.canViewDocumentTypes)
                        _buildDocumentTypesView(),
                      if (context.uiSettings$.canViewTags) _buildTagsView(),
                      if (context.uiSettings$.canViewStoragePaths)
                        _buildStoragePathView(),
                      if (context.uiSettings$.canViewCustomFields)
                        _buildCustomFieldsView(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCorrespondentsView() {
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(handle: searchBarHandle),
        SliverOverlapInjector(handle: tabBarHandle),
        LabelTabView<Correspondent>(
          query: context.correspondentRepository.getAllQuery(),
          filterBuilder: (label) => DocumentFilter(
            correspondent: IdQueryParameter.include(ids: [label.id]),
          ),
          canView: context.uiSettings$.canViewCorrespondents,
          canEdit: context.uiSettings$.canEditCorrespondents,
          canAddNew: context.uiSettings$.canCreateCorrespondents,
          onEdit: (correspondent) {
            EditLabelRoute(correspondent).push(context);
          },
          emptyStateActionButtonLabel: S.of(context)!.addNewCorrespondent,
          emptyStateDescription: S.of(context)!.noCorrespondentsSetUp,
          onAddNew: () =>
              CreateLabelRoute(LabelType.correspondent).push(context),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildDocumentTypesView() {
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(handle: searchBarHandle),
        SliverOverlapInjector(handle: tabBarHandle),
        LabelTabView<DocumentType>(
          query: context.documentTypeRepository.getAllQuery(),
          filterBuilder: (label) => DocumentFilter(
            documentType: IdQueryParameter.include(ids: [label.id]),
          ),
          canEdit: context.uiSettings$.canEditDocumentTypes,
          canAddNew: context.uiSettings$.canCreateDocumentTypes,
          canView: context.uiSettings$.canViewDocumentTypes,
          onEdit: (label) {
            EditLabelRoute(label).push(context);
          },
          emptyStateActionButtonLabel: S.of(context)!.addNewDocumentType,
          emptyStateDescription: S.of(context)!.noDocumentTypesSetUp,
          onAddNew: () =>
              CreateLabelRoute(LabelType.documentType).push(context),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildTagsView() {
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(handle: searchBarHandle),
        SliverOverlapInjector(handle: tabBarHandle),
        LabelTabView<Tag>(
          query: context.tagRepository.getAllQuery(),
          filterBuilder: (label) =>
              DocumentFilter(tags: IdsTagsQuery(include: [label.id])),
          canEdit: context.uiSettings$.canEditTags,
          canAddNew: context.uiSettings$.canCreateTags,
          canView: context.uiSettings$.canViewTags,
          onEdit: (label) {
            EditLabelRoute(label).push(context);
          },
          leadingBuilder: (t) => CircleAvatar(
            backgroundColor: t.color,
            child: t.isInboxTag ? Icon(Icons.inbox, color: t.textColor) : null,
          ),
          emptyStateActionButtonLabel: S.of(context)!.addNewTag,
          emptyStateDescription: S.of(context)!.noTagsSetUp,
          onAddNew: () => CreateLabelRoute(LabelType.tag).push(context),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildStoragePathView() {
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(handle: searchBarHandle),
        SliverOverlapInjector(handle: tabBarHandle),
        LabelTabView<StoragePath>(
          query: context.storagePathRepository.getAllQuery(),
          onEdit: (label) {
            EditLabelRoute(label).push(context);
          },
          filterBuilder: (label) => DocumentFilter(
            storagePath: IdQueryParameter.include(ids: [label.id]),
          ),
          canEdit: context.uiSettings$.canEditStoragePaths,
          canAddNew: context.uiSettings$.canCreateStoragePaths,
          canView: context.uiSettings$.canViewStoragePaths,
          contentBuilder: (path) => Text(path.path),
          emptyStateActionButtonLabel: S.of(context)!.addNewStoragePath,
          emptyStateDescription: S.of(context)!.noStoragePathsSetUp,
          onAddNew: () => CreateLabelRoute(LabelType.storagePath).push(context),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildCustomFieldsView() {
    if (!context.uiSettings.canViewCustomFields) {
      return SliverToBoxAdapter(
        child: Center(
          child: Text(
            S.of(context)!.unauthorizedErrorMessage,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(handle: searchBarHandle),
        SliverOverlapInjector(handle: tabBarHandle),
        CustomFieldTabView(
          query: context.customFieldRepository.getAllQuery(),
          onEdit: (field) {
            EditCustomFieldRoute(field).push(context);
          },
          canEdit: context.uiSettings$.canEditCustomFields,
          canAddNew: context.uiSettings$.canCreateCustomFields,
          emptyStateActionButtonLabel: S.of(context)!.addNewCustomField,
          emptyStateDescription: S.of(context)!.noCustomFieldsSetUp,
          onAddNew: () => CreateCustomFieldRoute().push(context),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}
