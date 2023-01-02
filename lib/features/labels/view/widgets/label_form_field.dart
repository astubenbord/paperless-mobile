import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/form_builder_type_ahead.dart';
import 'package:paperless_mobile/generated/l10n.dart';

///
/// Form field allowing to select labels (i.e. correspondent, documentType)
/// [T] is the label type (e.g. [DocumentType], [Correspondent], ...), [R] is the return type (e.g. [CorrespondentQuery], ...).
///
class LabelFormField<T extends Label> extends StatefulWidget {
  final Widget prefixIcon;
  final Map<int, T> labelOptions;
  final FormBuilderState? formBuilderState;
  final IdQueryParameter? initialValue;
  final String name;
  final String textFieldLabel;
  final FormFieldValidator? validator;
  final Widget Function(String initialName)? labelCreationWidgetBuilder;
  final bool notAssignedSelectable;
  final void Function(IdQueryParameter?)? onChanged;

  const LabelFormField({
    Key? key,
    required this.name,
    required this.labelOptions,
    this.validator,
    this.initialValue,
    required this.textFieldLabel,
    this.labelCreationWidgetBuilder,
    required this.formBuilderState,
    required this.prefixIcon,
    this.notAssignedSelectable = true,
    this.onChanged,
  }) : super(key: key);

  @override
  State<LabelFormField<T>> createState() => _LabelFormFieldState<T>();
}

class _LabelFormFieldState<T extends Label> extends State<LabelFormField<T>> {
  bool _showCreationSuffixIcon = false;
  late bool _showClearSuffixIcon;

  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _showClearSuffixIcon =
        widget.labelOptions.containsKey(widget.initialValue?.id);
    _textEditingController = TextEditingController(
      text: widget.labelOptions[widget.initialValue?.id]?.name ?? '',
    )..addListener(() {
        setState(() {
          _showCreationSuffixIcon = widget.labelOptions.values
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
    final isEnabled = widget.labelOptions.values.fold<bool>(
            false,
            (previousValue, element) =>
                previousValue || (element.documentCount ?? 0) > 0) ||
        widget.labelCreationWidgetBuilder != null;
    return FormBuilderTypeAhead<IdQueryParameter>(
      enabled: isEnabled,
      noItemsFoundBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          S.of(context).labelFormFieldNoItemsFoundText,
          textAlign: TextAlign.center,
          style:
              TextStyle(color: Theme.of(context).disabledColor, fontSize: 18.0),
        ),
      ),
      getImmediateSuggestions: true,
      loadingBuilder: (context) => Container(),
      initialValue: widget.initialValue ?? const IdQueryParameter.unset(),
      name: widget.name,
      suggestionsBoxDecoration: SuggestionsBoxDecoration(
        elevation: 4.0,
        shadowColor: Theme.of(context).colorScheme.primary,
        // color: Theme.of(context).colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          // side: BorderSide(
          //   color: Theme.of(context).colorScheme.primary,
          //   width: 2.0,
          // ),
        ),
      ),
      itemBuilder: (context, suggestion) => ListTile(
        title: Text(
          widget.labelOptions[suggestion.id]?.name ??
              S.of(context).labelNotAssignedText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // tileColor: Theme.of(context).colorScheme.surfaceVariant,
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        style: ListTileStyle.list,
      ),
      suggestionsCallback: (pattern) {
        final List<IdQueryParameter> suggestions = widget.labelOptions.entries
            .where(
              (entry) =>
                  widget.labelOptions[entry.key]!.name
                      .toLowerCase()
                      .contains(pattern.toLowerCase()) ||
                  pattern.isEmpty,
            )
            .where(
              (entry) =>
                  widget.labelCreationWidgetBuilder != null ||
                  (entry.value.documentCount ?? 0) > 0,
            )
            .map((entry) => IdQueryParameter.fromId(entry.key))
            .toList();
        if (widget.notAssignedSelectable) {
          suggestions.insert(0, const IdQueryParameter.notAssigned());
        }
        return suggestions;
      },
      onChanged: (value) {
        setState(() => _showClearSuffixIcon = value?.isSet ?? false);
        widget.onChanged?.call(value);
      },
      controller: _textEditingController,
      decoration: InputDecoration(
        prefixIcon: widget.prefixIcon,
        label: Text(widget.textFieldLabel),
        hintText: _getLocalizedHint(context),
        suffixIcon: _buildSuffixIcon(context),
      ),
      selectionToTextTransformer: (suggestion) {
        if (suggestion == const IdQueryParameter.notAssigned()) {
          return S.of(context).labelNotAssignedText;
        }
        return widget.labelOptions[suggestion.id]?.name ?? "";
      },
      direction: AxisDirection.up,
      onSuggestionSelected: (suggestion) =>
          widget.formBuilderState?.fields[widget.name]?.didChange(suggestion),
    );
  }

  Widget? _buildSuffixIcon(BuildContext context) {
    if (_showCreationSuffixIcon && widget.labelCreationWidgetBuilder != null) {
      return IconButton(
        onPressed: () async {
          FocusScope.of(context).unfocus();
          final createdLabel = await showDialog<T>(
            context: context,
            builder: (context) => widget.labelCreationWidgetBuilder!(
              _textEditingController.text,
            ),
          );
          if (createdLabel != null) {
            // If new label has been created, set form field value and text of this form field and unfocus keyboard (we assume user is done).
            widget.formBuilderState?.fields[widget.name]
                ?.didChange(IdQueryParameter.fromId(createdLabel.id));
            _textEditingController.text = createdLabel.name;
          } else {
            _reset();
          }
        },
        icon: const Icon(
          Icons.new_label,
        ),
      );
    }
    if (_showClearSuffixIcon) {
      return IconButton(
        icon: const Icon(Icons.clear),
        onPressed: _reset,
      );
    }
    return null;
  }

  void _reset() {
    widget.formBuilderState?.fields[widget.name]?.didChange(
      const IdQueryParameter.unset(),
    );
    _textEditingController.clear();
  }

  String _getLocalizedHint(BuildContext context) {
    if (T == Correspondent) {
      return S.of(context).correspondentFormFieldSearchHintText;
    } else if (T == DocumentType) {
      return S.of(context).documentTypeFormFieldSearchHintText;
    } else {
      return S.of(context).tagFormFieldSearchHintText;
    }
  }
}
