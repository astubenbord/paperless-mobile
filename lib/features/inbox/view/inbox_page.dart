import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:paperless_mobile/core/bloc/paperless_statistics_cubit.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/model/paperless_statistics_state.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/tags_query.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_details_page.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/labels/bloc/label_bloc_provider.dart';
import 'package:paperless_mobile/features/labels/tags/bloc/tags_cubit.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  static const _a4AspectRatio = 1 / 1.4142;

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  Iterable<int> _inboxTags = [];
  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _initInbox();
  }

  Future<void> _initInbox() async {
    final tags = BlocProvider.of<TagCubit>(context).state.labels;
    log("Loading documents with tags...${tags.values.join(",")}");
    _inboxTags =
        tags.values.where((t) => t.isInboxTag ?? false).map((t) => t.id!);
    final filter =
        DocumentFilter(tags: AnyAssignedTagsQuery(tagIds: _inboxTags));
    return BlocProvider.of<DocumentsCubit>(context).updateFilter(
      filter: filter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentsCubit, DocumentsState>(
      builder: (context, documentState) {
        return Scaffold(
          appBar: AppBar(
            title:
                BlocBuilder<PaperlessStatisticsCubit, PaperlessStatisticsState>(
              builder: (context, state) {
                return Text(
                  S.of(context).bottomNavInboxPageLabel +
                      (state.isLoaded
                          ? ' (${state.statistics!.documentsInInbox})'
                          : ''),
                );
              },
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          floatingActionButton: documentState.documents.isNotEmpty
              ? FloatingActionButton.extended(
                  label: Text("Mark all as seen"),
                  icon: const Icon(Icons.done_all),
                  onPressed: () =>
                      _onMarkAllAsSeen(documentState.documents, _inboxTags),
                )
              : null,
          body: Builder(
            builder: (context) {
              if (!documentState.isLoaded) {
                return const Center(child: CircularProgressIndicator());
              }
              if (documentState.documents.isEmpty) {
                return Text(
                  "You do not have new documents in your inbox.",
                  textAlign: TextAlign.center,
                ) // TODO: INTL
                    .padded();
              }
              return Column(
                children: [
                  Text(
                    'Hint: Swipe left to mark a document as read. This will remove all inbox tags from the document.', //TODO: INTL
                    style: Theme.of(context).textTheme.caption,
                  ).padded(
                    const EdgeInsets.only(
                      top: 4.0,
                      left: 8.0,
                      right: 8.0,
                      bottom: 8.0,
                    ),
                  ),
                  Expanded(
                    child: AnimatedList(
                      key: _listKey,
                      initialItemCount: documentState.documents.length,
                      itemBuilder: (context, index, animation) {
                        final doc = documentState.documents[index];
                        return _buildListItem(context, doc);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildListItem(BuildContext context, DocumentModel doc) {
    return Dismissible(
      direction: DismissDirection.endToStart,
      background: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.done,
            color: Theme.of(context).colorScheme.primary,
          ).padded(),
          Text(
            'Mark as read', //TODO: INTL
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ).padded(),
      confirmDismiss: (_) => _onItemDismissed(doc),
      key: ObjectKey(doc.id),
      child: ListTile(
        title: Text(doc.title),
        isThreeLine: true,
        leading: AspectRatio(
          aspectRatio: _a4AspectRatio,
          child: DocumentPreview(
            id: doc.id,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat().format(doc.added)),
            TagsWidget(tagIds: doc.tags.where((id) => _inboxTags.contains(id)))
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LabelBlocProvider(
              child: BlocProvider.value(
                value: BlocProvider.of<DocumentsCubit>(context),
                child: DocumentDetailsPage(
                  documentId: doc.id,
                  allowEdit: false,
                  isLabelClickable: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideAnimation(
    BuildContext context,
    animation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  Future<void> _onMarkAllAsSeen(
    List<DocumentModel> documents,
    Iterable<int> inboxTags,
  ) async {
    for (int i = documents.length - 1; i >= 0; i--) {
      final doc = documents[i];
      _listKey.currentState?.removeItem(
        0,
        (context, animation) => _buildSlideAnimation(
          context,
          animation,
          _buildListItem(context, doc),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 75));
    }
    await BlocProvider.of<DocumentsCubit>(context)
        .bulkEditTags(documents, removeTags: inboxTags);
    BlocProvider.of<PaperlessStatisticsCubit>(context).resetInboxCount();
  }

  Future<bool> _onItemDismissed(DocumentModel doc) async {
    try {
      final removedTags = await BlocProvider.of<DocumentsCubit>(context)
          .removeInboxTags(doc, _inboxTags);
      BlocProvider.of<PaperlessStatisticsCubit>(context).decrementInboxCount();
      showSnackBar(
        context,
        'Document removed from inbox.', //TODO: INTL
        action: SnackBarAction(
          label: 'UNDO', //TODO: INTL
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: () => _onUndoMarkAsSeen(doc, removedTags),
        ),
      );
      return true;
    } on ErrorMessage catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
      return false;
    } catch (error) {
      showErrorMessage(
        context,
        const ErrorMessage.unknown(),
      );
      return false;
    }
  }

  Future<void> _onUndoMarkAsSeen(
      DocumentModel doc, Iterable<int> removedTags) async {
    try {
      await BlocProvider.of<DocumentsCubit>(context).updateDocument(
        doc.copyWith(
          tags: {...doc.tags, ...removedTags},
          overwriteTags: true,
        ),
      );
      BlocProvider.of<PaperlessStatisticsCubit>(context).incrementInboxCount();
      BlocProvider.of<DocumentsCubit>(context).reloadDocuments();
    } on ErrorMessage catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
