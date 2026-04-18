import 'dart:async';
import 'dart:math' as math;

import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/api/extensions/cached_query_extensions.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/repository/search_repository.dart';
import 'package:paperless_mobile/core/store/slices/local_user_app_state.dart';
import 'package:paperless_mobile/features/document_search/view/remove_history_entry_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/adaptive_documents_view.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/view_type_selection_widget.dart';
import 'package:paperless_mobile/features/settings/model/view_type.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

enum SearchView { suggestions, results }

class DocumentSearchPage extends StatefulWidget {
  static String heroPrefix = "search_hero";
  final VoidCallback close;
  final void Function(BuildContext context, Document document) onItemSelected;
  final List<int> disabledIds;

  const DocumentSearchPage({
    super.key,
    required this.onItemSelected,
    required this.close,
    this.disabledIds = const [],
  });

  @override
  State<DocumentSearchPage> createState() => _DocumentSearchPageState();
}

class _DocumentSearchPageState extends State<DocumentSearchPage> {
  final _queryController = TextEditingController(text: '');
  final _queryFocusNode = FocusNode();

  Timer? _debounceTimer;
  String _searchTerm = '';
  SearchView _searchView = SearchView.suggestions;
  late ViewType _documentViewType;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(() {
      _debounceTimer?.cancel();
      if (_queryController.text.isEmpty) {
        setState(() {
          _searchTerm = '';
          _searchView = SearchView.suggestions;
        });
        return;
      }
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _searchTerm = _queryController.text;
        });
      });
    });
    _documentViewType =
        context.loggedInUserData.appState.documentSearchViewType;
  }

  @override
  Widget build(BuildContext context) {
    const progressIndicatorHeight = 4.0;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        toolbarHeight: 72 - progressIndicatorHeight,
        leading: BackButton(
          color: theme.colorScheme.onSurfaceVariant,
          onPressed: () {
            if (_searchView == SearchView.results) {
              setState(() {
                _searchView = SearchView.suggestions;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _queryController.clear();
                _queryFocusNode.requestFocus();
              });
            } else {
              widget.close();
            }
          },
        ),
        title: TextField(
          autofocus: true,
          // style: theme.textTheme.bodyLarge?.apply(
          //   color: theme.colorScheme.onSurface,
          // ),
          focusNode: _queryFocusNode,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            hintText: S.of(context)!.searchDocuments,
            border: InputBorder.none,
          ),
          controller: _queryController,
          textInputAction: TextInputAction.search,
          onSubmitted: (query) {
            _onSubmit(context, query);
          },
        ),
        actions: [
          IconButton(
            color: theme.colorScheme.onSurfaceVariant,
            icon: const Icon(Icons.clear),
            onPressed: () {
              _queryController.clear();
            },
          ).padded(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(progressIndicatorHeight),
          child: QueryBuilder(
            query: context.read<SearchRepository>().autocompleteQuery(
              _queryController.text,
            ),
            builder: (context, state) {
              if (state.isLoading) {
                return const LinearProgressIndicator();
              }
              return ColoredBox(color: Theme.of(context).colorScheme.surface);
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: switch (_searchView) {
              SearchView.suggestions => _buildSuggestionsView(),
              SearchView.results => _buildResultsView(),
            },
          ),
        ],
      ),
    );
  }

  void _onSubmit(BuildContext context, String query) {
    FocusScope.of(context).unfocus();
    _debounceTimer?.cancel();
    context.localStore.updateLoggedInUserAppState(
      (state) => state.copyWith(
        documentSearchHistory: [
          ...state.documentSearchHistory.whereNot((e) => e == query),
          query,
        ],
      ),
    );
    setState(() {
      _searchTerm = query;
      _searchView = SearchView.results;
    });
  }

  Widget _buildSuggestionsView() {
    final searchHistory =
        context.loggedInUserData$.appState.documentSearchHistory;
    final historyMatches = searchHistory
        .where((element) => element.startsWith(_searchTerm))
        .toList();

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ListTile(
              title: Text(historyMatches[index]),
              leading: const Icon(Icons.history),
              onLongPress: () => _onDeleteHistoryEntry(historyMatches[index]),
              onTap: () => _selectSuggestion(historyMatches[index]),
              trailing: _buildInsertSuggestionButton(historyMatches[index]),
            ),
            childCount: historyMatches.length,
          ),
        ),
        QueryBuilder(
          query: context.searchRepository.autocompleteQuery(_searchTerm),
          builder: (context, state) {
            if (state.isError) {
              return SliverFillRemaining(
                child: Center(
                  child: Text(S.of(context)!.couldNotLoadSuggestions),
                ),
              );
            }
            if (state.isLoadingInitial) {
              return SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final suggestions = state.data ?? [];
            return SliverMainAxisGroup(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ListTile(
                      title: Text(suggestions.elementAt(index)),
                      leading: const Icon(Icons.search),
                      onTap: () =>
                          _selectSuggestion(suggestions.elementAt(index)),
                      trailing: _buildInsertSuggestionButton(
                        suggestions.elementAt(index),
                      ),
                    ),
                    childCount: suggestions.length,
                  ),
                ),
                if (suggestions.isEmpty && historyMatches.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Center(child: Text(S.of(context)!.noMatchesFound)),
                    ),
                  ),
              ],
            );
          },
        ),
        SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  void _onDeleteHistoryEntry(String entry) async {
    final shouldRemove =
        await showDialog<bool>(
          useRootNavigator: false,
          context: context,
          builder: (context) => RemoveHistoryEntryDialog(entry: entry),
        ) ??
        false;
    if (shouldRemove && mounted) {
      context.localStore.updateLoggedInUserAppState(
        (state) => state.copyWith(
          documentSearchHistory: state.documentSearchHistory
              .whereNot((e) => e == entry)
              .toList(),
        ),
      );
    }
  }

  Widget _buildInsertSuggestionButton(String suggestion) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(math.pi),
      child: IconButton(
        icon: const Icon(Icons.arrow_outward),
        onPressed: () {
          _queryController.text = '$suggestion ';
          _queryController.selection = TextSelection.fromPosition(
            TextPosition(offset: _queryController.text.length),
          );
          _queryFocusNode.requestFocus();
        },
      ),
    );
  }

  Widget _buildResultsView() {
    final normalizedQuery = _searchTerm.trim();
    final resultListQuery = context.documentRepository.getAllQuery(
      filter: DocumentFilter(
        query:
            context.uiSettings.settings?.search?.moreLink ==
                UiSettingsViewSettingsSearchMoreLink.advanced
            ? TextQuery.extended(normalizedQuery)
            : TextQuery.titleAndContent(normalizedQuery),
      ),
    );

    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          S.of(context)!.results,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        ViewTypeSelectionWidget(
          viewType: _documentViewType,
          onChanged: (type) {
            setState(() {
              _documentViewType = type;
            });
          },
        ),
      ],
    ).paddedLTRB(16, 8, 8, 8);
    return QueryBuilder(
      query: resultListQuery,
      builder: (context, state) {
        final documents =
            state.data?.pages.expand((e) => e.results).toList() ?? [];
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: header),
            if (documents.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Text(S.of(context)!.noDocumentsFound),
                ).paddedOnly(top: 8),
              )
            else ...[
              SliverAdaptiveDocumentsView(
                heroTagPrefix: DocumentSearchPage.heroPrefix,
                viewType: _documentViewType,
                documents: documents,
                isLabelClickable: false,
                isLoading: state.isLoading,
                hasLoaded: state.isSuccess,
                disabledIds: widget.disabledIds,
                onTap: (document) {
                  widget.onItemSelected(context, document);
                },
              ),
              SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ],
        );
      },
    );
  }

  void _selectSuggestion(String suggestion) {
    _queryController.text = suggestion;
    _onSubmit(context, suggestion);
  }
}
