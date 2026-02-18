import 'package:animations/animations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/widgets/colored_chip.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/fullscreen_tags_form.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class TagsFormField extends StatelessWidget {
  final String name;
  final Map<int, Tag> options;
  final TagsQuery? initialValue;
  final bool allowOnlySelection;
  final bool allowCreation;
  final bool allowExclude;
  final Iterable<int> suggestions;
  final String? labelSuffix;

  const TagsFormField({
    super.key,
    required this.options,
    this.initialValue,
    required this.name,
    required this.allowOnlySelection,
    required this.allowCreation,
    required this.allowExclude,
    this.suggestions = const [],
    this.labelSuffix,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = options.values.isNotEmpty || allowCreation;

    return FormBuilderField<TagsQuery?>(
      initialValue: initialValue,
      enabled: enabled,
      builder: (field) {
        final values = _generateOptions(context, field.value, field).toList();
        final isEmpty = (field.value is IdsTagsQuery &&
                (field.value as IdsTagsQuery).include.isEmpty) ||
            field.value == null;
        bool anyAssigned = field.value is AnyAssignedTagsQuery;

        final displayedSuggestions = switch (field.value) {
          IdsTagsQuery(include: var include) =>
            suggestions.toSet().difference(include.toSet()).toList(),
          _ => <int>[],
        };
        return Column(
          children: [
            OpenContainer<TagsQuery>(
              middleColor: Theme.of(context).colorScheme.surface,
              closedColor: Theme.of(context).colorScheme.surface,
              openColor: Theme.of(context).colorScheme.surface,
              closedShape: InputBorder.none,
              openElevation: 0,
              closedElevation: 0,
              tappable: enabled,
              closedBuilder: (context, openForm) => Container(
                margin: const EdgeInsets.only(top: 6),
                child: GestureDetector(
                  onTap: openForm,
                  child: InputDecorator(
                    isEmpty: isEmpty,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(12),
                      labelText:
                          '${S.of(context)!.tags}${labelSuffix ?? ''}${anyAssigned ? ' (${S.of(context)!.anyAssigned})' : ''}',
                      prefixIcon: const Icon(Icons.label_outline),
                      enabled: enabled,
                    ),
                    child: SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 4),
                        itemBuilder: (context, index) => values[index],
                        itemCount: values.length,
                      ),
                    ),
                  ),
                ),
              ),
              openBuilder: (context, closeForm) => FullscreenTagsForm(
                options: options,
                onSubmit: closeForm,
                initialValue: field.value,
                allowOnlySelection: allowOnlySelection,
                allowCreation: allowCreation &&
                    context
                        .watch<LocalUserAccount>()
                        .paperlessUser
                        .canCreateTags,
                allowExclude: allowExclude,
              ),
              onClosed: (data) {
                if (data != null) {
                  field.didChange(data);
                }
              },
            ),
            if (displayedSuggestions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context)!.suggestions,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(
                    height: kMinInteractiveDimension,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: displayedSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion =
                            options[displayedSuggestions.elementAt(index)];
                        if (suggestion == null) {
                          return SizedBox.shrink();
                        }
                        return ColoredChipWrapper(
                          child: ActionChip(
                            label: Text(suggestion.name),
                            onPressed: () {
                              field.didChange(switch (field.value) {
                                IdsTagsQuery(include: var include) =>
                                  IdsTagsQuery(
                                    include: [...include, suggestion.id!],
                                  ),
                                _ => IdsTagsQuery(include: [suggestion.id!]),
                              });
                            },
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(width: 4.0),
                    ),
                  ),
                ],
              ).padded(),
          ],
        );
      },
      name: name,
    );
  }

  Iterable<Widget> _generateOptions(
    BuildContext context,
    TagsQuery? query,
    FormFieldState<TagsQuery?> field,
  ) sync* {
    if (query == null) {
      yield Container();
    } else {
      final widgets = switch (query) {
        IdsTagsQuery(include: var inc, exclude: var exc) => [
            for (var i in inc) _buildTagIdQueryWidget(context, i, field, false),
            for (var e in exc) _buildTagIdQueryWidget(context, e, field, true),
          ],
        AnyAssignedTagsQuery query => [
            for (var id in query.tagIds)
              _buildAnyAssignedTagWidget(context, id, field, query),
          ],
        NotAssignedTagsQuery() => [_buildNotAssignedTagWidget(context, field)],
      };
      for (var child in widgets) {
        yield child;
      }
    }
  }

  Widget _buildTagIdQueryWidget(
    BuildContext context,
    int id,
    FormFieldState<TagsQuery?> field,
    bool exclude,
  ) {
    assert(field.value is IdsTagsQuery);
    final formValue = field.value as IdsTagsQuery;
    final tag = options[id]!;
    return QueryTagChip(
      onDeleted: () => field.didChange(formValue.copyWith(
        include:
            formValue.include.whereNot((element) => element == id).toList(),
        exclude:
            formValue.exclude.whereNot((element) => element == id).toList(),
      )),
      onSelected: allowExclude
          ? () {
              if (formValue.include.contains(id)) {
                field.didChange(
                  formValue.copyWith(
                    include: formValue.include
                        .whereNot((element) => element == id)
                        .toList(),
                    exclude: [...formValue.exclude, id],
                  ),
                );
              } else if (formValue.exclude.contains(id)) {}
              field.didChange(
                formValue.copyWith(
                  include: [...formValue.include, id],
                  exclude: formValue.exclude
                      .whereNot((element) => element == id)
                      .toList(),
                ),
              );
            }
          : null,
      exclude: exclude,
      backgroundColor: tag.color,
      foregroundColor: tag.textColor,
      labelText: tag.name,
    );
  }

  Widget _buildNotAssignedTagWidget(
    BuildContext context,
    FormFieldState<TagsQuery?> field,
  ) {
    return QueryTagChip(
      onDeleted: () => field.didChange(null),
      exclude: false,
      backgroundColor: Colors.grey,
      foregroundColor: Colors.black,
      labelText: S.of(context)!.notAssigned,
    );
  }

  Widget _buildAnyAssignedTagWidget(
    BuildContext context,
    int e,
    FormFieldState<TagsQuery?> field,
    AnyAssignedTagsQuery query,
  ) {
    return QueryTagChip(
      onDeleted: () {
        final updatedQuery = query.copyWith(
          tagIds: query.tagIds.whereNot((element) => element == e).toList(),
        );
        if (updatedQuery.tagIds.isEmpty) {
          field.didChange(const IdsTagsQuery());
        } else {
          field.didChange(updatedQuery);
        }
      },
      exclude: false,
      backgroundColor: options[e]!.color,
      foregroundColor: options[e]!.textColor,
      labelText: options[e]!.name,
    );
  }
}

typedef TagQueryCallback = void Function(Tag tag);

class QueryTagChip extends StatelessWidget {
  final VoidCallback onDeleted;
  final VoidCallback? onSelected;
  final bool exclude;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String labelText;

  const QueryTagChip({
    super.key,
    required this.onDeleted,
    this.onSelected,
    required this.exclude,
    this.backgroundColor,
    this.foregroundColor,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredChipWrapper(
      child: InputChip(
        labelPadding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 2,
        ),
        padding: const EdgeInsets.all(4),
        selectedColor: backgroundColor,
        visualDensity: const VisualDensity(vertical: -2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text(
          labelText,
          style: TextStyle(
            color: foregroundColor,
            decorationColor: foregroundColor,
            decoration: exclude ? TextDecoration.lineThrough : null,
          ),
        ),
        onDeleted: onDeleted,
        onPressed: onSelected,
        deleteIconColor: foregroundColor,
        checkmarkColor: foregroundColor,
        backgroundColor: backgroundColor,
        side: BorderSide.none,
      ),
    );
  }
}
