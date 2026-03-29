// ignore_for_file: invalid_use_of_protected_member

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:paperless_mobile/api/constants/api_date_format.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/landing/view/widgets/mime_types_pie_chart.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

final _separatorRegex = RegExp(r'\d+(?<separator>\D+).*');

class FormDateTime {
  final int? day;
  final int? month;
  final int? year;

  FormDateTime({this.day, this.month, this.year});

  FormDateTime.fromDateTime(DateTime date)
    : day = date.day,
      month = date.month,
      year = date.year;

  FormDateTime copyWith({int? day, int? month, int? year}) {
    return FormDateTime(
      day: day ?? this.day,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  bool get isComplete => day != null && month != null && year != null;

  DateTime? toDateTime() {
    if (day == null || month == null || year == null) {
      return null;
    }
    return DateTime(year!, month!, day!);
  }
}

/// A localized, segmented date input field.
class FormBuilderLocalizedDatePicker extends StatefulWidget {
  final String name;
  final String labelText;
  final Widget? prefixIcon;
  final DateTime? initialValue;
  final DateTime firstDate;
  final DateTime lastDate;
  final FocusNode? focusNode;

  /// If set to true, the field will not throw any validation errors when empty.
  final bool allowUnset;

  const FormBuilderLocalizedDatePicker({
    super.key,
    required this.name,
    this.initialValue,
    required this.firstDate,
    required this.lastDate,
    required this.labelText,
    this.prefixIcon,
    this.allowUnset = false,
    this.focusNode,
  });

  @override
  State<FormBuilderLocalizedDatePicker> createState() =>
      _FormBuilderLocalizedDatePickerState();
}

class _FormBuilderLocalizedDatePickerState
    extends State<FormBuilderLocalizedDatePicker> {
  bool _initialized = false;
  late final String _separator;
  late final String _format;

  final _textFieldControls =
      LinkedList<_NeighbourAwareDateInputSegmentControls>();
  bool _temporarilyDisableListeners = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final date = DateTime(1000, 11, 22);
    final format = context.dateLocale == 'iso-8601'
        ? apiDateFormat.format(date)
        : DateFormat.yMd(context.dateLocale).format(date);
    _separator =
        _separatorRegex.firstMatch(format)?.namedGroup('separator') ?? '.';
    _format = format
        .replaceAll("1000", "yyyy")
        .replaceAll("11", "MM")
        .replaceAll("22", "dd");

    final components = _format.split(_separator);
    for (int i = 0; i < components.length; i++) {
      final formatString = components[i].replaceAll(
        RegExp('[${RegExp.escape(_separator)}]'),
        '',
      );
      final initialText = widget.initialValue != null
          ? DateFormat(formatString).format(widget.initialValue!)
          : null;
      final defaultFocusNode = FocusNode(debugLabel: formatString);
      final focusNode = i == 0
          ? (widget.focusNode ?? defaultFocusNode)
          : defaultFocusNode;
      final controls = _NeighbourAwareDateInputSegmentControls(
        node: focusNode,
        controller: TextEditingController(text: initialText),
        format: formatString,
        position: i,
        type: _DateInputSegment.fromPattern(formatString),
      );
      _textFieldControls.add(controls);
      controls.controller.addListener(() {
        if (_temporarilyDisableListeners) {
          return;
        }
        if (controls.controller.selection.isCollapsed &&
            controls.controller.text.length == controls.format.length) {
          controls.next?.node.requestFocus();
        }
      });
      controls.node.addListener(() {
        if (_temporarilyDisableListeners || !controls.node.hasFocus) {
          return;
        }
        controls.controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controls.controller.text.length,
        );
      });
    }
  }

  @override
  void dispose() {
    for (var controls in _textFieldControls) {
      controls.node.dispose();
      controls.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (value) {
        if (value.logicalKey == LogicalKeyboardKey.backspace &&
            value is KeyDownEvent) {
          final currentFocus = _textFieldControls
              .where((element) => element.node.hasFocus)
              .firstOrNull;
          if (currentFocus == null) {
            return;
          }
          if (currentFocus.controller.text.isEmpty) {
            currentFocus.previous?.node.requestFocus();
            final endOffset = currentFocus.previous?.controller.text.length;
            currentFocus.previous?.controller.selection =
                TextSelection.collapsed(offset: endOffset ?? 0);
          }
        }
      },
      child: FormBuilderField<FormDateTime>(
        name: widget.name,
        validator: _validateDate,
        onChanged: (value) {
          assert(!widget.allowUnset && value != null);
          if (value == null) {
            return;
          }
          // When the change is requested from external sources, such as calling
          // field.didChange(value), then we want to update the text fields individually
          // without causing the either field to gain focus (as defined above).
          final isChangeRequestedFromOutside = _textFieldControls.none(
            (element) => element.node.hasFocus,
          );

          if (isChangeRequestedFromOutside) {
            _updateInputsWithDate(value, disableListeners: true);
          }
          // Imitate the functionality of the validator function in "normal" form fields.
          // The error is shown on the outer decorator as if this was a regular text input.
          // Errors are cleared after the next user interaction.
          // final error = _validateDate(value);
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        initialValue: widget.initialValue != null
            ? FormDateTime.fromDateTime(widget.initialValue!)
            : null,
        builder: (field) {
          return GestureDetector(
            onTap: () {
              _textFieldControls.first.node.requestFocus();
            },
            child: InputDecorator(
              textAlignVertical: TextAlignVertical.bottom,
              decoration: InputDecoration(
                errorText: field.errorText,
                labelText: widget.labelText,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_month_outlined),
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate:
                              field.value?.toDateTime() ?? DateTime.now(),
                          firstDate: widget.firstDate,
                          lastDate: widget.lastDate,
                          initialEntryMode: DatePickerEntryMode.calendarOnly,
                        );
                        if (selectedDate != null) {
                          final formDate = FormDateTime.fromDateTime(
                            selectedDate,
                          );
                          _temporarilyDisableListeners = true;
                          _updateInputsWithDate(formDate);
                          field.didChange(formDate);
                          _temporarilyDisableListeners = false;
                        }
                      },
                    ),
                    if (widget.allowUnset)
                      IconButton(
                        onPressed: () {
                          for (var c in _textFieldControls) {
                            c.controller.clear();
                          }
                          _textFieldControls.first.node.requestFocus();
                          field.didChange(null);
                        },
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                ).paddedOnly(right: 4),
              ),
              child: Row(
                children: [
                  for (var s in _textFieldControls) ...[
                    IntrinsicWidth(
                      child: _buildDateSegmentInput(s, context, field),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ).paddedOnly(top: 4),
    );
  }

  String? _validateDate(FormDateTime? date) {
    if (widget.allowUnset && date == null) {
      return null;
    }
    if (date == null) {
      return S.of(context)!.thisFieldIsRequired;
    }
    final d = date.toDateTime();
    if (d == null) {
      return S.of(context)!.thisFieldIsRequired;
    }
    if (d.day != date.day && d.month != date.month && d.year != date.year) {
      return "Invalid date.";
    }
    if (d.isBefore(widget.firstDate) || d.isAfter(widget.lastDate)) {
      return S.of(context)!.dateOutOfRange(widget.firstDate, widget.lastDate);
    }

    return null;
  }

  void _updateInputsWithDate(
    FormDateTime date, {
    bool disableListeners = false,
  }) {
    if (disableListeners) {
      _temporarilyDisableListeners = true;
    }
    for (var controls in _textFieldControls) {
      final value = DateFormat(controls.format).format(date.toDateTime()!);
      controls.controller.text = value;
    }
    _temporarilyDisableListeners = false;
  }

  Widget _buildDateSegmentInput(
    _NeighbourAwareDateInputSegmentControls controls,
    BuildContext context,
    FormFieldState<FormDateTime> field,
  ) {
    return TextFormField(
      onFieldSubmitted: (value) {
        if (value.length < controls.format.length) {
          controls.controller.text = value.padLeft(controls.format.length, '0');
        }
        controls.next?.node.requestFocus();
      },
      style: const TextStyle(fontFamily: 'RobotoMono'),
      keyboardType: TextInputType.datetime,
      textInputAction: controls.position < 2
          ? TextInputAction.next
          : TextInputAction.done,
      controller: controls.controller,
      focusNode: _textFieldControls.elementAt(controls.position).node,
      maxLength: controls.format.length,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      enableInteractiveSelection: false,
      onChanged: (value) {
        if (value.isEmpty) {
          final fieldValue = field.value ?? FormDateTime();

          final newValue = switch (controls.type) {
            _DateInputSegment.day => FormDateTime(
              year: fieldValue.year,
              month: fieldValue.month,
            ),
            _DateInputSegment.month => FormDateTime(
              year: fieldValue.year,
              day: fieldValue.day,
            ),
            _DateInputSegment.year => FormDateTime(
              month: fieldValue.month,
              day: fieldValue.day,
            ),
          };
          field.setValue(newValue);
        } else if (value.length == controls.format.length) {
          final number = int.tryParse(value);
          if (number == null) {
            return;
          }
          final fieldValue = field.value ?? FormDateTime();
          final newValue = switch (controls.type) {
            _DateInputSegment.day => fieldValue.copyWith(day: number),
            _DateInputSegment.month => fieldValue.copyWith(month: number),
            _DateInputSegment.year => fieldValue.copyWith(year: number),
          };
          field.setValue(newValue);
          field.validate();
        }
      },
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        RangeLimitedInputFormatter(1, switch (controls.type) {
          _DateInputSegment.day => 31,
          _DateInputSegment.month => 12,
          _DateInputSegment.year => 9999,
        }),
      ],
      onEditingComplete: () {
        if (field.value != null) {
          _updateInputsWithDate(field.value!, disableListeners: true);
        }
        FocusScope.of(context).unfocus();
      },
      decoration: InputDecoration(
        isDense: true,
        suffixIcon: controls.position < 2
            ? Text(
                _separator,
                style: const TextStyle(fontFamily: 'RobotoMono'),
              ).paddedSymmetrically(horizontal: 2)
            : null,
        suffixIconConstraints: const BoxConstraints.tightFor(),
        fillColor: Colors.blue.values[controls.position],
        counterText: '',
        contentPadding: EdgeInsets.zero,
        hintText: controls.format,
        hintStyle: const TextStyle(fontFamily: "RobotoMono"),
        border: Theme.of(context).inputDecorationTheme.border?.copyWith(
          borderSide: const BorderSide(width: 0, style: BorderStyle.none),
        ),
      ),
    );
  }
}

enum _DateInputSegment {
  day,
  month,
  year;

  static _DateInputSegment fromPattern(String pattern) {
    final char = pattern.characters.first;
    return switch (char) {
      'd' => day,
      'M' => month,
      'y' => year,
      _ => throw ArgumentError.value(pattern),
    };
  }
}

final class _NeighbourAwareDateInputSegmentControls
    with LinkedListEntry<_NeighbourAwareDateInputSegmentControls> {
  final FocusNode node;
  final TextEditingController controller;
  final int position;
  final String format;
  final _DateInputSegment type;

  _NeighbourAwareDateInputSegmentControls({
    required this.node,
    required this.controller,
    required this.format,
    required this.position,
    required this.type,
  });
}

class RangeLimitedInputFormatter extends TextInputFormatter {
  RangeLimitedInputFormatter(this.minimum, this.maximum)
    : assert(minimum < maximum);

  final int minimum;
  final int maximum;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < 2) {
      return newValue;
    }
    var value = int.parse(newValue.text);
    final lastCharacter = newValue.text.characters.last;
    if (value < minimum || value > maximum) {
      return TextEditingValue(
        text: lastCharacter,
        selection: TextSelection.collapsed(offset: 1),
      );
    }
    return newValue;
  }
}
