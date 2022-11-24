import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:paperless_mobile/core/bloc/paperless_statistics_cubit.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/widgets/documents_list_loading_widget.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/inbox/bloc/inbox_cubit.dart';
import 'package:paperless_mobile/features/inbox/bloc/state/inbox_state.dart';
import 'package:paperless_mobile/features/inbox/view/widgets/document_inbox_item.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<InboxCubit>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).bottomNavInboxPageLabel),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: BlocBuilder<InboxCubit, InboxState>(
        builder: (context, state) {
          return FloatingActionButton.extended(
            label: Text("Mark all as seen"),
            icon: const Icon(Icons.done_all),
            onPressed: state.isLoaded && state.inboxItems.isNotEmpty
                ? () => _onMarkAllAsSeen(
                      bloc.state.inboxItems,
                      bloc.state.inboxTags,
                    )
                : null,
          );
        },
      ),
      body: BlocBuilder<InboxCubit, InboxState>(
        builder: (context, state) {
          if (!state.isLoaded) {
            return const DocumentsListLoadingWidget();
          }

          if (state.inboxItems.isEmpty) {
            return Text(
              "You do not have new documents in your inbox.",
              textAlign: TextAlign.center,
            ).padded();
          }
          return RefreshIndicator(
            onRefresh: () => BlocProvider.of<InboxCubit>(context).reloadInbox(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Hint: Swipe left to mark a document as seen. This will remove all inbox tags from the document.', //TODO: INTL
                  textAlign: TextAlign.center,
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
                    initialItemCount: state.inboxItems.length,
                    itemBuilder: (context, index, animation) {
                      final doc = state.inboxItems.elementAt(index);
                      return _buildListItem(context, doc);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
      child: DocumentInboxItem(document: doc),
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
    Iterable<DocumentModel> documents,
    Iterable<int> inboxTags,
  ) async {
    for (int i = documents.length - 1; i >= 0; i--) {
      final doc = documents.elementAt(i);
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
      final removedTags =
          await BlocProvider.of<InboxCubit>(context).remove(doc);
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
    DocumentModel document,
    Iterable<int> removedTags,
  ) async {
    try {
      await BlocProvider.of<InboxCubit>(context)
          .undoRemove(document, removedTags);
      BlocProvider.of<PaperlessStatisticsCubit>(context).incrementInboxCount();
    } on ErrorMessage catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
