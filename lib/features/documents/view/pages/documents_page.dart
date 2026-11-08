import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:collection/collection.dart';
import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/document_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/store/bloc/current_user_app_state_builder.dart';
import 'package:paperless_mobile/core/store/slices/local_user_app_state.dart';
import 'package:paperless_mobile/features/app_drawer/view/app_drawer.dart';
import 'package:paperless_mobile/features/document_search/view/sliver_search_bar.dart';
import 'package:paperless_mobile/features/documents/view/widgets/adaptive_documents_view.dart';
import 'package:paperless_mobile/features/documents/view/widgets/documents_empty_state.dart';
import 'package:paperless_mobile/features/documents/view/widgets/saved_views/saved_view_changed_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/saved_views/saved_views_widget.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/document_filter_panel.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/confirm_delete_saved_view_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/document_selection_sliver_app_bar.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/view_type_selection_widget.dart';
import 'package:paperless_mobile/features/documents/view/widgets/sort_documents_button.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/tasks/model/pending_tasks_notifier.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';
import 'package:sliver_tools/sliver_tools.dart';

class DocumentFilterIntent {
  final DocumentFilter? filter;
  final bool shouldReset;

  DocumentFilterIntent({this.filter, this.shouldReset = false});
}

class DocumentsPage extends StatefulWidget {
  final DocumentFilter? filter;
  const DocumentsPage({super.key, this.filter});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final SliverOverlapAbsorberHandle searchBarHandle =
      SliverOverlapAbsorberHandle();

  final SliverOverlapAbsorberHandle savedViewsHandle =
      SliverOverlapAbsorberHandle();

  final _nestedScrollViewKey = GlobalKey<NestedScrollViewState>();

  final _savedViewsExpansionController = ExpansibleController();
  bool _showExtendedFab = true;
  final Set<Document> _selection = {};

  @override
  void initState() {
    super.initState();
    context.read<PendingTasksNotifier>().addListener(_onTasksChanged);
    context.documentRepository
        .getAllQuery(filter: context.currentDocumentFilter)
        .refetch();
    context.refetchLabels();
    context.savedViewRepository.getAllQuery().refetch();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nestedScrollViewKey.currentState!.innerController.addListener(
        _scrollExtentChangedListener,
      );
    });
  }

  void _onTasksChanged() {
    final notifier = context.read<PendingTasksNotifier>();
    final tasks = notifier.value;
    final finishedTasks = tasks.values.where(
      (element) => element.status == StatusEnum.success,
    );
    if (finishedTasks.isNotEmpty) {
      showSnackBar(
        context,
        S.of(context)!.newDocumentAvailable,
        action: SnackBarActionConfig(
          label: S.of(context)!.reload,
          onPressed: () {
            // finishedTasks.forEach((task) {
            //   notifier.acknowledgeTasks([finishedTasks]);
            // });
            CachedQuery.instance.refetchQueries(
              keys: [
                context.documentRepository.queryKeyForFilter(
                  context.currentDocumentFilter,
                ),
              ],
            );
          },
        ),
        duration: const Duration(seconds: 10),
      );
    }
  }

  Future<void> _reloadData() async {
    final currentFilter =
        context.loggedInUserData.appState.currentDocumentFilter;
    CachedQuery.instance.refetchQueries(
      keys: [
        if (context.uiSettings.canViewSavedViews)
          context.savedViewRepository.queryKey,
        if (context.uiSettings.canViewCorrespondents)
          context.correspondentRepository.queryKey,
        if (context.uiSettings.canViewTags) context.tagRepository.queryKey,
        if (context.uiSettings.canViewDocumentTypes)
          context.documentTypeRepository.queryKey,
        if (context.uiSettings.canViewStoragePaths)
          context.storagePathRepository.queryKey,
        if (context.uiSettings.canViewCustomFields)
          context.customFieldRepository.queryKey,
        if (context.uiSettings.canViewDocuments)
          context.documentRepository.queryKeyForFilter(currentFilter),
      ],
    );
  }

  void _scrollExtentChangedListener() {
    const threshold = kToolbarHeight * 2;
    final offset =
        _nestedScrollViewKey.currentState!.innerController.position.pixels;
    if (offset < threshold && _showExtendedFab == false) {
      setState(() {
        _showExtendedFab = true;
      });
    } else if (offset >= threshold && _showExtendedFab == true) {
      setState(() {
        _showExtendedFab = false;
      });
    }
  }

  @override
  void dispose() {
    _nestedScrollViewKey.currentState?.innerController.removeListener(
      _scrollExtentChangedListener,
    );
    // context.read<PendingTasksNotifier>().removeListener(_onTasksChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      child: Scaffold(
        drawer: const AppDrawer(),
        floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
        floatingActionButton: _selection.isEmpty
            ? CurrentUserAppDataBuilder(
                builder: (context, userData) {
                  final filter = userData.appState.currentDocumentFilter;
                  return _buildFilterButton(
                    context,
                    filter.appliedFiltersCount > 0 ||
                        filter.selectedView != null,
                  );
                },
              ).animate().fadeIn(duration: 200.milliseconds)
            : null,
        resizeToAvoidBottomInset: true,
        body: PopScope(
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            if (_selection.isNotEmpty) {
              setState(() {
                _selection.clear();
              });
              return;
            }
            if (context.currentDocumentFilter.appliedFiltersCount > 0 ||
                context.currentDocumentFilter.selectedView != null) {
              await _onResetFilter();
              return;
            }
            Navigator.of(context).pop();
          },
          child: NestedScrollView(
            key: _nestedScrollViewKey,
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverOverlapAbsorber(
                handle: searchBarHandle,
                sliver: Builder(
                  builder: (context) {
                    if (_selection.isEmpty) {
                      return SliverSearchBar(
                        titleText: S.of(context)!.documents,
                      );
                    } else {
                      return DocumentSelectionSliverAppBar(
                        selection: _selection,
                        onResetSelection: () => setState(_selection.clear),
                      );
                    }
                  },
                ),
              ),
              SliverOverlapAbsorber(
                handle: savedViewsHandle,
                sliver: SliverPinnedHeader(
                  child: Material(elevation: 2, child: _buildViewActions()),
                ),
              ),
            ],
            body: _buildDocumentsTab(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, bool canResetFilter) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DeferredPointerHandler(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              FloatingActionButton.extended(
                extendedPadding: _showExtendedFab
                    ? null
                    : const EdgeInsets.symmetric(horizontal: 16),
                heroTag: "fab_documents_page_filter",
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.horizontal,
                        child: child,
                      ),
                    );
                  },
                  child: _showExtendedFab
                      ? Row(
                          children: [
                            const Icon(Icons.filter_alt_outlined),
                            const SizedBox(width: 8),
                            Text(S.of(context)!.filterDocuments),
                          ],
                        )
                      : const Icon(Icons.filter_alt_outlined),
                ),
                onPressed: _openDocumentFilter,
              ),
              if (canResetFilter)
                Positioned(
                  top: -20,
                  right: -8,
                  child: DeferPointer(
                    paintOnTop: true,
                    child: Material(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _onResetFilter();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_showExtendedFab)
                              Text(
                                "Reset (${context.currentDocumentFilter$.appliedFiltersCount})", //TODO: INTL
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onError,
                                    ),
                              ).padded()
                            else
                              Icon(
                                Icons.replay,
                                color: Theme.of(context).colorScheme.onError,
                              ).padded(4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsTab(BuildContext context) {
    final localStore = context.localStore;
    final currentFilter =
        context.loggedInUserData$.appState.currentDocumentFilter;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Listen for scroll notifications to load new data.
        // Scroll controller does not work here due to nestedscrollview limitations.
        final offset = notification.metrics.pixels;
        try {
          if (offset > 128 && _savedViewsExpansionController.isExpanded) {
            _savedViewsExpansionController.collapse();
          }
          // Workaround for https://github.com/astubenbord/paperless-mobile/issues/341 probably caused by https://github.com/flutter/flutter/issues/138153
        } on TypeError catch (error) {
          logger.fw(
            "An exception was thrown, but this message can probably be ignored. See issue #341 for more details.",
            error: error,
            className: runtimeType.toString(),
            methodName: "_buildDocumentsTab",
          );
        }

        final max = notification.metrics.maxScrollExtent;
        final query = context.documentRepository.getAllQuery(
          filter: context.currentDocumentFilter,
        );
        final isLastPageLoaded =
            query.state.data?.pages.fold(
              0,
              (value, element) => value + element.results.length,
            ) ==
            (query.state.data?.firstPage?.count ?? 0);

        if (max == 0 || query.state.isLoading || isLastPageLoaded) {
          return false;
        }

        if (offset >= max * 0.7) {
          query.getNextPage().onError<PaperlessApiException>((
            error,
            stackTrace,
          ) {
            if (context.mounted) showErrorMessage(context, error, stackTrace);
            return null;
          });
          return true;
        }
        return false;
      },
      child: RefreshIndicator(
        edgeOffset: kTextTabBarHeight + 2,
        onRefresh: _reloadData,
        child: CustomScrollView(
          key: const PageStorageKey<String>("documents"),
          slivers: <Widget>[
            SliverOverlapInjector(handle: searchBarHandle),
            SliverOverlapInjector(handle: savedViewsHandle),
            SliverToBoxAdapter(
              child: CurrentUserAppDataBuilder(
                builder: (context, userData) {
                  if (!context.uiSettings$.canViewSavedViews) {
                    return const SizedBox.shrink();
                  }
                  return CurrentUserAppDataBuilder(
                    builder: (context, userData) => SavedViewsWidget(
                      controller: _savedViewsExpansionController,
                      onViewSelected: (view) {
                        if (userData
                                .appState
                                .currentDocumentFilter
                                .selectedView ==
                            view.id) {
                          _onResetFilter();
                        } else {
                          localStore.updateLoggedInUserAppState(
                            (appState) => appState.copyWith(
                              currentDocumentFilter: view.toDocumentFilter(),
                            ),
                          );
                        }
                      },
                      onUpdateView: (id, view) async {
                        await context.savedViewRepository
                            .putMutation(id)
                            .mutate(view);
                        if (context.mounted) {
                          showSnackBar(
                            context,
                            S.of(context)!.savedViewSuccessfullyUpdated,
                          );
                        }
                      },
                      onDeleteView: (view) async {
                        HapticFeedback.mediumImpact();
                        final shouldRemove = await showDialog(
                          useRootNavigator: false,
                          context: context,
                          builder: (context) =>
                              ConfirmDeleteSavedViewDialog(view: view),
                        );
                        if (shouldRemove && context.mounted) {
                          await context.savedViewRepository
                              .deleteMutation(view.id)
                              .mutate(null);
                          if (currentFilter.selectedView != null &&
                              currentFilter.selectedView == view.id) {
                            _onResetFilter();
                          }
                        }
                      },
                      filter: userData.appState.currentDocumentFilter,
                    ),
                  );
                },
              ),
            ),
            CurrentUserAppDataBuilder(
              builder: (context, userData) {
                return QueryBuilder(
                  query: context.documentRepository.getAllQuery(
                    filter: userData.appState.currentDocumentFilter,
                  ),
                  builder: (context, state) {
                    if (state.data != null &&
                        (state.data?.firstPage?.count ?? 0) == 0) {
                      return SliverToBoxAdapter(
                        child: DocumentsEmptyState(
                          filter: userData.appState.currentDocumentFilter,
                          onReset: _onResetFilter,
                        ),
                      );
                    }
                    final documents =
                        state.data?.pages.expand((p) => p.results).toList() ??
                        [];
                    final allowToggleFilter = _selection.isEmpty;
                    final viewType = userData.appState.documentsPageViewType;

                    return SliverAdaptiveDocumentsView(
                      viewType: viewType,
                      heroTagPrefix: 'documents_page',
                      onTap: (document) {
                        DocumentDetailsRoute(
                          documentId: document.id,
                          title: document.title,
                          thumbnailUrl: document.buildThumbnailUrl(context),
                          heroTagPrefix: 'documents_page',
                        ).push(context);
                      },
                      onSelected: (document) {
                        if (_selection.contains(document)) {
                          setState(() {
                            _selection.remove(document);
                          });
                        } else {
                          setState(() {
                            _selection.add(document);
                          });
                        }
                      },
                      onTagSelected: allowToggleFilter
                          ? _toggleTagInFilter
                          : null,
                      onCorrespondentSelected: allowToggleFilter
                          ? _addCorrespondentToFilter
                          : null,
                      onDocumentTypeSelected: allowToggleFilter
                          ? _addDocumentTypeToFilter
                          : null,
                      onStoragePathSelected: allowToggleFilter
                          ? _addStoragePathToFilter
                          : null,
                      documents: documents,
                      hasLoaded: state.isSuccess,
                      isLabelClickable: true,
                      isLoading: state.isLoading,
                      selectedDocumentIds: _selection.ids,
                    );
                  },
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  Widget _buildViewActions() {
    return Container(
      padding: const EdgeInsets.all(4),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SortDocumentsButton(enabled: _selection.isEmpty),
          CurrentUserAppDataBuilder(
            builder: (context, userData) {
              final viewType = userData.appState.documentsPageViewType;
              return ViewTypeSelectionWidget(
                viewType: viewType,
                onChanged: (viewType) {
                  context.localStore.updateLoggedInUserAppState(
                    (appState) =>
                        appState.copyWith(documentsPageViewType: viewType),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _openDocumentFilter() async {
    final draggableSheetController = DraggableScrollableController();
    final filterIntent = await showModalBottomSheet<DocumentFilterIntent>(
      useSafeArea: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        controller: draggableSheetController,
        expand: false,
        snap: true,
        snapSizes: const [0.9, 1],
        initialChildSize: .9,
        maxChildSize: 1,
        builder: (context, controller) => DocumentFilterPanel(
          initialFilter: context.currentDocumentFilter,
          scrollController: controller,
          draggableSheetController: draggableSheetController,
        ),
      ),
    );
    if (filterIntent != null) {
      try {
        if (filterIntent.shouldReset) {
          await _onResetFilter();
        } else {
          if (mounted) {
            context.localStore.updateLoggedInUserAppState(
              (appState) => appState.copyWith(
                currentDocumentFilter: filterIntent.filter!,
              ),
            );
          }
        }
      } on PaperlessApiException catch (error, stackTrace) {
        if (mounted) showErrorMessage(context, error, stackTrace);
      }
    }
  }

  void _toggleTagInFilter(int tagId) {
    context.localStore.updateCurrentDocumentFilter(
      (filter) => filter.copyWith(tags: filter.tags.toggleInclude(tagId)),
    );
  }

  void _addCorrespondentToFilter(int? correspondentId) {
    if (correspondentId == null) return;
    context.localStore.updateCurrentDocumentFilter(
      (filter) => filter.copyWith(
        correspondent: filter.correspondent.toggleInclude(correspondentId),
      ),
    );
  }

  void _addDocumentTypeToFilter(int? documentTypeId) {
    if (documentTypeId == null) return;

    context.localStore.updateCurrentDocumentFilter(
      (filter) => filter.copyWith(
        documentType: filter.documentType.toggleInclude(documentTypeId),
      ),
    );
  }

  void _addStoragePathToFilter(int? pathId) {
    if (pathId == null) return;

    context.localStore.updateCurrentDocumentFilter(
      (filter) => filter.copyWith(
        storagePath: filter.storagePath.toggleInclude(pathId),
      ),
    );
  }

  ///
  /// Resets the current filter and scrolls all the way to the top of the view.
  /// If a saved view is currently selected and the filter has changed,
  /// the user will be shown a dialog informing them about the changes.
  /// The user can then decide whether to abort the reset or to continue and discard the changes.
  Future<void> _onResetFilter() async {
    void toTop() async {
      await _nestedScrollViewKey.currentState?.outerController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    final activeView = context.savedViewRepository
        .getAllQuery()
        .state
        .data
        ?.firstWhereOrNull(
          (view) => view.id == context.currentDocumentFilter.selectedView,
        );

    void reset() {
      context.localStore.updateLoggedInUserAppState(
        (data) => data.copyWith(currentDocumentFilter: DocumentFilter()),
      );
    }

    final viewHasChanged =
        activeView != null &&
        activeView.toDocumentFilter() != context.currentDocumentFilter;
    if (viewHasChanged) {
      final discardChanges =
          await showDialog<bool>(
            useRootNavigator: false,
            context: context,
            builder: (context) => const SavedViewChangedDialog(),
          ) ??
          false;
      if (!discardChanges) {
        return;
      }
    }
    reset();
    toTop();
  }
}
