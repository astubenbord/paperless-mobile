import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/service/github_issue_service.dart';
import 'package:paperless_mobile/core/widgets/offline_banner.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/labels/correspondent/bloc/correspondents_cubit.dart';
import 'package:paperless_mobile/features/labels/document_type/bloc/document_type_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_details_page.dart';
import 'package:paperless_mobile/features/documents/view/widgets/documents_empty_state.dart';
import 'package:paperless_mobile/features/documents/view/widgets/grid/document_grid.dart';
import 'package:paperless_mobile/features/documents/view/widgets/list/document_list.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/document_filter_panel.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/documents_page_app_bar.dart';
import 'package:paperless_mobile/features/documents/view/widgets/sort_documents_button.dart';
import 'package:paperless_mobile/features/home/view/widget/info_drawer.dart';
import 'package:paperless_mobile/features/labels/storage_path/bloc/storage_path_cubit.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:paperless_mobile/features/labels/tags/bloc/tags_cubit.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';
import 'package:paperless_mobile/features/settings/model/view_type.dart';
import 'package:paperless_mobile/util.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({Key? key}) : super(key: key);

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final PagingController<int, DocumentModel> _pagingController =
      PagingController<int, DocumentModel>(
    firstPageKey: 1,
  );

  final PanelController _panelController = PanelController();

  @override
  void initState() {
    super.initState();
    if (!BlocProvider.of<DocumentsCubit>(context).state.isLoaded) {
      _initDocuments();
    }
    _pagingController.addPageRequestListener(_loadNewPage);
  }

  Future<void> _initDocuments() async {
    try {
      BlocProvider.of<DocumentsCubit>(context).loadDocuments();
    } on ErrorMessage catch (error, stackTrace) {
      showError(context, error, stackTrace);
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _loadNewPage(int pageKey) async {
    final documentsCubit = BlocProvider.of<DocumentsCubit>(context);
    final pageCount = documentsCubit.state
        .inferPageCount(pageSize: documentsCubit.state.filter.pageSize);
    if (pageCount <= pageKey + 1) {
      _pagingController.nextPageKey = null;
    }
    try {
      await documentsCubit.loadMore();
    } on ErrorMessage catch (error, stackTrace) {
      showError(context, error, stackTrace);
    }
  }

  void _onSelected(DocumentModel model) {
    BlocProvider.of<DocumentsCubit>(context).toggleDocumentSelection(model);
  }

  Future<void> _onRefresh() async {
    try {
      await BlocProvider.of<DocumentsCubit>(context).updateCurrentFilter(
        (filter) => filter.copyWith(page: 1),
      );
    } on ErrorMessage catch (error, stackTrace) {
      showError(context, error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_panelController.isPanelOpen) {
          FocusScope.of(context).unfocus();
          _panelController.close();
          return false;
        }
        final documentsCubit = BlocProvider.of<DocumentsCubit>(context);
        if (documentsCubit.state.selection.isNotEmpty) {
          documentsCubit.resetSelection();
          return false;
        }
        return true;
      },
      child: BlocConsumer<ConnectivityCubit, ConnectivityState>(
        listenWhen: (previous, current) =>
            previous != ConnectivityState.connected &&
            current == ConnectivityState.connected,
        listener: (context, state) {
          BlocProvider.of<DocumentsCubit>(context).loadDocuments();
        },
        builder: (context, connectivityState) {
          return Scaffold(
            drawer: BlocProvider.value(
              value: BlocProvider.of<AuthenticationCubit>(context),
              child: const InfoDrawer(),
            ),
            resizeToAvoidBottomInset: true,
            body: SlidingUpPanel(
              backdropEnabled: true,
              parallaxEnabled: true,
              parallaxOffset: .5,
              controller: _panelController,
              defaultPanelState: PanelState.CLOSED,
              minHeight: 48,
              maxHeight: (MediaQuery.of(context).size.height * 3) / 4,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              body: _buildBody(connectivityState),
              color: Theme.of(context).scaffoldBackgroundColor,
              panelBuilder: (scrollController) => DocumentFilterPanel(
                panelController: _panelController,
                scrollController: scrollController,
              ),
            ),
          );
        },
      ),
    );
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
                  onTap: _openDocumentDetails,
                  state: state,
                  onSelected: _onSelected,
                  pagingController: _pagingController,
                  hasInternetConnection:
                      connectivityState == ConnectivityState.connected,
                );
                break;
              case ViewType.grid:
                child = DocumentGridView(
                    onTap: _openDocumentDetails,
                    state: state,
                    onSelected: _onSelected,
                    pagingController: _pagingController,
                    hasInternetConnection:
                        connectivityState == ConnectivityState.connected);
                break;
            }

            if (state.isLoaded && state.documents.isEmpty) {
              child = SliverToBoxAdapter(
                child: DocumentsEmptyState(
                  state: state,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: Container(
                child: CustomScrollView(
                  slivers: [
                    DocumentsPageAppBar(
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
                                      settings.preferredViewType.toggle()),
                        ),
                      ],
                    ),
                    child,
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height / 4,
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openDocumentDetails(DocumentModel model) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: BlocProvider.of<DocumentsCubit>(context)),
            BlocProvider.value(
                value: BlocProvider.of<CorrespondentCubit>(context)),
            BlocProvider.value(
                value: BlocProvider.of<DocumentTypeCubit>(context)),
            BlocProvider.value(value: BlocProvider.of<TagCubit>(context)),
            BlocProvider.value(
                value: BlocProvider.of<StoragePathCubit>(context)),
          ],
          child: DocumentDetailsPage(
            documentId: model.id,
          ),
        ),
      ),
    );
  }
}
