import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/widgets/documents_list_loading_widget.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/inbox/bloc/inbox_cubit.dart';
import 'package:paperless_mobile/features/inbox/bloc/state/inbox_state.dart';
import 'package:paperless_mobile/features/inbox/view/widgets/inbox_item.dart';
import 'package:paperless_mobile/features/inbox/view/widgets/inbox_empty_widget.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:collection/collection.dart';
import 'package:paperless_mobile/extensions/dart_extensions.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).bottomNavInboxPageLabel),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(14),
          child: BlocBuilder<InboxCubit, InboxState>(
            builder: (context, state) {
              return Align(
                alignment: Alignment.centerRight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Text(
                      '${state.inboxItems.length} ${S.of(context).inboxPageUnseenText}',
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
          if (!state.isLoaded || state.inboxItems.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            label: Text(S.of(context).inboxPageMarkAllAsSeenLabel),
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
            return InboxEmptyWidget(
              emptyStateRefreshIndicatorKey: _emptyStateRefreshIndicatorKey,
            );
          }

          // Build a list of slivers alternating between SliverToBoxAdapter
          // (group header) and a SliverList (inbox items).
          final List<Widget> slivers = _groupByDate(state.inboxItems)
              .entries
              .map(
                (entry) => [
                  SliverToBoxAdapter(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32.0),
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.caption,
                          textAlign: TextAlign.center,
                        ).padded(),
                      ),
                    ).padded(const EdgeInsets.only(top: 8.0)),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: entry.value.length,
                      (context, index) => _buildListItem(
                        context,
                        entry.value[index],
                      ),
                    ),
                  ),
                ],
              )
              .flattened
              .toList();

          return RefreshIndicator(
            onRefresh: () => BlocProvider.of<InboxCubit>(context).loadInbox(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Text(
                          S.of(context).inboxPageUsageHintText,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.caption,
                        ).padded(
                          const EdgeInsets.only(
                            top: 8.0,
                            left: 8.0,
                            right: 8.0,
                            bottom: 8.0,
                          ),
                        ),
                      ),
                      ...slivers
                    ],
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
            S.of(context).inboxPageMarkAsSeenText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ).padded(),
      confirmDismiss: (_) => _onItemDismissed(doc),
      key: UniqueKey(),
      child: InboxItem(document: doc),
    );
  }

  Future<void> _onMarkAllAsSeen(
    Iterable<DocumentModel> documents,
    Iterable<int> inboxTags,
  ) async {
    final isActionConfirmed = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(S
                .of(context)
                .inboxPageMarkAllAsSeenConfirmationDialogTitleText),
            content: Text(
              S.of(context).inboxPageMarkAllAsSeenConfirmationDialogText,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(S.of(context).genericActionCancelLabel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  S.of(context).genericActionOkLabel,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
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
        S.of(context).inboxPageDocumentRemovedMessageText,
        action: SnackBarAction(
          label: S.of(context).inboxPageUndoRemoveText,
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

  Map<String, List<DocumentModel>> _groupByDate(
    Iterable<DocumentModel> documents,
  ) {
    return groupBy<DocumentModel, String>(
      documents,
      (doc) {
        if (doc.added.isToday) {
          return S.of(context).inboxPageTodayText;
        }
        if (doc.added.isYesterday) {
          return S.of(context).inboxPageYesterdayText;
        }
        return DateFormat.yMMMMd().format(doc.added);
      },
    );
  }
}
