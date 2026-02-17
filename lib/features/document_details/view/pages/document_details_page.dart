import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_filex/open_filex.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/accessibility/accessibility_utils.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/bloc/loading_status.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/translation/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/widgets/material/colored_tab_bar.dart';
import 'package:paperless_mobile/features/document_details/cubit/document_details_cubit.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_content_widget.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_download_button.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_meta_data_widget.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_notes_widget.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_overview_widget.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_permissions_widget.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_share_button.dart';
import 'package:paperless_mobile/features/documents/view/widgets/delete_document_confirmation_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/similar_documents/cubit/similar_documents_cubit.dart';
import 'package:paperless_mobile/features/similar_documents/view/similar_documents_view.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/connectivity_aware_action_wrapper.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';
import 'package:paperless_mobile/core/theme.dart';

class DocumentDetailsPage extends StatefulWidget {
  final int id;
  final String? title;
  final bool isLabelClickable;
  final String? titleAndContentQueryString;
  final String? thumbnailUrl;
  final String? heroTag;

  const DocumentDetailsPage({
    super.key,
    this.isLabelClickable = true,
    this.titleAndContentQueryString,
    this.thumbnailUrl,
    required this.id,
    this.heroTag,
    this.title,
  });

  @override
  State<DocumentDetailsPage> createState() => _DocumentDetailsPageState();
}

class _DocumentDetailsPageState extends State<DocumentDetailsPage> {
  static const double _itemSpacing = 24;

  final _pagingScrollController = ScrollController();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializeDateFormatting(Localizations.localeOf(context).toString());
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    debugPrint(disableAnimations.toString());
    final hasMultiUserSupport =
        context.watch<LocalUserAccount>().hasMultiUserSupport;
    final tabLength = 5 + (hasMultiUserSupport ? 1 : 0);
    return AnnotatedRegion(
      value: buildOverlayStyle(
        Theme.of(context),
        systemNavigationBarColor: Theme.of(context).bottomAppBarTheme.color,
      ),
      child: BlocBuilder<DocumentDetailsCubit, DocumentDetailsState>(
        builder: (context, state) {
          return DefaultTabController(
            length: tabLength,
            child: Scaffold(
              extendBodyBehindAppBar: false,
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endDocked,
              floatingActionButton: switch (state.status) {
                LoadingStatus.loaded => _buildEditButton(state.document!),
                _ => null
              },
              bottomNavigationBar: _buildBottomAppBar(),
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context),
                    sliver:
                        BlocBuilder<DocumentDetailsCubit, DocumentDetailsState>(
                      builder: (context, state) {
                        final title = switch (state.status) {
                          LoadingStatus.loaded => state.document!.title,
                          _ => widget.title ?? '',
                        };
                        return SliverAppBar(
                          title: Text(title),
                          leading: const BackButton(),
                          pinned: true,
                          forceElevated: innerBoxIsScrolled,
                          collapsedHeight: kToolbarHeight,
                          expandedHeight: 250.0,
                          flexibleSpace: FlexibleSpaceBar(
                            background: Builder(
                              builder: (context) {
                                return Hero(
                                  tag: widget.heroTag ?? "thumb_${widget.id}",
                                  child: GestureDetector(
                                    onTap: () {
                                      DocumentPreviewRoute(
                                        id: widget.id,
                                        title: title,
                                      ).push(context);
                                    },
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        Positioned.fill(
                                          child: DocumentPreview(
                                            documentId: widget.id,
                                            title: title,
                                            enableHero: false,
                                            fit: BoxFit.cover,
                                            alignment: Alignment.topCenter,
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                stops: [0.2, 0.4],
                                                colors: [
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .surface
                                                      .withAlpha(153),
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .surface
                                                      .withAlpha(77),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).accessible();
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Text(
                                    S.of(context)!.content,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Text(
                                    S.of(context)!.metaData,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Text(
                                    S.of(context)!.similarDocuments,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                      if ((state.document?.notes.length ?? 0) >
                                          0)
                                        Card(
                                          child: Text(state
                                                  .document!.notes.length
                                                  .toString())
                                              .paddedSymmetrically(
                                                  horizontal: 8, vertical: 2),
                                        ),
                                    ],
                                  ),
                                ),
                                if (hasMultiUserSupport)
                                  Tab(
                                    child: Text(
                                      S.of(context)!.permissions,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                body: BlocBuilder<DocumentDetailsCubit, DocumentDetailsState>(
                  builder: (context, state) {
                    return BlocProvider(
                      create: (context) => SimilarDocumentsCubit(
                        context.read(),
                        context.read(),
                        context.read(),
                        documentId: widget.id,
                      ),
                      child: TabBarView(
                        children: [
                          CustomScrollView(
                            slivers: [
                              SliverOverlapInjector(
                                handle: NestedScrollView
                                    .sliverOverlapAbsorberHandleFor(context),
                              ),
                              switch (state.status) {
                                LoadingStatus.loaded => DocumentOverviewWidget(
                                    document: state.document!,
                                    itemSpacing: _itemSpacing,
                                    queryString:
                                        widget.titleAndContentQueryString,
                                  ).paddedSymmetrically(
                                    vertical: 16,
                                    sliver: true,
                                  ),
                                LoadingStatus.error => _buildErrorState(),
                                _ => _buildLoadingState(),
                              },
                            ],
                          ),
                          CustomScrollView(
                            slivers: [
                              SliverOverlapInjector(
                                handle: NestedScrollView
                                    .sliverOverlapAbsorberHandleFor(context),
                              ),
                              switch (state.status) {
                                LoadingStatus.loaded => DocumentContentWidget(
                                    document: state.document!,
                                    queryString:
                                        widget.titleAndContentQueryString,
                                  ).paddedSymmetrically(
                                    vertical: 16,
                                    sliver: true,
                                  ),
                                LoadingStatus.error => _buildErrorState(),
                                _ => _buildLoadingState(),
                              }
                            ],
                          ),
                          CustomScrollView(
                            slivers: [
                              SliverOverlapInjector(
                                handle: NestedScrollView
                                    .sliverOverlapAbsorberHandleFor(context),
                              ),
                              switch (state.status) {
                                LoadingStatus.loaded => DocumentMetaDataWidget(
                                    document: state.document!,
                                    itemSpacing: _itemSpacing,
                                    metaData: state.metaData!,
                                  ).paddedSymmetrically(
                                    vertical: 16,
                                    sliver: true,
                                  ),
                                LoadingStatus.error => _buildErrorState(),
                                _ => _buildLoadingState(),
                              },
                            ],
                          ),
                          CustomScrollView(
                            controller: _pagingScrollController,
                            slivers: [
                              SliverOverlapInjector(
                                handle: NestedScrollView
                                    .sliverOverlapAbsorberHandleFor(context),
                              ),
                              SimilarDocumentsView(
                                pagingScrollController: _pagingScrollController,
                              ).paddedSymmetrically(
                                vertical: 16,
                                sliver: true,
                              ),
                            ],
                          ),
                          CustomScrollView(
                            slivers: [
                              SliverOverlapInjector(
                                handle: NestedScrollView
                                    .sliverOverlapAbsorberHandleFor(context),
                              ),
                              switch (state.status) {
                                LoadingStatus.loaded => DocumentNotesWidget(
                                    document: state.document!,
                                  ).paddedSymmetrically(
                                    vertical: 16,
                                    sliver: true,
                                  ),
                                LoadingStatus.error => _buildErrorState(),
                                _ => _buildLoadingState(),
                              },
                            ],
                          ),
                          if (hasMultiUserSupport)
                            CustomScrollView(
                              controller: _pagingScrollController,
                              slivers: [
                                SliverOverlapInjector(
                                  handle: NestedScrollView
                                      .sliverOverlapAbsorberHandleFor(context),
                                ),
                                switch (state.status) {
                                  LoadingStatus.loaded =>
                                    DocumentPermissionsWidget(
                                      document: state.document!,
                                    ).paddedSymmetrically(
                                      vertical: 16,
                                      sliver: true,
                                    ),
                                  LoadingStatus.error => _buildErrorState(),
                                  _ => _buildLoadingState(),
                                }
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
                      ),
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

  Widget _buildEditButton(DocumentModel document) {
    final currentUser = context.watch<LocalUserAccount>();

    bool canEdit = context.watchInternetConnection &&
        currentUser.paperlessUser.canEditDocuments;
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
        onPressed: () => EditDocumentRoute(document).push(context),
      ),
    );
  }

  Widget _buildErrorState() {
    return SliverToBoxAdapter(
      child: Center(
        child: Text("Could not load document."),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverFillRemaining(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  BlocBuilder<DocumentDetailsCubit, DocumentDetailsState> _buildBottomAppBar() {
    return BlocBuilder<DocumentDetailsCubit, DocumentDetailsState>(
      builder: (context, state) {
        final currentUser = context.watch<LocalUserAccount>();
        return BottomAppBar(
          child: Builder(
            builder: (context) {
              return switch (state.status) {
                LoadingStatus.loaded => Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ConnectivityAwareActionWrapper(
                        disabled: !currentUser.paperlessUser.canDeleteDocuments,
                        offlineBuilder: (context, child) {
                          return const IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: null,
                          ).paddedSymmetrically(horizontal: 4);
                        },
                        child: IconButton(
                          tooltip: S.of(context)!.deleteDocumentTooltip,
                          icon: const Icon(Icons.delete),
                          onPressed: () => _onDelete(state.document!),
                        ).paddedSymmetrically(horizontal: 4),
                      ),
                      ConnectivityAwareActionWrapper(
                        offlineBuilder: (context, child) =>
                            const DocumentDownloadButton(
                          document: null,
                          enabled: false,
                        ),
                        child: DocumentDownloadButton(
                          document: state.document,
                        ),
                      ),
                      ConnectivityAwareActionWrapper(
                        offlineBuilder: (context, child) => const IconButton(
                          icon: Icon(Icons.open_in_new),
                          onPressed: null,
                        ),
                        child: IconButton(
                          tooltip: S.of(context)!.openInSystemViewer,
                          icon: const Icon(Icons.open_in_new),
                          onPressed: _onOpenFileInSystemViewer,
                        ).paddedOnly(right: 4.0),
                      ),
                      DocumentShareButton(document: state.document),
                      IconButton(
                        tooltip: S.of(context)!.print,
                        onPressed: () => context
                            .read<DocumentDetailsCubit>()
                            .printDocument(),
                        icon: const Icon(Icons.print),
                      ),
                    ],
                  ),
                _ => SizedBox.shrink(),
              };
            },
          ),
        );
      },
    );
  }

  void _onOpenFileInSystemViewer() async {
    final status =
        await context.read<DocumentDetailsCubit>().openDocumentInSystemViewer();
    switch (status) {
      case ResultType.done:
        return;
      case ResultType.noAppToOpen:
        if (mounted) {
          showGenericError(context, S.of(context)!.noAppToDisplayPDFFilesFound);
        }
      case ResultType.fileNotFound:
        if (mounted) {
          showGenericError(context, translateError(context, ErrorCode.unknown));
        }
      case ResultType.permissionDenied:
        if (mounted) {
          showGenericError(
              context, S.of(context)!.couldNotOpenFilePermissionDenied);
        }
      case ResultType.error:
      //TODO: Show and log error
    }
  }

  void _onDelete(DocumentModel document) async {
    final delete = await showDialog(
          context: context,
          builder: (context) =>
              DeleteDocumentConfirmationDialog(document: document),
        ) ??
        false;
    if (delete) {
      try {
        if (mounted) {
          await context.read<DocumentDetailsCubit>().delete(document);
          // showSnackBar(context, S.of(context)!.documentSuccessfullyDeleted);
        }
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
}
