import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';

///
/// Form field allowing to select labels (i.e. correspondent, documentType)
/// [T] is the label type (e.g. [DocumentType], [Correspondent], ...), [R] is the return type (e.g. [CorrespondentQuery], ...).
///
class LabelFormField<T extends Label, R extends IdQueryParameter>
    extends StatefulWidget {
  final Widget prefixIcon;
  final Map<int, T> state;
  final FormBuilderState? formBuilderState;
  final IdQueryParameter? initialValue;
  final String name;
  final String label;
  final FormFieldValidator? validator;
  final Widget Function(String)? labelCreationWidgetBuilder;
  final R Function() queryParameterNotAssignedBuilder;
  final R Function(int? id) queryParameterIdBuilder;
  final bool notAssignedSelectable;
  final void Function(R?)? onChanged;

  const LabelFormField({
    Key? key,
    required this.name,
    required this.state,
    this.validator,
    this.initialValue,
    required this.label,
    this.labelCreationWidgetBuilder,
    required this.queryParameterNotAssignedBuilder,
    required this.queryParameterIdBuilder,
    required this.formBuilderState,
    required this.prefixIcon,
    this.notAssignedSelectable = true,
    this.onChanged,
  }) : super(key: key);

  @override
  State<LabelFormField<T, R>> createState() => _LabelFormFieldState<T, R>();
}

class _LabelFormFieldState<T extends Label, R extends IdQueryParameter>
    extends State<LabelFormField<T, R>> {
  bool _showCreationSuffixIcon = false;
  late bool _showClearSuffixIcon;

  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _showClearSuffixIcon = widget.state.containsKey(widget.initialValue?.id);
    _textEditingController = TextEditingController(
        text: widget.state[widget.initialValue?.id]?.name ?? '')
      ..addListener(() {
        setState(() {
          _showCreationSuffixIcon = widget.state.values
              .where((item) => item.name.toLowerCase().startsWith(
                    _textEditingController.text.toLowerCase(),
                  ))
              .isEmpty;
        });
        setState(() =>
            _showClearSuffixIcon = _textEditingController.text.isNotEmpty);
      });
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderTypeAhead<IdQueryParameter>(
      noItemsFoundBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          S.of(context).labelFormFieldNoItemsFoundText,
          textAlign: TextAlign.center,
          style:
              TextStyle(color: Theme.of(context).disabledColor, fontSize: 18.0),
        ),
      ),
      initialValue: widget.initialValue ?? widget.queryParameterIdBuilder(null),
      name: widget.name,
      itemBuilder: (context, suggestion) => ListTile(
        title: Text(widget.state[suggestion.id]?.name ??
            S.of(context).labelNotAssignedText),
      ),
      suggestionsCallback: (pattern) {
        final List<IdQueryParameter> suggestions = widget.state.keys
            .where((item) =>
                widget.state[item]!.name
                    .toLowerCase()
                    .startsWith(pattern.toLowerCase()) ||
                pattern.isEmpty)
            .map((id) => widget.queryParameterIdBuilder(id))
            .toList();
        if (widget.notAssignedSelectable) {
          suggestions.insert(0, widget.queryParameterNotAssignedBuilder());
        }
        return suggestions;
      },
      onChanged: (value) {
        setState(() => _showClearSuffixIcon = value?.isSet ?? false);
        widget.onChanged?.call(value as R);
      },
      controller: _textEditingController,
      decoration: InputDecoration(
        prefixIcon: widget.prefixIcon,
        label: Text(widget.label),
        hintText: _getLocalizedHint(context),
        suffixIcon: _buildSuffixIcon(context),
      ),
      selectionToTextTransformer: (suggestion) {
        if (suggestion == widget.queryParameterNotAssignedBuilder()) {
          return S.of(context).labelNotAssignedText;
        }
        return widget.state[suggestion.id]?.name ?? "";
      },
      direction: AxisDirection.up,
      onSuggestionSelected: (suggestion) => widget
          .formBuilderState?.fields[widget.name]
          ?.didChange(suggestion as R),
    );
  }

  Widget? _buildSuffixIcon(BuildContext context) {
    if (_showCreationSuffixIcon && widget.labelCreationWidgetBuilder != null) {
      return IconButton(
        onPressed: () => Navigator.of(context)
            .push<T>(MaterialPageRoute(
                builder: (context) => widget
                    .labelCreationWidgetBuilder!(_textEditingController.text)))
            .then((value) {
          if (value != null) {
            // If new label has been created, set form field value and text of this form field and unfocus keyboard (we assume user is done).
            widget.formBuilderState?.fields[widget.name]
                ?.didChange(widget.queryParameterIdBuilder(value.id));
            _textEditingController.text = value.name;
            FocusScope.of(context).unfocus();
          } else {
            _reset();
          }
        }),
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
    widget.formBuilderState?.fields[widget.name]
        ?.didChange(widget.queryParameterIdBuilder(null));
    _textEditingController.clear();
  }

  String _getLocalizedHint(BuildContext context) {
    if (T == Correspondent) {
      return S.of(context).correspondentFormFieldSearchHintText;
    } else if (T == DocumentType) {
      return S.of(context).documentTypeFormFieldSearchHintText;
    } else {
      return S
          .of(context)
          .tagFormFieldSearchHintText; //TODO: Update tag form field once there is multi selection support.
    }
  }
}
