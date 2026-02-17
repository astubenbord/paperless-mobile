import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';

import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/features/login/view/test_keys.dart';

class ServerAddressFormField extends StatefulWidget {
  static const String fkServerAddress = "serverAddress";
  final String? initialValue;
  final ValueChanged<String?>? onChanged;

  const ServerAddressFormField({
    super.key,
    this.onChanged,
    this.initialValue,
  });

  @override
  State<ServerAddressFormField> createState() => _ServerAddressFormFieldState();
}

class _ServerAddressFormFieldState extends State<ServerAddressFormField>
    with AutomaticKeepAliveClientMixin {
  bool _canClear = false;
  final _textFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(() {
      setState(() {
        _canClear = _textEditingController.text.isNotEmpty;
      });
    });
  }

  final _focusNode = FocusNode();
  final _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FormBuilderField<String>(
      initialValue: widget.initialValue,
      name: ServerAddressFormField.fkServerAddress,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: widget.onChanged,
      builder: (field) {
        return RawAutocomplete<String>(
          focusNode: _focusNode,
          textEditingController: _textEditingController,
          optionsViewBuilder: (context, onSelected, options) {
            return _AutocompleteOptions(
              onSelected: onSelected,
              options: options,
              maxOptionsHeight: 200.0,
              maxWidth: MediaQuery.sizeOf(context).width - 40,
            );
          },
          key: TestKeys.login.serverAddressFormField,
          optionsBuilder: (textEditingValue) {
            return Hive.box<String>(HiveBoxes.hosts)
                .values
                .where((element) => element.contains(textEditingValue.text));
          },
          onSelected: (option) {
            _formatInput(field);
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              key: _textFieldKey,
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: "http://192.168.1.50:8000",
                labelText: S.of(context)!.serverAddress,
                suffixIcon: _canClear
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        color: Theme.of(context).iconTheme.color,
                        onPressed: () {
                          textEditingController.clear();
                          field.didChange(textEditingController.text);
                        },
                      )
                    : null,
              ),
              autofocus: false,
              onFieldSubmitted: (_) {
                _formatInput(field);
                onFieldSubmitted();
              },
              onTapOutside: (event) {
                if (!FocusScope.of(context).hasFocus) {
                  return;
                }
                _formatInput(field);
                onFieldSubmitted();
                FocusScope.of(context).unfocus();
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return S.of(context)!.serverAddressMustNotBeEmpty;
                }
                if (!RegExp(r"^https?://.*").hasMatch(value!)) {
                  return S.of(context)!.serverAddressMustIncludeAScheme;
                }
                return null;
              },
              keyboardType: TextInputType.url,
              onChanged: (value) {
                field.didChange(value);
              },
              onEditingComplete: () {
                field.didChange(_textEditingController.text);
                _focusNode.unfocus();
              },
            );
          },
        );
      },
    );
  }

  void _formatInput(FormFieldState<String> field) {
    String address = _textEditingController.text.trim();
    address = address.replaceAll(RegExp(r'^\/+|\/+$'), '');
    _textEditingController.text = address;
    _textEditingController.selection = TextSelection(
      baseOffset: address.length,
      extentOffset: address.length,
    );
    field.didChange(_textEditingController.text);
  }

  @override
  bool get wantKeepAlive => true;
}

/// Taken from [Autocomplete]
class _AutocompleteOptions extends StatelessWidget {
  const _AutocompleteOptions({
    required this.onSelected,
    required this.options,
    required this.maxOptionsHeight,
    required this.maxWidth,
  });

  final AutocompleteOnSelected<String> onSelected;

  final Iterable<String> options;
  final double maxOptionsHeight;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxOptionsHeight,
            maxWidth: maxWidth,
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (BuildContext context, int index) {
              final option = options.elementAt(index);
              return InkWell(
                onTap: () {
                  onSelected(option);
                },
                child: Builder(builder: (BuildContext context) {
                  final bool highlight =
                      AutocompleteHighlightedOption.of(context) == index;
                  if (highlight) {
                    SchedulerBinding.instance
                        .addPostFrameCallback((Duration timeStamp) {
                      Scrollable.ensureVisible(context, alignment: 0.5);
                    });
                  }
                  return Container(
                    color: highlight ? Theme.of(context).focusColor : null,
                    padding: const EdgeInsets.all(16.0),
                    child: Text(option),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
