import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/accessibility/accessibility_utils.dart';
import 'package:paperless_mobile/core/extensions/document_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/document_search/cubit/document_search_cubit.dart';
import 'package:paperless_mobile/features/document_search/view/remove_history_entry_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/adaptive_documents_view.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/view_type_selection_widget.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';

class DocumentSearchPage extends StatefulWidget {
  const DocumentSearchPage({super.key});

  @override
  State<DocumentSearchPage> createState() => _DocumentSearchPageState();
}

class _DocumentSearchPageState extends State<DocumentSearchPage> {
  final _queryController = TextEditingController(text: '');
  final _queryFocusNode = FocusNode();

  Timer? _debounceTimer;

  String get query => _queryController.text;

  @override
  Widget build(BuildContext context) {
    const double progressIndicatorHeight = 4;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        toolbarHeight: 72 - progressIndicatorHeight,
        leading: BackButton(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: Hero(
          tag: "search_hero_tag",
          child: TextField(
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
            onChanged: (query) {
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                context.read<DocumentSearchCubit>().suggest(query);
              });
            },
            textInputAction: TextInputAction.search,
            onSubmitted: (query) {
              FocusScope.of(context).unfocus();
              _debounceTimer?.cancel();
              context.read<DocumentSearchCubit>().search(query);
            },
          ),
        ).accessible(),
        actions: [
          IconButton(
            color: theme.colorScheme.onSurfaceVariant,
            icon: const Icon(Icons.clear),
            onPressed: () {
              context.read<DocumentSearchCubit>().reset();
              _queryController.clear();
            },
          ).padded(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(progressIndicatorHeight),
          child: BlocBuilder<DocumentSearchCubit, DocumentSearchState>(
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
            child: BlocBuilder<DocumentSearchCubit, DocumentSearchState>(
              builder: (context, state) {
                switch (state.view) {
                  case SearchView.suggestions:
                    return _buildSuggestionsView(state);
                  case SearchView.results:
                    return _buildResultsView(state);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsView(DocumentSearchState state) {
    final suggestions = state.suggestions
        .whereNot((element) => state.searchHistory.contains(element))
        .toList();
    final historyMatches = state.searchHistory
        .where(
          (element) => element.startsWith(query),
        )
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
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ListTile(
              title: Text(suggestions[index]),
              leading: const Icon(Icons.search),
              onTap: () => _selectSuggestion(suggestions[index]),
              trailing: _buildInsertSuggestionButton(suggestions[index]),
            ),
            childCount: suggestions.length,
          ),
        ),
        if (suggestions.isEmpty && historyMatches.isEmpty && state.hasLoaded)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Center(child: Text(S.of(context)!.noMatchesFound)),
            ),
          ),
      ],
    );
  }

  Future<void> _onDeleteHistoryEntry(String entry) async {
    final shouldRemove = await showDialog<bool>(
          context: context,
          builder: (context) => RemoveHistoryEntryDialog(entry: entry),
        ) ??
        false;
    if (shouldRemove && mounted) {
      context.read<DocumentSearchCubit>().removeHistoryEntry(entry);
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

  Widget _buildResultsView(DocumentSearchState state) {
    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          S.of(context)!.results,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        BlocBuilder<DocumentSearchCubit, DocumentSearchState>(
          builder: (context, state) {
            return ViewTypeSelectionWidget(
              viewType: state.viewType,
              onChanged: (type) =>
                  context.read<DocumentSearchCubit>().updateViewType(type),
            );
          },
        )
      ],
    ).paddedLTRB(16, 8, 8, 8);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: header),
        if (state.hasLoaded && !state.isLoading && state.documents.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Text(S.of(context)!.noDocumentsFound),
            ).paddedOnly(top: 8),
          )
        else
          SliverAdaptiveDocumentsView(
            viewType: state.viewType,
            documents: state.documents,
            hasInternetConnection: true,
            isLabelClickable: false,
            isLoading: state.isLoading,
            hasLoaded: state.hasLoaded,
            enableHeroAnimation: false,
            onTap: (document) {
              DocumentDetailsRoute(
                title: document.title,
                id: document.id,
                isLabelClickable: false,
                thumbnailUrl: document.buildThumbnailUrl(context),
              ).push(context);
            },
          )
      ],
    );
  }

  void _selectSuggestion(String suggestion) {
    _queryController.text = suggestion;
    context.read<DocumentSearchCubit>().search(suggestion);
    FocusScope.of(context).unfocus();
  }
}
