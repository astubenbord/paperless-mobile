import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/model/server_message_exception.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_cancel_button.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_confirm_button.dart';
import 'package:paperless_mobile/core/widgets/hint_card.dart';
import 'package:paperless_mobile/core/extensions/dart_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/app_drawer/view/app_drawer.dart';
import 'package:paperless_mobile/features/document_search/view/sliver_search_bar.dart';
import 'package:paperless_mobile/features/inbox/cubit/inbox_cubit.dart';
import 'package:paperless_mobile/features/inbox/view/widgets/inbox_empty_widget.dart';
import 'package:paperless_mobile/features/inbox/view/widgets/inbox_item.dart';
import 'package:paperless_mobile/core/paging/view/document_paging_view_mixin.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/core/widgets/connectivity_aware_action_wrapper.dart';
import 'package:paperless_mobile/core/util/message_helpers.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage>
    with DocumentPagingViewMixin<InboxPage, InboxCubit> {
  final SliverOverlapAbsorberHandle searchBarHandle =
      SliverOverlapAbsorberHandle();

  @override
  final pagingScrollController = ScrollController();
  final _nestedScrollViewKey = GlobalKey<NestedScrollViewState>();
  final _emptyStateRefreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _scrollController = ScrollController();
  bool _showExtendedFab = true;
  @override
  void initState() {
    super.initState();
    context.read<InboxCubit>().reloadInbox();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nestedScrollViewKey.currentState!.innerController
          .addListener(_scrollExtentChangedListener);
    });
  }

  @override
  void dispose() {
    _nestedScrollViewKey.currentState?.innerController
        .removeListener(_scrollExtentChangedListener);
    super.dispose();
  }

  void _scrollExtentChangedListener() {
    const threshold = 400;
    final offset =
        _nestedScrollViewKey.currentState!.innerController.position.pixels;
    if (offset < threshold && _showExtendedFab == false) {
      setState(() {
        _showExtendedFab = true;
      });
    } else if (offset >= threshold && _showExtendedFab == true) {
      setState(() {
        _showExtendedFab = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEditDocument =
        context.watch<LocalUserAccount>().paperlessUser.canEditDocuments;
    return Scaffold(
      drawer: const AppDrawer(),
      floatingActionButton: ConnectivityAwareActionWrapper(
        offlineBuilder: (context, child) => const SizedBox.shrink(),
        child: BlocBuilder<InboxCubit, InboxState>(
          builder: (context, state) {
            if (!state.hasLoaded ||
                state.documents.isEmpty ||
                !canEditDocument) {
              return const SizedBox.shrink();
            }
            return FloatingActionButton.extended(
              extendedPadding: _showExtendedFab
                  ? null
                  : const EdgeInsets.symmetric(horizontal: 16),
              heroTag: "inbox_page_fab",
              label: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.horizontal,
                      child: child,
                    ),
                  );
                },
                child: _showExtendedFab
                    ? Row(
                        children: [
                          const Icon(Icons.done_all),
                          Text(S.of(context)!.allSeen),
                        ],
                      )
                    : const Icon(Icons.done_all),
              ),
              onPressed: state.hasLoaded && state.documents.isNotEmpty
                  ? () => _onMarkAllAsSeen(
                        state.documents,
                        state.inboxTags,
                      )
                  : null,
            );
          },
        ),
      ),
      body: SafeArea(
        top: true,
        child: NestedScrollView(
          key: _nestedScrollViewKey,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverSearchBar(titleText: S.of(context)!.inbox),
          ],
          body: BlocBuilder<InboxCubit, InboxState>(
            builder: (_, state) {
              if (state.documents.isEmpty && state.hasLoaded) {
                return Center(
                  child: InboxEmptyWidget(
                    emptyStateRefreshIndicatorKey:
                        _emptyStateRefreshIndicatorKey,
                  ),
                );
              } else if (state.isLoading) {
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 16, left: 16),
                  controller: _scrollController,
                  itemBuilder: (context, index) {
                    return const InboxItemPlaceholder();
                  },
                );
              } else {
                return RefreshIndicator(
                  onRefresh: context.read<InboxCubit>().reload,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: HintCard(
                          show: !state.isHintAcknowledged,
                          hintText:
                              S.of(context)!.swipeLeftToMarkADocumentAsSeen,
                          onHintAcknowledged: () =>
                              context.read<InboxCubit>().acknowledgeHint(),
                        ),
                      ),
                      // Build a list of slivers alternating between SliverToBoxAdapter
                      // (group header) and a SliverList (inbox items).
                      ..._groupByDate(state.documents)
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
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      textAlign: TextAlign.center,
                                    ).padded(),
                                  ),
                                ).paddedOnly(top: 8.0),
                              ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  childCount: entry.value.length,
                                  (context, index) {
                                    if (index < entry.value.length - 1) {
                                      return Column(
                                        children: [
                                          _buildListItem(
                                            entry.value[index],
                                          ),
                                          const Divider(
                                            indent: 16,
                                            endIndent: 16,
                                          ),
                                        ],
                                      );
                                    }
                                    return _buildListItem(
                                      entry.value[index],
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                          .flattened,
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 78),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(DocumentModel doc) {
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
            S.of(context)!.markAsSeen,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ).padded(),
      confirmDismiss: (_) => _onItemDismissed(doc),
      key: ValueKey(doc.id),
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
            title: Text(S.of(context)!.markAllAsSeen),
            content: Text(
              S.of(context)!.areYouSureYouWantToMarkAllDocumentsAsSeen,
            ),
            actions: [
              const DialogCancelButton(),
              DialogConfirmButton(
                label: S.of(context)!.markAsSeen,
                style: DialogConfirmButtonStyle.danger,
              ),
            ],
          ),
        ) ??
        false;
    if (isActionConfirmed && mounted) {
      await context.read<InboxCubit>().clearInbox();
    }
  }

  Future<bool> _onItemDismissed(DocumentModel doc) async {
    if (!context.read<LocalUserAccount>().paperlessUser.canEditDocuments) {
      showSnackBar(context, S.of(context)!.missingPermissions);
      return false;
    }
    final isConnectedToInternet =
        await context.read<ConnectivityStatusService>().isConnectedToInternet();
    if (!isConnectedToInternet) {
      if (mounted) showSnackBar(context, S.of(context)!.youAreCurrentlyOffline);
      return false;
    }
    try {
      if (mounted) {
        final removedTags =
            await context.read<InboxCubit>().removeFromInbox(doc);
        if (mounted) {
          showSnackBar(
            context,
            S.of(context)!.removeDocumentFromInbox,
            action: SnackBarActionConfig(
              label: S.of(context)!.undo,
              onPressed: () => _onUndoMarkAsSeen(doc, removedTags),
            ),
          );
        }
      }
      return true;
    } on PaperlessApiException catch (error, stackTrace) {
      if (mounted) showErrorMessage(context, error, stackTrace);
    } on ServerMessageException catch (error) {
      if (mounted) showGenericError(context, error.message);
    } catch (error) {
      if (mounted) {
        showErrorMessage(
          context,
          const PaperlessApiException.unknown(),
        );
      }
    }
    return false;
  }

  Future<void> _onUndoMarkAsSeen(
    DocumentModel document,
    Iterable<int> removedTags,
  ) async {
    try {
      await context
          .read<InboxCubit>()
          .undoRemoveFromInbox(document, removedTags);
    } on PaperlessApiException catch (error, stackTrace) {
      if (mounted) showErrorMessage(context, error, stackTrace);
    }
  }

  Map<String, List<DocumentModel>> _groupByDate(
    Iterable<DocumentModel> documents,
  ) {
    return groupBy<DocumentModel, String>(
      documents,
      (doc) {
        if (doc.added.isToday) {
          return S.of(context)!.today;
        }
        if (doc.added.isYesterday) {
          return S.of(context)!.yesterday;
        }
        return DateFormat.yMMMMd(Localizations.localeOf(context).toString())
            .format(doc.added);
      },
    );
  }
}
