import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/tags_query.dart';
import 'package:paperless_mobile/features/labels/tags/bloc/tags_cubit.dart';
import 'package:paperless_mobile/features/labels/tags/model/tag.model.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class TagFormField extends StatefulWidget {
  final TagsQuery? initialValue;
  final String name;

  const TagFormField({
    super.key,
    required this.name,
    this.initialValue,
  });

  @override
  State<TagFormField> createState() => _TagFormFieldState();
}

class _TagFormFieldState extends State<TagFormField> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TagCubit, Map<int, Tag>>(
      builder: (context, tagState) {
        return FormBuilderField<TagsQuery>(
          builder: (field) {
            final sortedTags = tagState.values.toList()
              ..sort(
                (a, b) => a.name.compareTo(b.name),
              );
            //TODO: this is either not correctly resetting on filter reset or (when adding UniqueKey to FormField or ChipsInput) unmounts widget.
            // return ChipsInput<int>(
            //   chipBuilder: (context, state, data) => Chip(
            //     onDeleted: () => state.deleteChip(data),
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            //     backgroundColor: Color(tagState[data]!.color ?? Colors.white.value),
            //     label: Text(
            //       tagState[data]!.name,
            //       style: TextStyle(color: Color(tagState[data]!.textColor ?? Colors.black.value)),
            //     ),
            //   ),
            //   suggestionBuilder: (context, state, data) => ListTile(
            //     title: Text(tagState[data]!.name),
            //     textColor: Color(tagState[data]!.textColor!),
            //     tileColor: Color(tagState[data]!.color!),
            //     onTap: () => state.selectSuggestion(data),
            //   ),
            //   findSuggestions: (query) => tagState.values
            //       .where((element) => element.name.toLowerCase().startsWith(query.toLowerCase()))
            //       .map((e) => e.id!)
            //       .toList(),
            //   onChanged: (tags) => field.didChange(tags),
            //   initialValue: field.value!,
            // );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).documentTagsPropertyLabel,
                ),
                Wrap(
                  children: sortedTags
                      .map((tag) => FilterChip(
                            label: Text(
                              tag.name,
                              style: TextStyle(
                                color: tag.textColor,
                              ),
                            ),
                            selectedColor: tag.color,
                            selected:
                                field.value?.ids.contains(tag.id) ?? false,
                            onSelected: (isSelected) {
                              List<int> ids = [...field.value?.ids ?? []];
                              if (isSelected) {
                                ids.add(tag.id!);
                              } else {
                                ids.remove(tag.id);
                              }
                              field.didChange(TagsQuery.fromIds(ids));
                            },
                            backgroundColor: tag.color,
                          ))
                      .toList()
                      .padded(const EdgeInsets.only(right: 4.0)),
                ),
              ],
            );
          },
          initialValue: widget.initialValue ?? const TagsQuery.unset(),
          name: widget.name,
        );
      },
    );
  }
}
