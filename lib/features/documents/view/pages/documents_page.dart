import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/repository/provider/label_repositories_provider.dart';
import 'package:paperless_mobile/features/document_details/bloc/document_details_cubit.dart';
import 'package:paperless_mobile/features/document_details/view/pages/document_details_page.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
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
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';
import 'package:paperless_mobile/features/settings/model/view_type.dart';
import 'package:paperless_mobile/util.dart';

class DocumentFilterIntent {
  final DocumentFilter? filter;
  final bool shouldReset;

  DocumentFilterIntent({
    this.filter,
    this.shouldReset = false,
  });
}

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({Key? key}) : super(key: key);

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final _pagingController = PagingController<int, DocumentModel>(
    firstPageKey: 1,
  );

  @override
  void initState() {
    super.initState();
    try {
      context.read<DocumentsCubit>().reload();
      context.read<SavedViewCubit>().reload();
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
        try {
          context.read<DocumentsCubit>().reload();
        } on PaperlessServerException catch (error, stackTrace) {
          showErrorMessage(context, error, stackTrace);
        }
      },
      builder: (context, connectivityState) {
        return Scaffold(
          drawer: BlocProvider.value(
            value: context.read<AuthenticationCubit>(),
            child: InfoDrawer(
              afterInboxClosed: () => context.read<DocumentsCubit>().reload(),
            ),
          ),
          floatingActionButton: BlocBuilder<DocumentsCubit, DocumentsState>(
            builder: (context, state) {
              final appliedFiltersCount = state.filter.appliedFiltersCount;
              return Badge.count(
                //TODO: Wait for stable version of m3, then use AlignmentDirectional.topEnd
                alignment: const AlignmentDirectional(44, -4),
                isLabelVisible: appliedFiltersCount > 0,
                count: state.filter.appliedFiltersCount,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                child: FloatingActionButton(
                  child: const Icon(Icons.filter_alt_outlined),
                  onPressed: _openDocumentFilter,
                ),
              );
            },
          ),
          resizeToAvoidBottomInset: true,
          body: _buildBody(connectivityState),
        );
      },
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
      builder: (_) => BlocProvider.value(
        value: context.read<DocumentsCubit>(),
        child: DraggableScrollableSheet(
          controller: draggableSheetController,
          expand: false,
          snap: true,
          snapSizes: const [0.9, 1],
          initialChildSize: .9,
          maxChildSize: 1,
          builder: (context, controller) => LabelsBlocProvider(
            child: DocumentFilterPanel(
              initialFilter: context.read<DocumentsCubit>().state.filter,
              scrollController: controller,
              draggableSheetController: draggableSheetController,
            ),
          ),
        ),
      ),
    );
    if (filterIntent != null) {
      try {
        if (filterIntent.shouldReset) {
          await context.read<DocumentsCubit>().resetFilter();
          context.read<DocumentsCubit>().unselectView();
        } else {
          if (filterIntent.filter !=
              context.read<DocumentsCubit>().state.filter) {
            context.read<DocumentsCubit>().unselectView();
          }
          await context
              .read<DocumentsCubit>()
              .updateFilter(filter: filterIntent.filter!);
        }
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      }
    }
  }

  Widget _buildBody(ConnectivityState connectivityState) {
    final isConnected = connectivityState == ConnectivityState.connected;
    return BlocBuilder<ApplicationSettingsCubit, ApplicationSettingsState>(
      builder: (context, settings) {
        return BlocBuilder<DocumentsCubit, DocumentsState>(
          buildWhen: (previous, current) => !const ListEquality()
              .equals(previous.documents, current.documents),
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
                  state: state,
                  onTap: _openDetails,
                  onSelected: _onSelected,
                  pagingController: _pagingController,
                  hasInternetConnection: isConnected,
                  onTagSelected: _addTagToFilter,
                  onCorrespondentSelected: _addCorrespondentToFilter,
                  onDocumentTypeSelected: _addDocumentTypeToFilter,
                  onStoragePathSelected: _addStoragePathToFilter,
                );
                break;
              case ViewType.grid:
                child = DocumentGridView(
                  state: state,
                  onTap: _openDetails,
                  onSelected: _onSelected,
                  pagingController: _pagingController,
                  hasInternetConnection: isConnected,
                  onTagSelected: _addTagToFilter,
                  onCorrespondentSelected: _addCorrespondentToFilter,
                  onDocumentTypeSelected: _addDocumentTypeToFilter,
                  onStoragePathSelected: _addStoragePathToFilter,
                );
                break;
            }

            if (state.hasLoaded && state.documents.isEmpty) {
              child = SliverToBoxAdapter(
                child: DocumentsEmptyState(
                  state: state,
                  onReset: () {
                    context.read<DocumentsCubit>().resetFilter();
                    context.read<DocumentsCubit>().unselectView();
                  },
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              notificationPredicate: (_) => isConnected,
              child: CustomScrollView(
                slivers: [
                  DocumentsPageAppBar(
                    isOffline: connectivityState != ConnectivityState.connected,
                    actions: [
                      const SortDocumentsButton(),
                      IconButton(
                        icon: Icon(
                          settings.preferredViewType == ViewType.grid
                              ? Icons.list
                              : Icons.grid_view,
                        ),
                        onPressed: () => context
                            .read<ApplicationSettingsCubit>()
                            .setViewType(
                              settings.preferredViewType.toggle(),
                            ),
                      ),
                    ],
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
    final potentiallyUpdatedModel =
        await Navigator.of(context).push<DocumentModel?>(
      _buildDetailsPageRoute(document),
    );
    if (potentiallyUpdatedModel != document) {
      context.read<DocumentsCubit>().reload();
    }
  }

  MaterialPageRoute<DocumentModel?> _buildDetailsPageRoute(
      DocumentModel document) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => DocumentDetailsCubit(
          context.read<PaperlessDocumentsApi>(),
          document,
        ),
        child: const LabelRepositoriesProvider(
          child: DocumentDetailsPage(),
        ),
      ),
    );
  }

  void _addTagToFilter(int tagId) {
    try {
      final tagsQuery =
          context.read<DocumentsCubit>().state.filter.tags is IdsTagsQuery
              ? context.read<DocumentsCubit>().state.filter.tags as IdsTagsQuery
              : const IdsTagsQuery();
      if (tagsQuery.includedIds.contains(tagId)) {
        context.read<DocumentsCubit>().updateCurrentFilter(
              (filter) => filter.copyWith(
                tags: tagsQuery.withIdsRemoved([tagId]),
              ),
            );
      } else {
        context.read<DocumentsCubit>().updateCurrentFilter(
              (filter) => filter.copyWith(
                tags: tagsQuery.withIdQueriesAdded([IncludeTagIdQuery(tagId)]),
              ),
            );
      }
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  void _addCorrespondentToFilter(int? correspondentId) {
    final cubit = context.read<DocumentsCubit>();
    try {
      if (cubit.state.filter.correspondent.id == correspondentId) {
        cubit.updateCurrentFilter(
          (filter) =>
              filter.copyWith(correspondent: const IdQueryParameter.unset()),
        );
      } else {
        cubit.updateCurrentFilter(
          (filter) => filter.copyWith(
              correspondent: IdQueryParameter.fromId(correspondentId)),
        );
      }
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  void _addDocumentTypeToFilter(int? documentTypeId) {
    final cubit = context.read<DocumentsCubit>();
    try {
      if (cubit.state.filter.documentType.id == documentTypeId) {
        cubit.updateCurrentFilter(
          (filter) =>
              filter.copyWith(documentType: const IdQueryParameter.unset()),
        );
      } else {
        cubit.updateCurrentFilter(
          (filter) => filter.copyWith(
              documentType: IdQueryParameter.fromId(documentTypeId)),
        );
      }
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  void _addStoragePathToFilter(int? pathId) {
    final cubit = context.read<DocumentsCubit>();
    try {
      if (cubit.state.filter.correspondent.id == pathId) {
        cubit.updateCurrentFilter(
          (filter) =>
              filter.copyWith(storagePath: const IdQueryParameter.unset()),
        );
      } else {
        cubit.updateCurrentFilter(
          (filter) =>
              filter.copyWith(storagePath: IdQueryParameter.fromId(pathId)),
        );
      }
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  Future<void> _loadNewPage(int pageKey) async {
    final documentsCubit = context.read<DocumentsCubit>();
    final pageCount = documentsCubit.state
        .inferPageCount(pageSize: documentsCubit.state.filter.pageSize);
    if (pageCount <= pageKey + 1) {
      _pagingController.nextPageKey = null;
    }
    try {
      await documentsCubit.loadMore();
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  void _onSelected(DocumentModel model) {
    context.read<DocumentsCubit>().toggleDocumentSelection(model);
  }

  Future<void> _onRefresh() async {
    try {
      // We do not await here on purpose so we can show a linear progress indicator below the app bar.
      await context.read<DocumentsCubit>().reload();
      await context.read<SavedViewCubit>().reload();
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
