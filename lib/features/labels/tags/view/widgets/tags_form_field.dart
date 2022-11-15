import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/tags_query.dart';
import 'package:paperless_mobile/features/labels/tags/bloc/tags_cubit.dart';
import 'package:paperless_mobile/features/labels/tags/model/tag.model.dart';
import 'package:paperless_mobile/features/labels/tags/view/pages/add_tag_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class TagFormField extends StatefulWidget {
  final TagsQuery? initialValue;
  final String name;
  final bool allowCreation;
  final bool notAssignedSelectable;

  const TagFormField({
    super.key,
    required this.name,
    this.initialValue,
    this.allowCreation = true,
    this.notAssignedSelectable = true,
  });

  @override
  State<TagFormField> createState() => _TagFormFieldState();
}

class _TagFormFieldState extends State<TagFormField> {
  late final TextEditingController _textEditingController;
  bool _showCreationSuffixIcon = false;
  bool _showClearSuffixIcon = false;

  @override
  void initState() {
    super.initState();
    final state = BlocProvider.of<TagCubit>(context).state;
    _textEditingController = TextEditingController()
      ..addListener(() {
        setState(() {
          _showCreationSuffixIcon = state.values
              .where(
                (item) => item.name.toLowerCase().startsWith(
                      _textEditingController.text.toLowerCase(),
                    ),
              )
              .isEmpty;
        });
        setState(() =>
            _showClearSuffixIcon = _textEditingController.text.isNotEmpty);
      });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TagCubit, Map<int, Tag>>(
      builder: (context, tagState) {
        return FormBuilderField<TagsQuery>(
          builder: (field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TypeAheadField<int>(
                  textFieldConfiguration: TextFieldConfiguration(
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
                  suggestionsCallback: (query) {
                    final suggestions = tagState.values
                        .where((element) => element.name
                            .toLowerCase()
                            .startsWith(query.toLowerCase()))
                        .map((e) => e.id!)
                        .toList()
                      ..removeWhere((element) =>
                          field.value?.ids.contains(element) ?? false);
                    if (widget.notAssignedSelectable) {
                      suggestions.insert(0, -1);
                    }
                    return suggestions;
                  },
                  getImmediateSuggestions: true,
                  animationStart: 1,
                  itemBuilder: (context, data) {
                    if (data == -1) {
                      return ListTile(
                        title: Text(S.of(context).labelNotAssignedText),
                      );
                    }
                    final tag = tagState[data]!;
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
                    if (id == -1) {
                      field.didChange(const TagsQuery.notAssigned());
                      return;
                    } else {
                      field.didChange(
                          TagsQuery.fromIds([...field.value?.ids ?? [], id]));
                    }
                    _textEditingController.clear();
                  },
                  direction: AxisDirection.up,
                ),
                if (field.value?.onlyNotAssigned ?? false) ...[
                  _buildNotAssignedTag(field)
                ] else ...[
                  Wrap(
                    alignment: WrapAlignment.start,
                    runAlignment: WrapAlignment.start,
                    spacing: 8.0,
                    children: (field.value?.ids ?? [])
                        .map((id) => _buildTag(field, tagState[id]!))
                        .toList(),
                  ),
                ]
              ],
            );
          },
          initialValue: widget.initialValue ?? const TagsQuery.unset(),
          name: widget.name,
        );
      },
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
        builder: (_) => BlocProvider.value(
          value: BlocProvider.of<TagCubit>(context),
          child: AddTagPage(initialValue: _textEditingController.text),
        ),
      ),
    );
    if (tag != null) {
      field.didChange(
        TagsQuery.fromIds([...field.value?.ids ?? [], tag.id!]),
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
      onDeleted: () => field.didChange(
        const TagsQuery.unset(),
      ),
    );
  }

  Widget _buildTag(FormFieldState<TagsQuery> field, Tag tag) {
    return InputChip(
      label: Text(
        tag.name,
        style: TextStyle(color: tag.textColor),
      ),
      backgroundColor: tag.color,
      onDeleted: () => field.didChange(
        TagsQuery.fromIds(
          field.value?.ids.where((element) => element != tag.id).toList() ?? [],
        ),
      ),
    );
  }
}
