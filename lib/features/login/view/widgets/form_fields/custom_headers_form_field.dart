import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class CustomHeadersFormField extends StatefulWidget {
  static const String fkCustomHeaders = 'custom_headers';

  final Map<String, String> initialHeaders;

  const CustomHeadersFormField({
    super.key,
    this.initialHeaders = const {},
  });

  @override
  State<CustomHeadersFormField> createState() => _CustomHeadersFormFieldState();
}

class _CustomHeadersFormFieldState extends State<CustomHeadersFormField> {
  late List<_HeaderEntry> _headers;

  @override
  void initState() {
    super.initState();
    _headers = widget.initialHeaders.entries
        .map((e) => _HeaderEntry(
              keyController: TextEditingController(text: e.key),
              valueController: TextEditingController(text: e.value),
            ))
        .toList();
    // Ajouter une ligne vide par défaut
    if (_headers.isEmpty) {
      _headers.add(_HeaderEntry(
        keyController: TextEditingController(),
        valueController: TextEditingController(),
      ));
    }
  }

  @override
  void dispose() {
    for (var header in _headers) {
      header.keyController.dispose();
      header.valueController.dispose();
    }
    super.dispose();
  }

  void _addHeader() {
    setState(() {
      _headers.add(_HeaderEntry(
        keyController: TextEditingController(),
        valueController: TextEditingController(),
      ));
    });
  }

  void _removeHeader(int index) {
    setState(() {
      _headers[index].keyController.dispose();
      _headers[index].valueController.dispose();
      _headers.removeAt(index);
    });
  }

  Map<String, String> _getHeadersMap() {
    final result = <String, String>{};
    for (var header in _headers) {
      final key = header.keyController.text.trim();
      final value = header.valueController.text.trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        result[key] = value;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<Map<String, String>>(
      name: CustomHeadersFormField.fkCustomHeaders,
      initialValue: _getHeadersMap(),
      onChanged: (value) {
        // Update the field value whenever headers change
      },
      builder: (FormFieldState<Map<String, String>> field) {
        final theme =
            Theme.of(context).copyWith(dividerColor: Colors.transparent);
        return Theme(
          data: theme,
          child: ExpansionTile(
            title: Text(S.of(context)!.customHeaders),
            subtitle: Text(S.of(context)!.customHeadersDescription),
            children: [
              ..._headers.asMap().entries.map((entry) {
                final index = entry.key;
                final header = entry.value;
                return _HeaderInputRow(
                  keyController: header.keyController,
                  valueController: header.valueController,
                  onRemove: _headers.length > 1
                      ? () => _removeHeader(index)
                      : null,
                  onChanged: () {
                    field.didChange(_getHeadersMap());
                  },
                );
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addHeader,
                    icon: const Icon(Icons.add),
                    label: Text(S.of(context)!.addHeader),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderEntry {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _HeaderEntry({
    required this.keyController,
    required this.valueController,
  });
}

class _HeaderInputRow extends StatelessWidget {
  final TextEditingController keyController;
  final TextEditingController valueController;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _HeaderInputRow({
    required this.keyController,
    required this.valueController,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: TextField(
              controller: keyController,
              decoration: InputDecoration(
                hintText: S.of(context)!.headerKey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextField(
              controller: valueController,
              decoration: InputDecoration(
                hintText: S.of(context)!.headerValue,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onRemove,
              tooltip: S.of(context)!.removeHeader,
            ),
        ],
      ),
    );
  }
}
