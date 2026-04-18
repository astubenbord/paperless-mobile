import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/api/extensions/cached_query_extensions.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/exception/server_message_exception.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/dart_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_cancel_button.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_confirm_button.dart';
import 'package:paperless_mobile/core/widgets/hint_card.dart';
import 'package:paperless_mobile/core/widgets/hint_state_builder.dart';
import 'package:paperless_mobile/features/app_drawer/view/app_drawer.dart';
import 'package:paperless_mobile/features/document_search/view/sliver_search_bar.dart';
import 'package:paperless_mobile/features/inbox/view/no_inbox_tags_declared_widget.dart';
import 'package:paperless_mobile/features/inbox/view/widgets/inbox_empty_widget.dart';
import 'package:paperless_mobile/features/inbox/view/widgets/inbox_item.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/connectivity_aware_action_wrapper.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final SliverOverlapAbsorberHandle searchBarHandle =
      SliverOverlapAbsorberHandle();

  final _nestedScrollViewKey = GlobalKey<NestedScrollViewState>();
  final _emptyStateRefreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _scrollController = ScrollController();
  bool _showExtendedFab = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.inboxRepository.inboxDocumentsQuery.state.isInitial) {
        context.inboxRepository.reload();
      }
      _nestedScrollViewKey.currentState?.innerController.addListener(
        _scrollExtentChangedListener,
      );
    });
  }

  @override
  void dispose() {
    _nestedScrollViewKey.currentState?.innerController.removeListener(
      _scrollExtentChangedListener,
    );
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
    return QueryBuilder(
      query: context.inboxRepository.inboxTagsQuery,
      builder: (context, inboxTagsState) {
        return Scaffold(
          drawer: const AppDrawer(),
          floatingActionButton: ConnectivityAwareActionWrapper(
            offlineBuilder: (context, child) => const SizedBox.shrink(),
            child: QueryBuilder(
              query: context.inboxRepository.inboxDocumentsQuery,
              builder: (context, state) {
                if (inboxTagsState.data?.isEmpty ?? true) {
                  return const SizedBox.shrink();
                }

                if (state.isLoadingInitial) {
                  return const InboxItemPlaceholder();
                }

                final documents = state.data?.pages.flattened ?? [];
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
                  onPressed: documents.isNotEmpty ? _onMarkAllAsSeen : null,
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
              body: Builder(
                builder: (context) {
                  if (inboxTagsState.isLoadingInitial) {
                    return _buildLoading();
                  }

                  if (inboxTagsState.data?.isEmpty ?? true) {
                    return NoInboxTagsDeclaredWidget();
                  }

                  return QueryBuilder(
                    query: context.inboxRepository.inboxDocumentsQuery,
                    builder: (context, state) {
                      if (state.isLoadingInitial) {
                        return _buildLoading();
                      }
                      if (state.isError) {
                        return Column(
                          children: [
                            Center(
                              child: Text(
                                'Could not load inbox',
                                textAlign: TextAlign.center,
                              ).padded(),
                            ),
                            Text(state.error.toString()).padded(),
                            TextButton(
                              onPressed: context.inboxRepository.reload,
                              child: Text('Retry'), //TODO: INTL
                            ),
                          ],
                        );
                      }
                      final documents = state.data!.pages.flattened;
                      return _buildLoaded(documents);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16),
      physics: const NeverScrollableScrollPhysics(),
      controller: _scrollController,
      itemBuilder: (context, index) => const InboxItemPlaceholder(),
    );
  }

  Widget _buildLoaded(List<Document> documents) {
    if (documents.isEmpty) {
      return Center(
        child: InboxEmptyWidget(
          emptyStateRefreshIndicatorKey: _emptyStateRefreshIndicatorKey,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: context.inboxRepository.reload,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HintStateBuilder(
              listenKey: 'inboxSwipeLeftHint',
              builder: (context, isHintAcknowledged, acknowledge) => HintCard(
                show: !isHintAcknowledged,
                hintText: S.of(context)!.swipeLeftToMarkADocumentAsSeen,
                onAcknowledgeHint: acknowledge,
              ),
            ),
          ),
          // Build a list of slivers alternating between SliverToBoxAdapter
          // (group header) and a SliverList (inbox items).
          ..._groupByDate(documents).entries
              .map(
                (entry) => [
                  SliverToBoxAdapter(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32.0),
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodySmall,
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
                              _buildListItem(entry.value[index]),
                              const Divider(indent: 16, endIndent: 16),
                            ],
                          );
                        }
                        return _buildListItem(entry.value[index]);
                      },
                    ),
                  ),
                ],
              )
              .flattened,
          const SliverToBoxAdapter(child: SizedBox(height: 78)),
        ],
      ),
    );
  }

  Widget _buildListItem(Document doc) {
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
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ).padded(),
      confirmDismiss: (_) => _onItemDismissed(doc),
      key: ValueKey(doc.id),
      child: InboxItem(document: doc),
    );
  }

  Future<void> _onMarkAllAsSeen() async {
    final isActionConfirmed =
        await showDialog(
          useRootNavigator: false,
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
      await context.inboxRepository.clearInboxMutation.mutate();
    }
  }

  Future<bool> _onItemDismissed(Document doc) async {
    if (!context.uiSettings$.canEditDocuments) {
      showSnackBar(context, S.of(context)!.missingPermissions);
      return false;
    }
    final isConnectedToInternet = await context
        .read<ConnectivityStatusService>()
        .isConnectedToInternet();
    if (!isConnectedToInternet) {
      if (mounted) showSnackBar(context, S.of(context)!.youAreCurrentlyOffline);
      return false;
    }
    try {
      if (mounted) {
        final result = await context.inboxRepository
            .markAsSeenMutation(doc)
            .mutate();
        final removedTags = result.data ?? <int>[];
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
        showErrorMessage(context, const PaperlessApiException.unknown());
      }
    }
    return false;
  }

  Future<void> _onUndoMarkAsSeen(
    Document document,
    List<int> removedTags,
  ) async {
    try {
      await context.inboxRepository
          .undoMarkAsSeenMutation(document)
          .mutate(removedTags);
    } on PaperlessApiException catch (error, stackTrace) {
      if (mounted) showErrorMessage(context, error, stackTrace);
    }
  }

  Map<String, List<Document>> _groupByDate(Iterable<Document> documents) {
    return groupBy<Document, String>(documents, (doc) {
      if (doc.added == null) {
        return S.of(context)!.notAssigned;
      }
      if (doc.added!.isToday) {
        return S.of(context)!.today;
      }
      if (doc.added!.isYesterday) {
        return S.of(context)!.yesterday;
      }
      return context.displayDateFormat.format(doc.added!);
    });
  }
}
