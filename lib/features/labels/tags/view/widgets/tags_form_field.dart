import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_tag_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class TagFormField extends StatefulWidget {
  final TagsQuery? initialValue;
  final String name;
  final bool allowCreation;
  final bool notAssignedSelectable;
  final bool anyAssignedSelectable;
  final bool excludeAllowed;
  final Map<int, Tag> selectableOptions;

  const TagFormField({
    super.key,
    required this.name,
    this.initialValue,
    this.allowCreation = true,
    this.notAssignedSelectable = true,
    this.anyAssignedSelectable = true,
    this.excludeAllowed = true,
    required this.selectableOptions,
  });

  @override
  State<TagFormField> createState() => _TagFormFieldState();
}

class _TagFormFieldState extends State<TagFormField> {
  static const _onlyNotAssignedId = -1;
  static const _anyAssignedId = -2;

  late final TextEditingController _textEditingController;
  bool _showCreationSuffixIcon = true;
  bool _showClearSuffixIcon = false;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController()
      ..addListener(() {
        setState(() {
          _showCreationSuffixIcon = widget.selectableOptions.values
                  .where(
                    (item) => item.name.toLowerCase().startsWith(
                          _textEditingController.text.toLowerCase(),
                        ),
                  )
                  .isEmpty ||
              _textEditingController.text.isEmpty;
        });
        setState(
          () => _showClearSuffixIcon = _textEditingController.text.isNotEmpty,
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.selectableOptions.values.fold<bool>(
            false,
            (previousValue, element) =>
                previousValue || (element.documentCount ?? 0) > 0) ||
        widget.allowCreation;

    return FormBuilderField<TagsQuery>(
      enabled: isEnabled,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TypeAheadField<int>(
              textFieldConfiguration: TextFieldConfiguration(
                enabled: isEnabled,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.label_outline,
                  ),
                  suffixIcon: _buildSuffixIcon(context, field),
                  labelText: S.of(context).documentTagsPropertyLabel,
                  hintText: S.of(context).tagFormFieldSearchHintText,
                ),
                controller: _textEditingController,
              ),
              suggestionsBoxDecoration: SuggestionsBoxDecoration(
                elevation: 4.0,
                shadowColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              suggestionsCallback: (query) {
                final suggestions = widget.selectableOptions.entries
                    .where(
                      (entry) => entry.value.name
                          .toLowerCase()
                          .startsWith(query.toLowerCase()),
                    )
                    .where((entry) =>
                        widget.allowCreation ||
                        (entry.value.documentCount ?? 0) > 0)
                    .map((entry) => entry.key)
                    .toList();
                if (field.value is IdsTagsQuery) {
                  suggestions.removeWhere((element) =>
                      (field.value as IdsTagsQuery).ids.contains(element));
                }
                if (widget.notAssignedSelectable &&
                    field.value is! OnlyNotAssignedTagsQuery) {
                  suggestions.insert(0, _onlyNotAssignedId);
                }
                if (widget.anyAssignedSelectable &&
                    field.value is! AnyAssignedTagsQuery) {
                  suggestions.insert(0, _anyAssignedId);
                }
                return suggestions;
              },
              getImmediateSuggestions: true,
              animationStart: 1,
              itemBuilder: (context, data) {
                if (data == _onlyNotAssignedId) {
                  return ListTile(
                    title: Text(S.of(context).labelNotAssignedText),
                  );
                } else if (data == _anyAssignedId) {
                  return ListTile(
                    title: Text(S.of(context).labelAnyAssignedText),
                  );
                }
                final tag = widget.selectableOptions[data]!;
                return ListTile(
                  leading: Icon(
                    Icons.circle,
                    color: tag.color,
                  ),
                  title: Text(
                    tag.name,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground),
                  ),
                );
              },
              onSuggestionSelected: (id) {
                if (id == _onlyNotAssignedId) {
                  //Not assigned tag
                  field.didChange(const OnlyNotAssignedTagsQuery());
                  return;
                } else if (id == _anyAssignedId) {
                  field.didChange(const AnyAssignedTagsQuery());
                } else {
                  final tagsQuery = field.value is IdsTagsQuery
                      ? field.value as IdsTagsQuery
                      : const IdsTagsQuery();
                  field.didChange(
                      tagsQuery.withIdQueriesAdded([IncludeTagIdQuery(id)]));
                }
                _textEditingController.clear();
              },
              direction: AxisDirection.up,
            ),
            if (field.value is OnlyNotAssignedTagsQuery) ...[
              _buildNotAssignedTag(field)
            ] else if (field.value is AnyAssignedTagsQuery) ...[
              _buildAnyAssignedTag(field)
            ] else ...[
              // field.value is IdsTagsQuery
              Wrap(
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.start,
                spacing: 8.0,
                children: ((field.value as IdsTagsQuery).queries)
                    .map(
                      (query) => _buildTag(
                        field,
                        query,
                        widget.selectableOptions[query.id],
                      ),
                    )
                    .toList(),
              ),
            ]
          ],
        );
      },
      initialValue: widget.initialValue ?? const IdsTagsQuery(),
      name: widget.name,
    );
  }

  Widget? _buildSuffixIcon(
    BuildContext context,
    FormFieldState<TagsQuery> field,
  ) {
    if (_showCreationSuffixIcon && widget.allowCreation) {
      return IconButton(
        onPressed: () => _onAddTag(context, field),
        icon: const Icon(
          Icons.new_label,
        ),
      );
    }
    if (_showClearSuffixIcon) {
      return IconButton(
        icon: const Icon(Icons.clear),
        onPressed: _textEditingController.clear,
      );
    }
    return null;
  }

  void _onAddTag(BuildContext context, FormFieldState<TagsQuery> field) async {
    final Tag? tag = await Navigator.of(context).push<Tag>(
      MaterialPageRoute(
        builder: (_) => RepositoryProvider(
          create: (context) => context.read<LabelRepository<Tag>>(),
          child: AddTagPage(initialValue: _textEditingController.text),
        ),
      ),
    );
    if (tag != null) {
      final tagsQuery = field.value is IdsTagsQuery
          ? field.value as IdsTagsQuery
          : const IdsTagsQuery();
      field.didChange(
        tagsQuery.withIdQueriesAdded([IncludeTagIdQuery(tag.id!)]),
      );
    }
    _textEditingController.clear();
    // Call has to be delayed as otherwise the framework will not hide the keyboard directly after closing the add page.
    Future.delayed(
      const Duration(milliseconds: 100),
      FocusScope.of(context).unfocus,
    );
  }

  Widget _buildNotAssignedTag(FormFieldState<TagsQuery> field) {
    return InputChip(
      label: Text(
        S.of(context).labelNotAssignedText,
      ),
      backgroundColor:
          Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
      onDeleted: () => field.didChange(const IdsTagsQuery()),
    );
  }

  Widget _buildTag(
    FormFieldState<TagsQuery> field,
    TagIdQuery query,
    Tag? tag,
  ) {
    final currentQuery = field.value as IdsTagsQuery;
    final isIncludedTag = currentQuery.includedIds.contains(query.id);
    if (tag == null) {
      return Container();
    }
    return InputChip(
      label: Text(
        tag.name,
        style: TextStyle(
          color: tag.textColor,
          decoration: !isIncludedTag ? TextDecoration.lineThrough : null,
          decorationThickness: 2.0,
        ),
      ),
      onPressed: widget.excludeAllowed
          ? () => field.didChange(currentQuery.withIdQueryToggled(tag.id!))
          : null,
      backgroundColor: tag.color,
      deleteIconColor: tag.textColor,
      onDeleted: () => field.didChange(
        (field.value as IdsTagsQuery).withIdsRemoved([tag.id!]),
      ),
    );
  }

  Widget _buildAnyAssignedTag(FormFieldState<TagsQuery> field) {
    return InputChip(
      label: Text(S.of(context).labelAnyAssignedText),
      backgroundColor:
          Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.12),
      onDeleted: () => field.didChange(const IdsTagsQuery()),
    );
  }
}
