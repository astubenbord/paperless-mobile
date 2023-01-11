import 'package:badges/badges.dart' as b;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/repository/provider/label_repositories_provider.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/document_details/bloc/document_details_cubit.dart';
import 'package:paperless_mobile/features/document_details/view/pages/document_details_page.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/view/widgets/documents_empty_state.dart';
import 'package:paperless_mobile/features/documents/view/widgets/list/adaptive_documents_view.dart';
import 'package:paperless_mobile/features/documents/view/widgets/new_items_loading_widget.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/document_filter_panel.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/bulk_delete_confirmation_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/sort_documents_button.dart';
import 'package:paperless_mobile/features/home/view/widget/info_drawer.dart';
import 'package:paperless_mobile/features/labels/bloc/providers/labels_bloc_provider.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
import 'package:paperless_mobile/features/saved_view/view/saved_view_selection_widget.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';
import 'package:paperless_mobile/features/settings/model/view_type.dart';
import 'package:paperless_mobile/features/tasks/cubit/task_status_cubit.dart';
import 'package:paperless_mobile/generated/l10n.dart';
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
  final ScrollController _scrollController = ScrollController();
  double _offset = 0;
  double _last = 0;

  static const double _savedViewWidgetHeight = 78 + 16;

  @override
  void initState() {
    super.initState();
    try {
      context.read<DocumentsCubit>().reload();
      context.read<SavedViewCubit>().reload();
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
    _scrollController
      ..addListener(_listenForScrollChanges)
      ..addListener(_listenForLoadDataTrigger);
  }

  void _listenForLoadDataTrigger() {
    final currState = context.read<DocumentsCubit>().state;
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !currState.isLoading &&
        !currState.isLastPageLoaded) {
      _loadNewPage();
    }
  }

  void _listenForScrollChanges() {
    final current = _scrollController.offset;
    _offset += _last - current;

    if (_offset <= -_savedViewWidgetHeight) _offset = -_savedViewWidgetHeight;
    if (_offset >= 0) _offset = 0;
    _last = current;
    if (_offset <= 0 && _offset >= -_savedViewWidgetHeight) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskStatusCubit, TaskStatusState>(
      listenWhen: (previous, current) =>
          !previous.isSuccess && current.isSuccess,
      listener: (context, state) {
        showSnackBar(
          context,
          S.of(context).documentsPageNewDocumentAvailableText,
          action: SnackBarActionConfig(
            label: S
                .of(context)
                .documentUploadProcessingSuccessfulReloadActionText,
            onPressed: () {
              context.read<TaskStatusCubit>().acknowledgeCurrentTask();
              context.read<DocumentsCubit>().reload();
            },
          ),
          duration: const Duration(seconds: 10),
        );
      },
      child: BlocConsumer<ConnectivityCubit, ConnectivityState>(
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
          const linearProgressIndicatorHeight = 4.0;
          return Scaffold(
            drawer: BlocProvider.value(
              value: context.read<AuthenticationCubit>(),
              child: InfoDrawer(
                afterInboxClosed: () => context.read<DocumentsCubit>().reload(),
              ),
            ),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(
                kToolbarHeight + linearProgressIndicatorHeight,
              ),
              child: BlocBuilder<DocumentsCubit, DocumentsState>(
                builder: (context, state) {
                  if (state.selection.isEmpty) {
                    return AppBar(
                      title: Text(
                        "${S.of(context).documentsPageTitle} (${_formatDocumentCount(state.count)})",
                      ),
                      actions: [
                        const SortDocumentsButton(),
                        BlocBuilder<ApplicationSettingsCubit,
                            ApplicationSettingsState>(
                          builder: (context, settingsState) => IconButton(
                            icon: Icon(
                              settingsState.preferredViewType == ViewType.grid
                                  ? Icons.list
                                  : Icons.grid_view_rounded,
                            ),
                            onPressed: () {
                              // Reset saved view widget position as scroll offset will be reset anyway.
                              setState(() {
                                _offset = 0;
                                _last = 0;
                              });
                              final cubit =
                                  context.read<ApplicationSettingsCubit>();
                              cubit.setViewType(
                                  cubit.state.preferredViewType.toggle());
                            },
                          ),
                        ),
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(
                            linearProgressIndicatorHeight),
                        child: state.isLoading
                            ? const LinearProgressIndicator()
                            : const SizedBox(height: 4.0),
                      ),
                    );
                  } else {
                    return AppBar(
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            context.read<DocumentsCubit>().resetSelection(),
                      ),
                      title: Text(
                          '${state.selection.length} ${S.of(context).documentsSelectedText}'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _onDelete(context, state),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
            floatingActionButton: BlocBuilder<DocumentsCubit, DocumentsState>(
              builder: (context, state) {
                final appliedFiltersCount = state.filter.appliedFiltersCount;
                return b.Badge(
                  position: b.BadgePosition.topEnd(top: -12, end: -6),
                  showBadge: appliedFiltersCount > 0,
                  badgeContent: Text(
                    '$appliedFiltersCount',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  animationType: b.BadgeAnimationType.fade,
                  badgeColor: Colors.red,
                  child: FloatingActionButton(
                    child: const Icon(Icons.filter_alt_outlined),
                    onPressed: _openDocumentFilter,
                  ),
                );
              },
            ),
            resizeToAvoidBottomInset: true,
            body: WillPopScope(
              onWillPop: () async {
                if (context.read<DocumentsCubit>().state.selection.isNotEmpty) {
                  context.read<DocumentsCubit>().resetSelection();
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                notificationPredicate: (_) => connectivityState.isConnected,
                child: BlocBuilder<TaskStatusCubit, TaskStatusState>(
                  builder: (context, taskState) {
                    return Stack(
                      children: [
                        _buildBody(connectivityState),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: _offset,
                          child: BlocBuilder<DocumentsCubit, DocumentsState>(
                            builder: (context, state) {
                              return ColoredBox(
                                color: Theme.of(context).colorScheme.background,
                                child: SavedViewSelectionWidget(
                                  height: _savedViewWidgetHeight,
                                  currentFilter: state.filter,
                                  enabled: state.selection.isEmpty &&
                                      connectivityState.isConnected,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onDelete(BuildContext context, DocumentsState documentsState) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) =>
              BulkDeleteConfirmationDialog(state: documentsState),
        ) ??
        false;
    if (shouldDelete) {
      try {
        await context
            .read<DocumentsCubit>()
            .bulkRemove(documentsState.selection);
        showSnackBar(
          context,
          S.of(context).documentsPageBulkDeleteSuccessfulText,
        );
        context.read<DocumentsCubit>().resetSelection();
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      }
    }
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

  String _formatDocumentCount(int count) {
    return count > 99 ? "99+" : count.toString();
  }

  Widget _buildBody(ConnectivityState connectivityState) {
    final isConnected = connectivityState == ConnectivityState.connected;
    return BlocBuilder<ApplicationSettingsCubit, ApplicationSettingsState>(
      builder: (context, settings) {
        return BlocBuilder<DocumentsCubit, DocumentsState>(
          buildWhen: (previous, current) =>
              !const ListEquality()
                  .equals(previous.documents, current.documents) ||
              previous.selectedIds != current.selectedIds,
          builder: (context, state) {
            // Some ugly tricks to make it work with bloc, update pageController

            if (state.hasLoaded && state.documents.isEmpty) {
              return DocumentsEmptyState(
                state: state,
                onReset: () {
                  context.read<DocumentsCubit>().resetFilter();
                  context.read<DocumentsCubit>().unselectView();
                },
              );
            }

            return AdaptiveDocumentsView(
              viewType: settings.preferredViewType,
              state: state,
              scrollController: _scrollController,
              onTap: _openDetails,
              onSelected: _onSelected,
              hasInternetConnection: isConnected,
              onTagSelected: _addTagToFilter,
              onCorrespondentSelected: _addCorrespondentToFilter,
              onDocumentTypeSelected: _addDocumentTypeToFilter,
              onStoragePathSelected: _addStoragePathToFilter,
              pageLoadingWidget: const NewItemsLoadingWidget(),
              beforeItems: const SizedBox(height: _savedViewWidgetHeight),
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

  Future<void> _loadNewPage() async {
    try {
      await context.read<DocumentsCubit>().loadMore();
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
      context.read<DocumentsCubit>().reload();
      context.read<SavedViewCubit>().reload();
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
