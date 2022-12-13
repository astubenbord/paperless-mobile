import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/repository/provider/label_repositories_provider.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/document_details/bloc/document_details_cubit.dart';
import 'package:paperless_mobile/features/document_details/view/pages/document_details_page.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/view/widgets/documents_empty_state.dart';
import 'package:paperless_mobile/features/documents/view/widgets/grid/document_grid.dart';
import 'package:paperless_mobile/features/documents/view/widgets/list/document_list.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/document_filter_panel.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/documents_page_app_bar.dart';
import 'package:paperless_mobile/features/documents/view/widgets/sort_documents_button.dart';
import 'package:paperless_mobile/features/home/view/widget/info_drawer.dart';
import 'package:paperless_mobile/features/labels/bloc/providers/labels_bloc_provider.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_state.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';
import 'package:paperless_mobile/features/settings/model/view_type.dart';
import 'package:paperless_mobile/util.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({Key? key}) : super(key: key);

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  late final DocumentsCubit _documentsCubit;
  late final SavedViewCubit _savedViewCubit;

  final _pagingController = PagingController<int, DocumentModel>(
    firstPageKey: 1,
  );

  @override
  void initState() {
    super.initState();
    _documentsCubit = BlocProvider.of<DocumentsCubit>(context);
    _savedViewCubit = BlocProvider.of<SavedViewCubit>(context);
    try {
      _documentsCubit.load();
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
    _pagingController.addPageRequestListener(_loadNewPage);
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConnectivityCubit, ConnectivityState>(
      listenWhen: (previous, current) =>
          previous != ConnectivityState.connected &&
          current == ConnectivityState.connected,
      listener: (context, state) {
        _documentsCubit.load();
      },
      builder: (context, connectivityState) {
        return Scaffold(
            drawer: BlocProvider.value(
              value: BlocProvider.of<AuthenticationCubit>(context),
              child: InfoDrawer(
                afterInboxClosed: () => _documentsCubit.reload(),
              ),
            ),
            floatingActionButton: BlocBuilder<DocumentsCubit, DocumentsState>(
              builder: (context, state) {
                final appliedFiltersCount = state.filter.appliedFiltersCount;
                return Badge(
                  toAnimate: false,
                  showBadge: appliedFiltersCount > 0,
                  badgeContent: appliedFiltersCount > 0
                      ? Text(state.filter.appliedFiltersCount.toString())
                      : null,
                  child: FloatingActionButton(
                    child: const Icon(Icons.filter_alt),
                    onPressed: _openDocumentFilter,
                  ),
                );
              },
            ),
            resizeToAvoidBottomInset: true,
            body: _buildBody(connectivityState));
      },
    );
  }

  void _openDocumentFilter() async {
    final filter = await showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height - kToolbarHeight - 16,
        child: LabelsBlocProvider(
          child: DocumentFilterPanel(
            initialFilter: _documentsCubit.state.filter,
          ),
        ),
      ),
      isDismissible: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
    );
    if (filter != null) {
      _documentsCubit.updateFilter(filter: filter);
      _savedViewCubit.resetSelection();
    }
  }

  Widget _buildBody(ConnectivityState connectivityState) {
    return BlocBuilder<ApplicationSettingsCubit, ApplicationSettingsState>(
      builder: (context, settings) {
        return BlocBuilder<DocumentsCubit, DocumentsState>(
          builder: (context, state) {
            // Some ugly tricks to make it work with bloc, update pageController
            _pagingController.value = PagingState(
              itemList: state.documents,
              nextPageKey: state.nextPageNumber,
            );

            late Widget child;
            switch (settings.preferredViewType) {
              case ViewType.list:
                child = DocumentListView(
                  onTap: _openDetails,
                  state: state,
                  onSelected: _onSelected,
                  pagingController: _pagingController,
                  hasInternetConnection:
                      connectivityState == ConnectivityState.connected,
                  onTagSelected: _addTagToFilter,
                );
                break;
              case ViewType.grid:
                child = DocumentGridView(
                  onTap: _openDetails,
                  state: state,
                  onSelected: _onSelected,
                  pagingController: _pagingController,
                  hasInternetConnection:
                      connectivityState == ConnectivityState.connected,
                  onTagSelected: _addTagToFilter,
                );
                break;
            }

            if (state.isLoaded && state.documents.isEmpty) {
              child = SliverToBoxAdapter(
                child: DocumentsEmptyState(
                  state: state,
                  onReset: () {
                    _documentsCubit.updateFilter();
                    _savedViewCubit.resetSelection();
                  },
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                slivers: [
                  BlocListener<SavedViewCubit, SavedViewState>(
                    listenWhen: (previous, current) =>
                        previous.selectedSavedViewId !=
                        current.selectedSavedViewId,
                    listener: (context, state) {
                      try {
                        if (state.selectedSavedViewId == null) {
                          _documentsCubit.updateFilter();
                        } else {
                          final newFilter = state
                              .value[state.selectedSavedViewId]
                              ?.toDocumentFilter();
                          if (newFilter != null) {
                            _documentsCubit.updateFilter(filter: newFilter);
                          }
                        }
                      } on PaperlessServerException catch (error, stackTrace) {
                        showErrorMessage(context, error, stackTrace);
                      }
                    },
                    child: DocumentsPageAppBar(
                      actions: [
                        const SortDocumentsButton(),
                        IconButton(
                          icon: Icon(
                            settings.preferredViewType == ViewType.grid
                                ? Icons.list
                                : Icons.grid_view,
                          ),
                          onPressed: () =>
                              BlocProvider.of<ApplicationSettingsCubit>(context)
                                  .setViewType(
                            settings.preferredViewType.toggle(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  child,
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openDetails(DocumentModel document) async {
    await Navigator.of(context).push<DocumentModel?>(
      _buildDetailsPageRoute(document),
    );
    _documentsCubit.reload();
  }

  MaterialPageRoute<DocumentModel?> _buildDetailsPageRoute(
      DocumentModel document) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: DocumentDetailsCubit(getIt<PaperlessDocumentsApi>(), document),
        child: const LabelRepositoriesProvider(
          child: DocumentDetailsPage(),
        ),
      ),
    );
  }

  void _addTagToFilter(int tagId) {
    try {
      final tagsQuery = _documentsCubit.state.filter.tags is IdsTagsQuery
          ? _documentsCubit.state.filter.tags as IdsTagsQuery
          : const IdsTagsQuery();
      if (tagsQuery.includedIds.contains(tagId)) {
        _documentsCubit.updateCurrentFilter(
          (filter) => filter.copyWith(
            tags: tagsQuery.withIdsRemoved([tagId]),
          ),
        );
      } else {
        _documentsCubit.updateCurrentFilter(
          (filter) => filter.copyWith(
            tags: tagsQuery.withIdQueriesAdded([IncludeTagIdQuery(tagId)]),
          ),
        );
      }
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  Future<void> _loadNewPage(int pageKey) async {
    final pageCount = _documentsCubit.state
        .inferPageCount(pageSize: _documentsCubit.state.filter.pageSize);
    if (pageCount <= pageKey + 1) {
      _pagingController.nextPageKey = null;
    }
    try {
      await _documentsCubit.loadMore();
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  void _onSelected(DocumentModel model) {
    _documentsCubit.toggleDocumentSelection(model);
  }

  Future<void> _onRefresh() async {
    try {
      await _documentsCubit.updateCurrentFilter(
        (filter) => filter.copyWith(page: 1),
      );
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
