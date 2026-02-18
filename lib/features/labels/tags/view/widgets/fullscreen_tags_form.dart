import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/labels_route.dart';

class FullscreenTagsForm extends StatefulWidget {
  final TagsQuery? initialValue;
  final Map<int, Tag> options;
  final void Function({TagsQuery? returnValue}) onSubmit;
  final bool allowOnlySelection;
  final bool allowCreation;
  final bool allowExclude;
  final bool autofocus;
  const FullscreenTagsForm({
    super.key,
    this.initialValue,
    required this.options,
    required this.onSubmit,
    required this.allowOnlySelection,
    required this.allowCreation,
    required this.allowExclude,
    this.autofocus = true,
  });

  @override
  State<FullscreenTagsForm> createState() => _FullscreenTagsFormState();
}

class _FullscreenTagsFormState extends State<FullscreenTagsForm> {
  late bool _showClearIcon = false;
  final _textEditingController = TextEditingController();
  final _focusNode = FocusNode();
  late List<Tag> _options;
  late Map<int, Tag> _allOptions;

  List<int> _include = [];
  List<int> _exclude = [];

  bool _anyAssigned = false;
  bool _notAssigned = false;

  @override
  void initState() {
    super.initState();
    _options = widget.options.values.toList();
    _allOptions = Map.of(widget.options);
    final value = widget.initialValue;
    if (value is IdsTagsQuery) {
      _include = value.include.toList();
      _exclude = value.exclude.toList();
    } else if (value is AnyAssignedTagsQuery) {
      _include = value.tagIds.toList();
      _anyAssigned = true;
    } else if (value is NotAssignedTagsQuery) {
      _notAssigned = true;
    }
    _textEditingController.addListener(() => setState(() {
          _showClearIcon = _textEditingController.text.isNotEmpty;
        }));
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        //Delay keyboard popup to ensure open animation is finished before.
        Future.delayed(
          const Duration(milliseconds: 200),
          () => _focusNode.requestFocus(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showFab = MediaQuery.viewInsetsOf(context).bottom == 0;
    final theme = Theme.of(context);
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
        leading: BackButton(
          color: theme.colorScheme.onSurface,
        ),
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
            hintText: S.of(context)!.startTyping,
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
            tooltip: S.of(context)!.done,
            icon: const Icon(Icons.done),
            onPressed: () {
              if (widget.allowOnlySelection) {
                widget.onSubmit(
                  returnValue: IdsTagsQuery(
                    include:
                        _include.sortedBy((id) => _allOptions[id]!.name),
                  ),
                );
                return;
              }
              late final TagsQuery query;
              if (_notAssigned) {
                query = const NotAssignedTagsQuery();
              } else if (_anyAssigned) {
                query = AnyAssignedTagsQuery(
                  tagIds: _include.sortedBy((id) => _allOptions[id]!.name),
                );
              } else {
                query = IdsTagsQuery(
                  include: _include.sortedBy((id) => _allOptions[id]!.name),
                  exclude: _exclude.sortedBy((id) => _allOptions[id]!.name),
                );
              }
              widget.onSubmit(returnValue: query);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: !widget.allowOnlySelection
              ? const Size.fromHeight(32)
              : const Size.fromHeight(1),
          child: Column(
            children: [
              Divider(color: theme.colorScheme.outline),
              if (!widget.allowOnlySelection)
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        enabled: isSegmentedButtonEnabled,
                        value: false,
                        label: Text(S.of(context)!.allTags),
                      ),
                      ButtonSegment(
                        enabled: isSegmentedButtonEnabled,
                        value: true,
                        label: Text(S.of(context)!.anyTag),
                      ),
                    ],
                    multiSelectionEnabled: false,
                    emptySelectionAllowed: true,
                    onSelectionChanged: (value) {
                      setState(() {
                        _anyAssigned = value.first;
                      });
                    },
                    selected: {_anyAssigned},
                  ),
                ),
            ],
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          final options = _buildOptions(_textEditingController.text);
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    return options.elementAt(index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onAddTag() async {
    final createdTag =
        await CreateLabelRoute(LabelType.tag, name: _textEditingController.text)
            .push<Tag>(context);
    _textEditingController.clear();
    if (createdTag != null) {
      setState(() {
        _options.add(createdTag);
        _allOptions[createdTag.id!] = createdTag;
        _toggleSelection(createdTag.id!);
      });
    }
  }

  bool get isSegmentedButtonEnabled {
    return _exclude.isEmpty && _include.length > 1;
  }

  Widget _buildNotAssignedOption() {
    return ListTile(
      title: Text(S.of(context)!.notAssigned),
      trailing: _notAssigned ? const Icon(Icons.done) : null,
      onTap: () {
        setState(() {
          _notAssigned = !_notAssigned;
          _include = [];
          _exclude = [];
        });
      },
    );
  }

  ///
  /// Filters the options passed to this widget by the current [query] and
  /// adds not-/any assigned options
  ///
  Iterable<Widget> _buildOptions(String query) sync* {
    final normalizedQuery = query.trim().toLowerCase();

    if (!widget.allowOnlySelection &&
        S.of(context)!.notAssigned.toLowerCase().contains(normalizedQuery)) {
      yield _buildNotAssignedOption();
    }

    var matches = _options
        .where((e) => e.name.trim().toLowerCase().contains(normalizedQuery));
    if (matches.isEmpty && widget.allowCreation) {
      yield Center(
        child: Column(
          children: [
            Text(S.of(context)!.noItemsFound).padded(),
            TextButton(
              onPressed: _onAddTag,
              child: Text(S.of(context)!.addTag),
            ),
          ],
        ),
      );
    }
    for (final tag in matches) {
      yield SelectableTagWidget(
        tag: tag,
        excluded: _exclude.contains(tag.id),
        selected: _include.contains(tag.id),
        onTap: () => _toggleSelection(tag.id!),
      );
    }
  }

  void _toggleSelection(int id) {
    if (widget.allowOnlySelection || widget.allowExclude) {
      if (_include.contains(id)) {
        setState(() => _include.remove(id));
      } else {
        setState(() => _include.add(id));
      }
    } else {
      if (_include.contains(id)) {
        setState(() {
          _notAssigned = false;
          _anyAssigned = false;
          _include.remove(id);
          _exclude.add(id);
        });
      } else if (_exclude.contains(id)) {
        setState(() {
          _notAssigned = false;
          _exclude.remove(id);
        });
      } else {
        setState(() {
          _notAssigned = false;
          _include.add(id);
        });
      }
    }
  }
}

class SelectableTagWidget extends StatelessWidget {
  final Tag tag;
  final bool selected;
  final bool excluded;
  final VoidCallback onTap;

  const SelectableTagWidget({
    super.key,
    required this.tag,
    required this.excluded,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final includeColor = Colors.green.withAlpha(76);
    final excludeColor = Colors.red.withAlpha(76);
    return ListTile(
      title: Text(tag.name),
      trailing: Text(S.of(context)!.documentsAssigned(tag.documentCount ?? 0)),
      leading: CircleAvatar(
        backgroundColor: tag.color,
        child: tag.isInboxTag ? Icon(Icons.inbox, color: tag.textColor) : null,
      ),
      onTap: onTap,
      tileColor: excluded
          ? excludeColor
          : selected
              ? includeColor
              : null,
    );
  }
}
