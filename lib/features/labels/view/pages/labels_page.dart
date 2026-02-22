import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/hive/hive_extensions.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/widgets/customizable_sliver_persistent_header_delegate.dart';
import 'package:paperless_mobile/core/logging/logger.dart';
import 'package:paperless_mobile/core/widgets/material/colored_tab_bar.dart';
import 'package:paperless_mobile/features/app_drawer/view/app_drawer.dart';
import 'package:paperless_mobile/features/document_search/view/sliver_search_bar.dart';
import 'package:paperless_mobile/features/labels/cubit/label_cubit.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_tab_view.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/core/widgets/connectivity_aware_action_wrapper.dart';
import 'package:paperless_mobile/routing/routes/labels_route.dart';

class LabelsPage extends StatefulWidget {
  const LabelsPage({super.key});

  @override
  State<LabelsPage> createState() => _LabelsPageState();
}

class _LabelsPageState extends State<LabelsPage>
    with SingleTickerProviderStateMixin {
  final SliverOverlapAbsorberHandle searchBarHandle =
      SliverOverlapAbsorberHandle();
  final SliverOverlapAbsorberHandle tabBarHandle =
      SliverOverlapAbsorberHandle();

  late final TabController _tabController;

  int _currentIndex = 0;

  int _calculateTabCount(UserModel user) => [
        user.canViewCorrespondents,
        user.canViewDocumentTypes,
        user.canViewTags,
        user.canViewStoragePaths,
      ].fold(0, (value, element) => value + (element ? 1 : 0));

  @override
  void initState() {
    super.initState();
    final user = context.read<LocalUserAccount>().paperlessUser;
    _tabController = TabController(
        length: _calculateTabCount(user), vsync: this)
      ..addListener(() => setState(() => _currentIndex = _tabController.index));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable:
            Hive.box<LocalUserAccount>(HiveBoxes.localUserAccount).listenable(),
        builder: (context, box, child) {
          final currentUserId = Hive.globalSettings.loggedInUserId;
          final user = box.get(currentUserId)!.paperlessUser;
          final fabLabel = [
            S.of(context)!.addCorrespondent,
            S.of(context)!.addDocumentType,
            S.of(context)!.addTag,
            S.of(context)!.addStoragePath,
          ][_currentIndex];
          return BlocBuilder<ConnectivityCubit, ConnectivityState>(
            builder: (context, connectedState) {
              return SafeArea(
                child: Scaffold(
                  drawer: const AppDrawer(),
                  floatingActionButton: ConnectivityAwareActionWrapper(
                    offlineBuilder: (context, child) => const SizedBox.shrink(),
                    child: FloatingActionButton.extended(
                      heroTag: "inbox_page_fab",
                      label: Text(fabLabel),
                      icon: Icon(Icons.add),
                      onPressed: [
                        if (user.canViewCorrespondents)
                          () => CreateLabelRoute(LabelType.correspondent)
                              .push(context),
                        if (user.canViewDocumentTypes)
                          () => CreateLabelRoute(LabelType.documentType)
                              .push(context),
                        if (user.canViewTags)
                          () => CreateLabelRoute(LabelType.tag).push(context),
                        if (user.canViewStoragePaths)
                          () => CreateLabelRoute(LabelType.storagePath)
                              .push(context),
                      ][_currentIndex],
                    ),
                  ),
                  body: NestedScrollView(
                    floatHeaderSlivers: true,
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverOverlapAbsorber(
                        handle: searchBarHandle,
                        sliver: SliverSearchBar(
                          titleText: S.of(context)!.labels,
                        ),
                      ),
                      SliverOverlapAbsorber(
                        handle: tabBarHandle,
                        sliver: SliverPersistentHeader(
                          pinned: true,
                          delegate: CustomizableSliverPersistentHeaderDelegate(
                            child: ColoredTabBar(
                              tabBar: TabBar(
                                controller: _tabController,
                                tabs: [
                                  if (user.canViewCorrespondents)
                                    Tab(
                                      icon: Tooltip(
                                        message: S.of(context)!.correspondents,
                                        child: Icon(
                                          Icons.person_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  if (user.canViewDocumentTypes)
                                    Tab(
                                      icon: Tooltip(
                                        message: S.of(context)!.documentTypes,
                                        child: Icon(
                                          Icons.description_outlined,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  if (user.canViewTags)
                                    Tab(
                                      icon: Tooltip(
                                        message: S.of(context)!.tags,
                                        child: Icon(
                                          Icons.label_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  if (user.canViewStoragePaths)
                                    Tab(
                                      icon: Tooltip(
                                        message: S.of(context)!.storagePaths,
                                        child: Icon(
                                          Icons.folder_open,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
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
                    body: BlocBuilder<LabelCubit, LabelState>(
                      builder: (context, state) {
                        return NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            final metrics = notification.metrics;
                            if (metrics.maxScrollExtent == 0) {
                              return true;
                            }
                            final desiredTab =
                                ((metrics.pixels / metrics.maxScrollExtent) *
                                        (_tabController.length - 1))
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
                                  context
                                      .read<LabelCubit>()
                                      .reloadCorrespondents,
                                  context
                                      .read<LabelCubit>()
                                      .reloadDocumentTypes,
                                  context.read<LabelCubit>().reloadTags,
                                  context.read<LabelCubit>().reloadStoragePaths,
                                ][_currentIndex]
                                    .call();
                              } catch (error, stackTrace) {
                                logger.fe(
                                    "An error ocurred while reloading "
                                    "${[
                                      "correspondents",
                                      "document types",
                                      "tags",
                                      "storage paths"
                                    ][_currentIndex]}.",
                                    error: error,
                                    stackTrace: stackTrace,
                                    className: runtimeType.toString(),
                                    methodName: 'onRefresh');
                              }
                            },
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                if (user.canViewCorrespondents)
                                  _buildCorrespondentsView(state, user),
                                if (user.canViewDocumentTypes)
                                  _buildDocumentTypesView(state, user),
                                if (user.canViewTags)
                                  _buildTagsView(state, user),
                                if (user.canViewStoragePaths)
                                  _buildStoragePathView(state, user),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        });
  }

  Widget _buildCorrespondentsView(LabelState state, UserModel user) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(handle: searchBarHandle),
            SliverOverlapInjector(handle: tabBarHandle),
            LabelTabView<Correspondent>(
              labels: state.correspondents,
              filterBuilder: (label) => DocumentFilter(
                correspondent: SetIdQueryParameter(id: label.id!),
              ),
              canEdit: user.canEditCorrespondents,
              canAddNew: user.canCreateCorrespondents,
              onEdit: (correspondent) {
                EditLabelRoute(correspondent).push(context);
              },
              emptyStateActionButtonLabel: S.of(context)!.addNewCorrespondent,
              emptyStateDescription: S.of(context)!.noCorrespondentsSetUp,
              onAddNew: () =>
                  CreateLabelRoute(LabelType.correspondent).push(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDocumentTypesView(LabelState state, UserModel user) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(handle: searchBarHandle),
            SliverOverlapInjector(handle: tabBarHandle),
            LabelTabView<DocumentType>(
              labels: state.documentTypes,
              filterBuilder: (label) => DocumentFilter(
                documentType: SetIdQueryParameter(id: label.id!),
              ),
              canEdit: user.canEditDocumentTypes,
              canAddNew: user.canCreateDocumentTypes,
              onEdit: (label) {
                EditLabelRoute(label).push(context);
              },
              emptyStateActionButtonLabel: S.of(context)!.addNewDocumentType,
              emptyStateDescription: S.of(context)!.noDocumentTypesSetUp,
              onAddNew: () =>
                  CreateLabelRoute(LabelType.documentType).push(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTagsView(LabelState state, UserModel user) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(handle: searchBarHandle),
            SliverOverlapInjector(handle: tabBarHandle),
            LabelTabView<Tag>(
              labels: state.tags,
              filterBuilder: (label) => DocumentFilter(
                tags: IdsTagsQuery(include: [label.id!]),
              ),
              canEdit: user.canEditTags,
              canAddNew: user.canCreateTags,
              onEdit: (label) {
                EditLabelRoute(label).push(context);
              },
              leadingBuilder: (t) => CircleAvatar(
                backgroundColor: t.color,
                child: t.isInboxTag
                    ? Icon(
                        Icons.inbox,
                        color: t.textColor,
                      )
                    : null,
              ),
              emptyStateActionButtonLabel: S.of(context)!.addNewTag,
              emptyStateDescription: S.of(context)!.noTagsSetUp,
              onAddNew: () => CreateLabelRoute(LabelType.tag).push(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStoragePathView(LabelState state, UserModel user) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(handle: searchBarHandle),
            SliverOverlapInjector(handle: tabBarHandle),
            LabelTabView<StoragePath>(
              labels: state.storagePaths,
              onEdit: (label) {
                EditLabelRoute(label).push(context);
              },
              filterBuilder: (label) => DocumentFilter(
                storagePath: SetIdQueryParameter(id: label.id!),
              ),
              canEdit: user.canEditStoragePaths,
              canAddNew: user.canCreateStoragePaths,
              contentBuilder: (path) => Text(path.path),
              emptyStateActionButtonLabel: S.of(context)!.addNewStoragePath,
              emptyStateDescription: S.of(context)!.noStoragePathsSetUp,
              onAddNew: () =>
                  CreateLabelRoute(LabelType.storagePath).push(context),
            ),
          ],
        );
      },
    );
  }
}
