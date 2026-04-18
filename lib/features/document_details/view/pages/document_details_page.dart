import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:paperless_mobile/api/extensions/cached_query_extensions.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/store/slices/local_user_account.dart';
import 'package:paperless_mobile/core/widgets/material/colored_tab_bar.dart';
import 'package:paperless_mobile/features/document_details/document_download/view/document_download_button.dart';
import 'package:paperless_mobile/features/document_details/document_open_in_system/view/document_open_in_system_viewer_button.dart';
import 'package:paperless_mobile/features/document_details/document_share/view/document_share_button.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_content_widget.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_meta_data_widget.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_notes_widget.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_overview_widget.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_permissions_widget.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_view.dart';
import 'package:paperless_mobile/features/documents/view/widgets/delete_document_confirmation_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/similar_documents/view/similar_documents_view.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/connectivity_aware_action_wrapper.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';
import 'package:paperless_mobile/theme.dart';

class DocumentDetailsPage extends StatefulWidget {
  final int id;
  final String? title;
  final bool isLabelClickable;
  final String? titleAndContentQueryString;
  final String? thumbnailUrl;
  final String? heroTagPrefix;

  const DocumentDetailsPage({
    super.key,
    this.isLabelClickable = true,
    this.titleAndContentQueryString,
    this.thumbnailUrl,
    required this.id,
    this.heroTagPrefix,
    this.title,
  });

  @override
  State<DocumentDetailsPage> createState() => _DocumentDetailsPageState();
}

class _DocumentDetailsPageState extends State<DocumentDetailsPage> {
  static const double _itemSpacing = 24;

  final _pagingScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.documentRepository.getMetaDataQuery(widget.id).fetch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializeDateFormatting(Localizations.localeOf(context).toString());
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.loggedInUser$;
    return PopScope(
      canPop: true,
      child: AnnotatedRegion(
        value: buildOverlayStyle(
          Theme.of(context),
          systemNavigationBarColor: Theme.of(context).bottomAppBarTheme.color,
        ),
        child: QueryBuilder(
          query: context.documentRepository.getDocumentQuery(widget.id),
          builder: (context, state) {
            return DefaultTabController(
              length: 6,
              child: Scaffold(
                extendBodyBehindAppBar: false,
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endDocked,
                floatingActionButton: state.data != null
                    ? _buildEditButton(state.data!, currentUser)
                    : null,
                bottomNavigationBar: _buildBottomAppBar(state, currentUser),
                body: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverOverlapAbsorber(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                      sliver: _buildSliverAppBar(
                        state.data?.title ?? widget.title ?? '',
                        innerBoxIsScrolled,
                        state,
                      ),
                    ),
                  ],
                  body: Builder(
                    builder: (context) {
                      return _buildBody(context, state);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, QueryStatus<Document> state) {
    if (state.isLoadingInitial) {
      return _buildLoadingState();
    }

    if (state.isError) {
      return _buildErrorState();
    }

    final document = state.data!;
    return TabBarView(
      children:
          [
                CustomScrollView(
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    DocumentOverviewWidget(
                      document: document,
                      itemSpacing: _itemSpacing,
                      queryString: widget.titleAndContentQueryString,
                    ).paddedSymmetrically(vertical: 16, sliver: true),
                  ],
                ),
                CustomScrollView(
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    DocumentContentWidget(
                      document: document,
                      queryString: widget.titleAndContentQueryString,
                    ).paddedSymmetrically(vertical: 16, sliver: true),
                  ],
                ),
                CustomScrollView(
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    DocumentMetaDataWidget(
                      document: document,
                      itemSpacing: _itemSpacing,
                    ).paddedSymmetrically(vertical: 16, sliver: true),
                  ],
                ),
                CustomScrollView(
                  controller: _pagingScrollController,
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    SimilarDocumentsView(
                      documentId: widget.id,
                      pagingScrollController: _pagingScrollController,
                    ).paddedSymmetrically(vertical: 16, sliver: true),
                  ],
                ),
                CustomScrollView(
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    DocumentNotesWidget(
                      documentId: widget.id,
                    ).paddedSymmetrically(vertical: 16, sliver: true),
                  ],
                ),
                CustomScrollView(
                  controller: _pagingScrollController,
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    DocumentPermissionsWidget(
                      document: document,
                    ).paddedSymmetrically(vertical: 16, sliver: true),
                  ],
                ),
              ]
              .map(
                (child) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: child,
                ),
              )
              .toList(),
    );
  }

  SliverAppBar _buildSliverAppBar(
    String title,
    bool innerBoxIsScrolled,
    QueryState<Document> state,
  ) {
    return SliverAppBar(
      title: title.isNotEmpty ? Text(title) : null,
      leading: const BackButton(),
      pinned: true,
      forceElevated: innerBoxIsScrolled,
      collapsedHeight: kToolbarHeight,
      expandedHeight: 250.0,
      flexibleSpace: FlexibleSpaceBar(
        background: Builder(
          builder: (context) {
            return GestureDetector(
              onTap: canPreviewMimeType(state.data?.mimeType)
                  ? () {
                      DocumentPreviewRoute(
                        documentId: widget.id,
                        title: title,
                        mimeType: state.data?.mimeType,
                      ).push(context);
                    }
                  : null,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned.fill(
                    child: DocumentPreview(
                      documentId: widget.id,
                      title: title,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      heroTagPrefix: widget.heroTagPrefix,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          stops: [0.2, 0.4],
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.surface.withAlpha(153),
                            Theme.of(context).colorScheme.surface.withAlpha(77),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottom: ColoredTabBar(
        tabBar: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              child: Text(
                S.of(context)!.overview,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            Tab(
              child: Text(
                S.of(context)!.content,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            Tab(
              child: Text(
                S.of(context)!.metaData,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            Tab(
              child: Text(
                S.of(context)!.similarDocuments,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    S.of(context)!.notes(0),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if ((state.data?.notes?.length ?? 0) > 0)
                    Card(
                      child: Text(
                        state.data!.notes!.length.toString(),
                      ).paddedSymmetrically(horizontal: 8, vertical: 2),
                    ),
                ],
              ),
            ),
            Tab(
              child: Text(
                S.of(context)!.permissions,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton(Document document, LocalUserAccount currentUser) {
    bool canEdit =
        context.internetConnection$ &&
        currentUser.profile.uiSettings.canEditDocuments;
    if (!canEdit) {
      return const SizedBox.shrink();
    }
    return Tooltip(
      message: S.of(context)!.editDocumentTooltip,
      preferBelow: false,
      verticalOffset: 40,
      child: FloatingActionButton(
        heroTag: "fab_document_details",
        child: const Icon(Icons.edit),
        onPressed: () => EditDocumentRoute(documentId: widget.id).push(context),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(child: Text("Could not load document."));
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildBottomAppBar(
    QueryState<Document> state,
    LocalUserAccount currentUser,
  ) {
    return BottomAppBar(
      child: Builder(
        builder: (context) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ConnectivityAwareActionWrapper(
                disabled: !currentUser.profile.uiSettings.canDeleteDocuments,
                offlineBuilder: (context, child) {
                  return const IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: null,
                  ).paddedSymmetrically(horizontal: 4);
                },
                child: MutationConsumer(
                  listener: (state) {
                    if (state is MutationError) {
                      showGenericError(context, state.error);
                    }
                  },
                  mutation: context.documentRepository.deleteDocumentMutation(
                    widget.id,
                  ),
                  builder: (context, mutationState, delete) {
                    return IconButton(
                      tooltip: S.of(context)!.deleteDocumentTooltip,
                      icon: mutationState.isLoading
                          ? CircularProgressIndicator()
                          : Icon(Icons.delete),
                      onPressed: () => _onDelete(state.data!, delete),
                    ).paddedSymmetrically(horizontal: 4);
                  },
                ),
              ),
              ConnectivityAwareActionWrapper(
                offlineBuilder: (context, child) =>
                    const DocumentDownloadButton(
                      document: null,
                      enabled: false,
                    ),
                child: DocumentDownloadButton(document: state.data),
              ),
              ConnectivityAwareActionWrapper(
                offlineBuilder: (context, child) => const IconButton(
                  icon: Icon(Icons.open_in_new),
                  onPressed: null,
                ),
                child: DocumentOpenInSystemViewerButton().paddedOnly(
                  right: 4.0,
                ),
              ),
              DocumentShareButton(),
            ],
          );
        },
      ),
    );
  }

  void _onDelete(
    Document document,
    Future<MutationState<void>> Function(void) delete,
  ) async {
    final shouldDelete =
        await showDialog(
          useRootNavigator: false,
          context: context,
          builder: (context) =>
              DeleteDocumentConfirmationDialog(document: document),
        ) ??
        false;
    if (!shouldDelete) {
      return;
    }
    try {
      await delete(null);
      // showSnackBar(context, S.of(context)!.documentSuccessfullyDeleted);
    } on PaperlessApiException catch (error, stackTrace) {
      if (mounted) {
        showErrorMessage(context, error, stackTrace);
      }
    } finally {
      if (mounted) {
        context.pop();
      }
    }
  }
}
