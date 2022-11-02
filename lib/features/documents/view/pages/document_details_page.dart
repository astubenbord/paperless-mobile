import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/bloc/label_bloc_provider.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/widgets/highlighted_text.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/model/document_meta_data.model.dart';
import 'package:paperless_mobile/features/documents/repository/document_repository.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_edit_page.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_view.dart';
import 'package:paperless_mobile/features/documents/view/widgets/delete_document_confirmation_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/labels/correspondent/view/widgets/correspondent_widget.dart';
import 'package:paperless_mobile/features/labels/document_type/view/widgets/document_type_widget.dart';
import 'package:paperless_mobile/features/labels/storage_path/view/widgets/storage_path_widget.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DocumentDetailsPage extends StatefulWidget {
  final int documentId;
  const DocumentDetailsPage({
    Key? key,
    required this.documentId,
  }) : super(key: key);

  @override
  State<DocumentDetailsPage> createState() => _DocumentDetailsPageState();
}

class _DocumentDetailsPageState extends State<DocumentDetailsPage> {
  static final DateFormat _detailedDateFormat = DateFormat("MMM d, yyyy HH:mm:ss");

  bool _isDownloadPending = false;
  bool _isAssignAsnPending = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentsCubit, DocumentsState>(
      // buildWhen required because rebuild would happen after delete causing error.
      buildWhen: (previous, current) {
        return current.documents.where((element) => element.id == widget.documentId).isNotEmpty;
      },
      builder: (context, state) {
        final document = state.documents.where((doc) => doc.id == widget.documentId).first;
        return SafeArea(
          bottom: true,
          child: DefaultTabController(
            length: 3,
            child: Scaffold(
              floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.edit),
                onPressed: () => _onEdit(document),
              ),
              bottomNavigationBar: BottomAppBar(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _onDelete(document),
                    ).padded(const EdgeInsets.symmetric(horizontal: 8.0)),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: Platform.isAndroid ? () => _onDownload(document) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _onOpen(document),
                    ).padded(const EdgeInsets.symmetric(horizontal: 8.0)),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _onShare(document),
                    ),
                  ],
                ),
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    floating: true,
                    pinned: true,
                    expandedHeight: 200.0,
                    flexibleSpace: DocumentPreview(
                      id: document.id,
                      fit: BoxFit.cover,
                    ),
                    bottom: ColoredTabBar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      tabBar: TabBar(
                        tabs: [
                          Tab(
                            child: Text(
                              S.of(context).documentDetailsPageTabOverviewLabel,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer),
                            ),
                          ),
                          Tab(
                            child: Text(
                              S.of(context).documentDetailsPageTabContentLabel,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer),
                            ),
                          ),
                          Tab(
                            child: Text(
                              S.of(context).documentDetailsPageTabMetaDataLabel,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  children: [
                    _buildDocumentOverview(document, state.filter.titleAndContentMatchString),
                    _buildDocumentContentView(document, state.filter.titleAndContentMatchString),
                    _buildDocumentMetaDataView(document),
                  ].padded(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentMetaDataView(DocumentModel document) {
    return FutureBuilder<DocumentMetaData>(
      future: getIt<DocumentRepository>().getMetaData(document),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final meta = snapshot.data!;
        return ListView(
          children: [
            _DetailsItem.text(_detailedDateFormat.format(document.modified),
                label: S.of(context).documentModifiedPropertyLabel, context: context),
            _separator(),
            _DetailsItem.text(_detailedDateFormat.format(document.added),
                label: S.of(context).documentAddedPropertyLabel, context: context),
            _separator(),
            _DetailsItem(
              label: S.of(context).documentArchiveSerialNumberPropertyLongLabel,
              content: document.archiveSerialNumber != null
                  ? Text(document.archiveSerialNumber.toString())
                  : OutlinedButton(
                      child: Text(S.of(context).documentDetailsPageAssignAsnButtonLabel),
                      onPressed: () => BlocProvider.of<DocumentsCubit>(context).assignAsn(document),
                    ),
            ),
            _separator(),
            _DetailsItem.text(
              meta.mediaFilename,
              context: context,
              label: S.of(context).documentMetaDataMediaFilenamePropertyLabel,
            ),
            _separator(),
            _DetailsItem.text(
              meta.originalChecksum,
              context: context,
              label: S.of(context).documentMetaDataChecksumLabel,
            ),
            _separator(),
            _DetailsItem.text(formatBytes(meta.originalSize, 2),
                label: S.of(context).documentMetaDataOriginalFileSizeLabel, context: context),
            _separator(),
            _DetailsItem.text(
              meta.originalMimeType,
              label: S.of(context).documentMetaDataOriginalMimeTypeLabel,
              context: context,
            ),
            _separator(),
          ],
        );
      },
    );
  }

  Widget _buildDocumentContentView(DocumentModel document, String? match) {
    return SingleChildScrollView(
      child: _DetailsItem(
        content: HighlightedText(
          text: document.content ?? "",
          highlights: match == null ? [] : match.split(" "),
          style: Theme.of(context).textTheme.bodyText2,
          caseSensitive: false,
        ),
        label: S.of(context).documentDetailsPageTabContentLabel,
      ),
    );
  }

  Widget _buildDocumentOverview(DocumentModel document, String? match) {
    return ListView(
      children: [
        _DetailsItem(
          content: HighlightedText(
            text: document.title,
            highlights: match?.split(" ") ?? <String>[],
          ),
          label: S.of(context).documentTitlePropertyLabel,
        ),
        _separator(),
        _DetailsItem.text(
          DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
              .format(document.created),
          context: context,
          label: S.of(context).documentCreatedPropertyLabel,
        ),
        _separator(),
        _DetailsItem(
          content: DocumentTypeWidget(
            documentTypeId: document.documentType,
            afterSelected: () {
              Navigator.pop(context);
            },
          ),
          label: S.of(context).documentDocumentTypePropertyLabel,
        ),
        _separator(),
        _DetailsItem(
          label: S.of(context).documentCorrespondentPropertyLabel,
          content: CorrespondentWidget(
            correspondentId: document.correspondent,
            afterSelected: () {
              Navigator.pop(context);
            },
          ),
        ),
        _separator(),
        _DetailsItem(
          label: S.of(context).documentStoragePathPropertyLabel,
          content: StoragePathWidget(
            pathId: document.storagePath,
            afterSelected: () {
              Navigator.pop(context);
            },
          ),
        ),
        _separator(),
        _DetailsItem(
          label: S.of(context).documentTagsPropertyLabel,
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TagsWidget(
              tagIds: document.tags,
            ),
          ),
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

  Widget _separator() {
    return const SizedBox(height: 32.0);
  }

  void _onEdit(DocumentModel document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LabelBlocProvider(
          child: DocumentEditPage(document: document),
        ),
        maintainState: true,
      ),
    );
  }

  Future<void> _onDownload(DocumentModel document) async {
    if (!Platform.isAndroid) {
      showSnackBar(context, "This feature is currently only supported on Android!");
      return;
    }
    setState(() => _isDownloadPending = true);
    getIt<DocumentRepository>().download(document).then((bytes) async {
      final Directory dir =
          (await getExternalStorageDirectories(type: StorageDirectory.downloads))!.first;
      String filePath = "${dir.path}/${document.originalFileName}";
      //TODO: Add replacement mechanism here (ask user if file should be replaced if exists)
      await File(filePath).writeAsBytes(bytes);
      setState(() => _isDownloadPending = false);
      dev.log("File downloaded to $filePath");
    });
  }

  ///
  /// Downloads file to temporary directory, from which it can then be shared.
  ///
  Future<void> _onShare(DocumentModel document) async {
    Uint8List documentBytes = await getIt<DocumentRepository>().download(document);
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

  Future<void> _onDelete(DocumentModel document) async {
    showDialog(
        context: context,
        builder: (context) => DeleteDocumentConfirmationDialog(document: document)).then((delete) {
      if (delete ?? false) {
        BlocProvider.of<DocumentsCubit>(context).removeDocument(document).then((value) {
          Navigator.pop(context);
          showSnackBar(context, S.of(context).documentDeleteSuccessMessage);
        }).onError<ErrorMessage>((error, _) {
          showSnackBar(context, translateError(context, error.code));
        });
      }
    });
  }

  Future<void> _onOpen(DocumentModel document) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentView(document: document),
      ),
    );
  }

  static String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
  }
}

class _DetailsItem extends StatelessWidget {
  final String label;
  final Widget content;
  const _DetailsItem({Key? key, required this.label, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.headline5?.copyWith(fontWeight: FontWeight.bold),
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
  }) : content = Text(text, style: Theme.of(context).textTheme.bodyText2);
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
