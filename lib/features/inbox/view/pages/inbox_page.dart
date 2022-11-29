import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/widgets/documents_list_loading_widget.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
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
  final GlobalKey<RefreshIndicatorState> _emptyStateRefreshIndicatorKey =
      GlobalKey();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
  }

  @override
  Widget build(BuildContext context) {
    //TODO: Group by date (today, yseterday, etc.)
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).bottomNavInboxPageLabel),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(14),
          child: BlocBuilder<InboxCubit, InboxState>(
            builder: (context, state) {
              return Align(
                alignment: Alignment.centerRight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Text(
                      '${state.inboxItems.length} unseen',
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.caption,
                    ).padded(const EdgeInsets.symmetric(horizontal: 4.0)),
                  ),
                ),
              );
            },
          ).padded(const EdgeInsets.symmetric(horizontal: 8.0)),
        ),
      ),
      floatingActionButton: BlocBuilder<InboxCubit, InboxState>(
        builder: (context, state) {
          return FloatingActionButton.extended(
            label: Text("Mark all as seen"),
            icon: const Icon(Icons.done_all),
            onPressed: state.isLoaded && state.inboxItems.isNotEmpty
                ? () => _onMarkAllAsSeen(
                      state.inboxItems,
                      state.inboxTags,
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
            return RefreshIndicator(
              key: _emptyStateRefreshIndicatorKey,
              onRefresh: () =>
                  BlocProvider.of<InboxCubit>(context).reloadInbox(),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('You do not have unseen documents.'),
                    TextButton(
                      onPressed: () =>
                          _emptyStateRefreshIndicatorKey.currentState?.show(),
                      child: Text('Refresh'),
                    ),
                  ],
                ),
              ),
            );
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
                  child: ListView.builder(
                    itemCount: state.inboxItems.length,
                    itemBuilder: (context, index) {
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
            Icons.done_all,
            color: Theme.of(context).colorScheme.primary,
          ).padded(),
          Text(
            'Mark as seen', //TODO: INTL
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ).padded(),
      confirmDismiss: (_) => _onItemDismissed(doc),
      key: UniqueKey(),
      child: DocumentInboxItem(document: doc),
    );
  }

  Future<void> _onMarkAllAsSeen(
    Iterable<DocumentModel> documents,
    Iterable<int> inboxTags,
  ) async {
    final isActionConfirmed = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm action'),
            content: Text(
              'Are you sure you want to mark all documents as seen? This will perform a bulk edit operation removing all inbox tags from the documents.\nThis action is not reversible! Are you sure you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(S.of(context).genericActionCancelLabel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(S.of(context).genericActionOkLabel),
              ),
            ],
          ),
        ) ??
        false;
    if (isActionConfirmed) {
      await BlocProvider.of<InboxCubit>(context).clearInbox();
    }
  }

  Future<bool> _onItemDismissed(DocumentModel doc) async {
    try {
      final removedTags =
          await BlocProvider.of<InboxCubit>(context).remove(doc);
      showSnackBar(
        context,
        'Document removed from inbox.', //TODO: INTL
        action: SnackBarAction(
          label: 'UNDO', //TODO: INTL
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
    } on ErrorMessage catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
