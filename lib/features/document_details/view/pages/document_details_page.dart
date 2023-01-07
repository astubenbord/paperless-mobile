import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/widgets/highlighted_text.dart';
import 'package:paperless_mobile/core/widgets/offline_widget.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/document_details/bloc/document_details_cubit.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_download_button.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_edit_page.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_view.dart';
import 'package:paperless_mobile/features/documents/view/widgets/delete_document_confirmation_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/edit_document/cubit/edit_document_cubit.dart';
import 'package:paperless_mobile/features/labels/correspondent/view/widgets/correspondent_widget.dart';
import 'package:paperless_mobile/features/labels/document_type/view/widgets/document_type_widget.dart';
import 'package:paperless_mobile/features/labels/storage_path/view/widgets/storage_path_widget.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DocumentDetailsPage extends StatefulWidget {
  final bool allowEdit;
  final bool isLabelClickable;
  final String? titleAndContentQueryString;

  const DocumentDetailsPage({
    Key? key,
    this.isLabelClickable = true,
    this.titleAndContentQueryString,
    this.allowEdit = true,
  }) : super(key: key);

  @override
  State<DocumentDetailsPage> createState() => _DocumentDetailsPageState();
}

class _DocumentDetailsPageState extends State<DocumentDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context)
            .pop(context.read<DocumentDetailsCubit>().state.document);
        return false;
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
          floatingActionButton: widget.allowEdit
              ? BlocBuilder<DocumentDetailsCubit, DocumentDetailsState>(
                  builder: (context, state) {
                    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
                      builder: (context, connectivityState) {
                        if (!connectivityState.isConnected) {
                          return Container();
                        }
                        return FloatingActionButton(
                          child: const Icon(Icons.edit),
                          onPressed: () => _onEdit(state.document),
                        );
                      },
                    );
                  },
                )
              : null,
          bottomNavigationBar:
              BlocBuilder<DocumentDetailsCubit, DocumentDetailsState>(
            builder: (context, state) {
              return BottomAppBar(
                child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
                  builder: (context, connectivityState) {
                    final isConnected = connectivityState.isConnected;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: widget.allowEdit && isConnected
                              ? () => _onDelete(state.document)
                              : null,
                        ).paddedSymmetrically(horizontal: 4),
                        DocumentDownloadButton(
                          document: state.document,
                          enabled: isConnected,
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: isConnected
                              ? () => _onOpen(state.document)
                              : null,
                        ).paddedOnly(right: 4.0),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: isConnected
                              ? () => _onShare(state.document)
                              : null,
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors
                        .black, //TODO: check if there is a way to dynamically determine color...
                  ),
                  onPressed: () => Navigator.of(context).pop(
                    context.read<DocumentDetailsCubit>().state.document,
                  ),
                ),
                floating: true,
                pinned: true,
                expandedHeight: 200.0,
                flexibleSpace:
                    BlocBuilder<DocumentDetailsCubit, DocumentDetailsState>(
                  builder: (context, state) => DocumentPreview(
                    id: state.document.id,
                    fit: BoxFit.cover,
                  ),
                ),
                bottom: ColoredTabBar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  tabBar: TabBar(
                    tabs: [
                      Tab(
                        child: Text(
                          S.of(context).documentDetailsPageTabOverviewLabel,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer),
                        ),
                      ),
                      Tab(
                        child: Text(
                          S.of(context).documentDetailsPageTabContentLabel,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer),
                        ),
                      ),
                      Tab(
                        child: Text(
                          S.of(context).documentDetailsPageTabMetaDataLabel,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            body: BlocBuilder<DocumentDetailsCubit, DocumentDetailsState>(
              builder: (context, state) {
                return TabBarView(
                  children: [
                    _buildDocumentOverview(
                      state.document,
                      widget.titleAndContentQueryString,
                    ),
                    _buildDocumentContentView(
                      state.document,
                      widget.titleAndContentQueryString,
                    ),
                    _buildDocumentMetaDataView(
                      state.document,
                    ),
                  ].padded(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onEdit(DocumentModel document) async {
    {
      final cubit = context.read<DocumentDetailsCubit>();
      Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: EditDocumentCubit(
              document,
              documentsApi: context.read(),
              correspondentRepository: context.read(),
              documentTypeRepository: context.read(),
              storagePathRepository: context.read(),
              tagRepository: context.read(),
            ),
            child: BlocListener<EditDocumentCubit, EditDocumentState>(
              listenWhen: (previous, current) =>
                  previous.document != current.document,
              listener: (context, state) {
                cubit.replaceDocument(state.document);
              },
              child: const DocumentEditPage(),
            ),
          ),
          maintainState: true,
        ),
      );
    }
  }

  Widget _buildDocumentMetaDataView(DocumentModel document) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        if (!state.isConnected) {
          return const Center(
            child: OfflineWidget(),
          );
        }
        return FutureBuilder<DocumentMetaData>(
          future: context.read<PaperlessDocumentsApi>().getMetaData(document),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final meta = snapshot.data!;
            return ListView(
              children: [
                _DetailsItem.text(DateFormat().format(document.modified),
                        label: S.of(context).documentModifiedPropertyLabel,
                        context: context)
                    .paddedOnly(bottom: 16),
                _DetailsItem.text(DateFormat().format(document.added),
                        label: S.of(context).documentAddedPropertyLabel,
                        context: context)
                    .paddedSymmetrically(vertical: 16),
                _DetailsItem(
                  label: S
                      .of(context)
                      .documentArchiveSerialNumberPropertyLongLabel,
                  content: document.archiveSerialNumber != null
                      ? Text(document.archiveSerialNumber.toString())
                      : OutlinedButton(
                          child: Text(S
                              .of(context)
                              .documentDetailsPageAssignAsnButtonLabel),
                          onPressed: widget.allowEdit
                              ? () => _assignAsn(document)
                              : null,
                        ),
                ).paddedSymmetrically(vertical: 16),
                _DetailsItem.text(
                  meta.mediaFilename,
                  context: context,
                  label:
                      S.of(context).documentMetaDataMediaFilenamePropertyLabel,
                ).paddedSymmetrically(vertical: 16),
                _DetailsItem.text(
                  meta.originalChecksum,
                  context: context,
                  label: S.of(context).documentMetaDataChecksumLabel,
                ).paddedSymmetrically(vertical: 16),
                _DetailsItem.text(formatBytes(meta.originalSize, 2),
                        label:
                            S.of(context).documentMetaDataOriginalFileSizeLabel,
                        context: context)
                    .paddedSymmetrically(vertical: 16),
                _DetailsItem.text(
                  meta.originalMimeType,
                  label: S.of(context).documentMetaDataOriginalMimeTypeLabel,
                  context: context,
                ).paddedSymmetrically(vertical: 16),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _assignAsn(DocumentModel document) async {
    try {
      await context.read<DocumentDetailsCubit>().assignAsn(document);
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  Widget _buildDocumentContentView(DocumentModel document, String? match) {
    return SingleChildScrollView(
      child: HighlightedText(
        text: document.content ?? "",
        highlights: match == null ? [] : match.split(" "),
        style: Theme.of(context).textTheme.bodyMedium,
        caseSensitive: false,
      ),
    ).paddedOnly(top: 8);
  }

  Widget _buildDocumentOverview(DocumentModel document, String? match) {
    return ListView(
      children: [
        _DetailsItem(
          content: HighlightedText(
            text: document.title,
            highlights: match?.split(" ") ?? <String>[],
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          label: S.of(context).documentTitlePropertyLabel,
        ).paddedOnly(bottom: 16),
        _DetailsItem.text(
          DateFormat.yMMMd().format(document.created),
          context: context,
          label: S.of(context).documentCreatedPropertyLabel,
        ).paddedSymmetrically(vertical: 16),
        Visibility(
          visible: document.documentType != null,
          child: _DetailsItem(
            content: DocumentTypeWidget(
              textStyle: Theme.of(context).textTheme.bodyLarge,
              isClickable: widget.isLabelClickable,
              documentTypeId: document.documentType,
            ),
            label: S.of(context).documentDocumentTypePropertyLabel,
          ).paddedSymmetrically(vertical: 16),
        ),
        Visibility(
          visible: document.correspondent != null,
          child: _DetailsItem(
            label: S.of(context).documentCorrespondentPropertyLabel,
            content: CorrespondentWidget(
              textStyle: Theme.of(context).textTheme.bodyLarge,
              isClickable: widget.isLabelClickable,
              correspondentId: document.correspondent,
            ),
          ).paddedSymmetrically(vertical: 16),
        ),
        Visibility(
          visible: document.storagePath != null,
          child: _DetailsItem(
            label: S.of(context).documentStoragePathPropertyLabel,
            content: StoragePathWidget(
              isClickable: widget.isLabelClickable,
              pathId: document.storagePath,
            ),
          ).paddedSymmetrically(vertical: 16),
        ),
        Visibility(
          visible: document.tags.isNotEmpty,
          child: _DetailsItem(
            label: S.of(context).documentTagsPropertyLabel,
            content: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TagsWidget(
                isClickable: widget.isLabelClickable,
                tagIds: document.tags,
                isSelectedPredicate: (_) => false,
                onTagSelected: (int tagId) {},
              ),
            ),
          ).paddedSymmetrically(vertical: 16),
        ),
        // _separator(),
        // FutureBuilder<List<SimilarDocumentModel>>(
        //     future: getIt<DocumentRepository>().findSimilar(document.id),
        //     builder: (context, snapshot) {
        //       if (!snapshot.hasData) {
        //         return CircularProgressIndicator();
        //       }
        //       return ExpansionTile(
        //         tilePadding: const EdgeInsets.symmetric(horizontal: 8.0),
        //         title: Text(
        //           S.of(context).documentDetailsPageSimilarDocumentsLabel,
        //           style:
        //               Theme.of(context).textTheme.headline5?.copyWith(fontWeight: FontWeight.bold),
        //         ),
        //         children: snapshot.data!
        //             .map((e) => DocumentListItem(
        //                 document: e,
        //                 onTap: (doc) {},
        //                 isSelected: false,
        //                 isAtLeastOneSelected: false))
        //             .toList(),
        //       );
        //     }),
      ],
    );
  }

  ///
  /// Downloads file to temporary directory, from which it can then be shared.
  ///
  Future<void> _onShare(DocumentModel document) async {
    Uint8List documentBytes =
        await context.read<PaperlessDocumentsApi>().download(document);
    final dir = await getTemporaryDirectory();
    final String path = "${dir.path}/${document.originalFileName}";
    await File(path).writeAsBytes(documentBytes);
    Share.shareXFiles(
      [
        XFile(
          path,
          name: document.originalFileName,
          mimeType: "application/pdf",
          lastModified: document.modified,
        )
      ],
      subject: document.title,
    );
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
        await context.read<DocumentDetailsCubit>().delete(document);
        showSnackBar(context, S.of(context).documentDeleteSuccessMessage);
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      } finally {
        // Document deleted => go back to primary route
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  Future<void> _onOpen(DocumentModel document) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentView(
          documentBytes:
              context.read<PaperlessDocumentsApi>().getPreview(document.id),
        ),
      ),
    );
  }

  static String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) +
        ' ' +
        suffixes[i];
  }
}

class _DetailsItem extends StatelessWidget {
  final String label;
  final Widget content;
  const _DetailsItem({Key? key, required this.label, required this.content})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          content,
        ],
      ),
    );
  }

  _DetailsItem.text(
    String text, {
    required this.label,
    required BuildContext context,
  }) : content = Text(text, style: Theme.of(context).textTheme.bodyLarge);
}

class ColoredTabBar extends Container implements PreferredSizeWidget {
  ColoredTabBar({
    super.key,
    required this.backgroundColor,
    required this.tabBar,
  });

  final TabBar tabBar;
  final Color backgroundColor;
  @override
  Size get preferredSize => tabBar.preferredSize;

  @override
  Widget build(BuildContext context) => Container(
        color: backgroundColor,
        child: tabBar,
      );
}
