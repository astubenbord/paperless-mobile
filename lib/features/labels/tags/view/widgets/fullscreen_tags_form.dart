import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/extensions/label_list_extension.dart';
import 'package:paperless_mobile/features/labels/view/widgets/multi_label_form.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/labels_route.dart';

/// A fullscreen form for selecting multiple tags.
///
/// When [allowExclude] is set (filter mode), every tag has its own selection
/// state, so included and excluded tags can be combined in one query: tapping
/// a tag cycles through include -> exclude -> unselected. The -1 sentinel
/// represents the "any assigned" / "not assigned" special option, which cycles
/// the same way and cannot be combined with individual tags.
class FullscreenTagsForm extends StatefulWidget {
  final TagsQuery? initialValue;
  final void Function({TagsQuery? returnValue}) onSubmit;
  final bool allowCreation;
  final bool allowExclude;
  final bool autofocus;

  const FullscreenTagsForm({
    super.key,
    this.initialValue,
    required this.onSubmit,
    required this.allowCreation,
    required this.allowExclude,
    this.autofocus = true,
  });

  @override
  State<FullscreenTagsForm> createState() => _FullscreenTagsFormState();
}

class _FullscreenTagsFormState extends State<FullscreenTagsForm> {
  bool _showClearIcon = false;
  final _textEditingController = TextEditingController();
  final _focusNode = FocusNode();

  /// Selection state per tag id (excluding the -1 sentinel).
  late Map<int, SelectionType> _selection;

  /// Selection state of the any assigned (include) / not assigned (exclude)
  /// option, or null if not selected.
  SelectionType? _assignmentSelection;

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(() {
      setState(() => _showClearIcon = _textEditingController.text.isNotEmpty);
    });
    _selection = switch (widget.initialValue) {
      IdsTagsQuery(include: final inc, exclude: final exc) => {
        for (final id in inc) id: SelectionType.include,
        if (widget.allowExclude)
          for (final id in exc) id: SelectionType.exclude,
      },
      _ => {},
    };
    _assignmentSelection = switch (widget.initialValue) {
      AnyAssignedTagsQuery() => SelectionType.include,
      NotAssignedTagsQuery() => SelectionType.exclude,
      _ => null,
    };
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        // Delay keyboard popup to ensure open animation is finished before.
        Future.delayed(
          const Duration(milliseconds: 200),
          () => _focusNode.requestFocus(),
        );
      });
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showFab = MediaQuery.viewInsetsOf(context).bottom == 0;
    final theme = Theme.of(context);

    return QueryBuilder(
      query: context.tagRepository.getAllQuery(),
      builder: (context, state) {
        final options = state.data?.toIdMap() ?? {};
        final filteredOptions = _filterOptionsByQuery(
          _textEditingController.text,
          options,
        );

        return Scaffold(
          floatingActionButton: widget.allowCreation && showFab
              ? FloatingActionButton(
                  heroTag: "fab_tags_form",
                  onPressed: _onAddTag,
                  child: const Icon(Icons.add),
                )
              : null,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface,
            toolbarHeight: 72,
            leading: BackButton(color: theme.colorScheme.onSurface),
            title: TextFormField(
              focusNode: _focusNode,
              controller: _textEditingController,
              autofocus: true,
              style: theme.textTheme.bodyLarge?.apply(
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.zero,
                hintStyle: theme.textTheme.bodyLarge?.apply(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                icon: const Icon(Icons.label_outline),
                hintText: _buildHintText(),
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.done,
            ),
            actions: [
              if (_showClearIcon)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _textEditingController.clear();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.done),
                onPressed: _onSubmitSelection,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: theme.colorScheme.outline),
            ),
          ),
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  if (widget.allowExclude)
                    Text(
                      S.of(context)!.tagFilterSelectionHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ).padded(),
                  if (filteredOptions.where((id) => id != -1).isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Text(S.of(context)!.noItemsFound).padded(),
                          if (widget.allowCreation)
                            TextButton(
                              onPressed: _onAddTag,
                              child: Text(S.of(context)!.addTag),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: filteredOptions.length,
                      itemBuilder: (BuildContext context, int index) {
                        final option = filteredOptions.elementAt(index);
                        return _buildOptionWidget(option, options);
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

  void _onAddTag() async {
    final createdTag = await CreateLabelRoute(
      LabelType.tag,
      name: _textEditingController.text,
    ).push<Tag>(context);
    _textEditingController.clear();
    if (createdTag != null) {
      setState(() {
        _assignmentSelection = null;
        _selection[createdTag.id] = SelectionType.include;
      });
    }
  }

  void _onSubmitSelection() {
    switch (_assignmentSelection) {
      case SelectionType.include:
        widget.onSubmit(returnValue: const AnyAssignedTagsQuery());
        return;
      case SelectionType.exclude:
        widget.onSubmit(returnValue: const NotAssignedTagsQuery());
        return;
      case null:
        break;
    }

    if (_selection.isEmpty) {
      widget.onSubmit(returnValue: null);
      return;
    }

    List<int> idsWith(SelectionType type) => [
      for (final MapEntry(:key, :value) in _selection.entries)
        if (value == type) key,
    ];

    widget.onSubmit(
      returnValue: IdsTagsQuery(
        include: idsWith(SelectionType.include),
        exclude: idsWith(SelectionType.exclude),
      ),
    );
  }

  /// Cycles unselected -> include -> exclude -> unselected in filter mode,
  /// and unselected <-> include otherwise.
  SelectionType? _nextSelection(SelectionType? current) {
    return switch (current) {
      null => SelectionType.include,
      SelectionType.include when widget.allowExclude => SelectionType.exclude,
      _ => null,
    };
  }

  /// Filters the options passed to this widget by the current [query] and
  /// adds any-assigned/not-assigned option at the top when exclude is allowed.
  Iterable<int> _filterOptionsByQuery(
    String query,
    Map<int, Tag> options,
  ) sync* {
    final normalizedQuery = query.trim().toLowerCase();
    // Show the any-assigned/not-assigned option only in filter mode
    if (widget.allowExclude) {
      yield -1;
    }

    yield* options.entries
        .where(
          (entry) => entry.value.name.toLowerCase().contains(normalizedQuery),
        )
        .map((e) => e.key);
  }

  String? _buildHintText() {
    return switch (widget.initialValue) {
      NotAssignedTagsQuery() => S.of(context)!.notAssigned,
      AnyAssignedTagsQuery() => S.of(context)!.anyAssigned,
      _ => S.of(context)!.startTyping,
    };
  }

  Widget _buildOptionWidget(int option, Map<int, Tag> options) {
    if (option == -1) {
      final selection = _assignmentSelection;
      return ListTile(
        selected: selection != null,
        selectedTileColor: Theme.of(context).focusColor,
        title: Text(switch (selection) {
          SelectionType.exclude => S.of(context)!.notAssigned,
          _ => S.of(context)!.anyAssigned,
        }),
        trailing: _SelectionIcon(selection: selection),
        onTap: () => _onOptionTap(option),
      );
    }

    final tag = options[option];
    if (tag == null) return const SizedBox.shrink();

    return SelectableTagWidget(
      tag: tag,
      selection: _selection[option],
      onTap: () => _onOptionTap(option),
    );
  }

  void _onOptionTap(int option) {
    setState(() {
      if (option == -1) {
        _assignmentSelection = _nextSelection(_assignmentSelection);
        if (_assignmentSelection != null) {
          _selection.clear();
        }
        return;
      }
      _assignmentSelection = null;
      final next = _nextSelection(_selection[option]);
      if (next == null) {
        _selection.remove(option);
      } else {
        _selection[option] = next;
      }
    });
  }
}

class _SelectionIcon extends StatelessWidget {
  final SelectionType? selection;

  const _SelectionIcon({required this.selection});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (selection) {
      SelectionType.include => Icon(
        Icons.check_circle,
        color: colorScheme.primary,
        semanticLabel: S.of(context)!.include,
      ),
      SelectionType.exclude => Icon(
        Icons.remove_circle,
        color: colorScheme.error,
        semanticLabel: S.of(context)!.exclude,
      ),
      null => const SizedBox.shrink(),
    };
  }
}

class SelectableTagWidget extends StatelessWidget {
  final Tag tag;
  final SelectionType? selection;
  final VoidCallback onTap;

  const SelectableTagWidget({
    super.key,
    required this.tag,
    required this.selection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(tag.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.of(context)!.documentsAssigned(tag.documentCount ?? 0)),
          if (selection != null) ...[
            const SizedBox(width: 8),
            _SelectionIcon(selection: selection),
          ],
        ],
      ),
      leading: CircleAvatar(
        backgroundColor: tag.color,
        child: tag.isInboxTag ? Icon(Icons.inbox, color: tag.textColor) : null,
      ),
      onTap: onTap,
      selected: selection != null,
      selectedTileColor: Theme.of(context).focusColor,
    );
  }
}
