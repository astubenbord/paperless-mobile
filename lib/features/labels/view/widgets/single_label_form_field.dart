import 'package:animations/animations.dart';
import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/api/extensions/cached_query_extensions.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/extensions/label_list_extension.dart';
import 'package:paperless_mobile/features/labels/view/widgets/single_label_form.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class SingleLabelFormField<T extends Label> extends StatelessWidget {
  final Widget prefixIcon;
  final Query<List<T>> query;
  final int? initialValue;
  final String name;
  final String labelText;
  final FormFieldValidator? validator;
  final Future<T?> Function(String? initialName)? onAddLabel;
  final void Function(int?)? onChanged;
  final Iterable<int> suggestions;
  final String? addLabelText;

  const SingleLabelFormField({
    super.key,
    required this.name,
    required this.query,
    required this.labelText,
    required this.prefixIcon,
    this.initialValue,
    this.validator,
    this.onAddLabel,
    this.onChanged,
    this.suggestions = const [],
    this.addLabelText,
  }) : assert(
         (addLabelText != null) == (onAddLabel != null),
         'addLabelText and onAddLabel must both be provided or both be null',
       );

  @override
  Widget build(BuildContext context) {
    // FormBuilderField must be OUTSIDE QueryBuilder to keep a stable field reference
    // when the query cache updates (e.g., after creating a new label)
    return FormBuilderField<int?>(
      name: name,
      initialValue: initialValue,
      onChanged: onChanged,
      builder: (field) {
        return QueryBuilder(
          query: query,
          builder: (context, state) {
            // Handle initial loading state
            if (state.isLoadingInitial) {
              return _buildLoadingInput(context);
            }

            final options = state.data?.toIdMap() ?? {};
            final enabled = options.isNotEmpty || onAddLabel != null;
            final displayText = field.value != null
                ? (options[field.value]?.name ?? '?')
                : '';
            final displayedSuggestions = suggestions
                .whereNot((id) => field.value == id)
                .toList();

            return Column(
              children: [
                OpenContainer<int?>(
                  middleColor: Theme.of(context).colorScheme.surface,
                  closedColor: Theme.of(context).colorScheme.surface,
                  openColor: Theme.of(context).colorScheme.surface,
                  closedShape: InputBorder.none,
                  openElevation: 0,
                  closedElevation: 0,
                  tappable: enabled,
                  closedBuilder: (context, openForm) {
                    return _buildSingleValueInput(
                      context,
                      displayText,
                      openForm,
                      enabled,
                      field,
                    );
                  },
                  openBuilder: (context, closeForm) => SingleLabelForm<T>(
                    addNewLabelText: addLabelText,
                    leadingIcon: prefixIcon,
                    onCreateNewLabel: onAddLabel,
                    query: query,
                    onSubmit: ({int? returnValue}) {
                      closeForm(returnValue: returnValue);
                    },
                    initialValue: field.value,
                  ),
                  onClosed: (data) {
                    field.didChange(data);
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
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: displayedSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion =
                                options[displayedSuggestions.elementAt(index)]!;

                            return ActionChip(
                              label: Text(suggestion.name),
                              onPressed: () {
                                field.didChange(suggestion.id);
                              },
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
        );
      },
    );
  }

  Widget _buildLoadingInput(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
          labelText: labelText,
          enabled: false,
        ),
        isEmpty: true,
        child: null,
      ),
    );
  }

  Widget _buildSingleValueInput(
    BuildContext context,
    String displayText,
    VoidCallback openForm,
    bool enabled,
    FormFieldState<int?> field,
  ) {
    final theme = Theme.of(context);
    final hasValue = displayText.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      child: GestureDetector(
        onTap: enabled ? openForm : null,
        child: InputDecorator(
          decoration: InputDecoration(
            prefixIcon: prefixIcon,
            labelText: labelText,
            enabled: enabled,
            suffixIcon: hasValue
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => field.didChange(null),
                  )
                : null,
          ),
          isEmpty: !hasValue,
          child: Text(displayText, style: theme.textTheme.titleMedium),
        ),
      ),
    );
  }
}
