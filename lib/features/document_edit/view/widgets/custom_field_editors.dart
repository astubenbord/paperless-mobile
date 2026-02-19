import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class CustomFieldEditSection extends StatefulWidget {
  final List<CustomFieldInstance> initialFields;
  final ValueChanged<List<CustomFieldInstance>> onChanged;

  const CustomFieldEditSection({
    super.key,
    required this.initialFields,
    required this.onChanged,
  });

  @override
  State<CustomFieldEditSection> createState() => _CustomFieldEditSectionState();
}

class _CustomFieldEditSectionState extends State<CustomFieldEditSection> {
  late List<CustomFieldInstance> _fields;
  Map<int, CustomFieldModel>? _fieldDefinitions;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fields = List.from(widget.initialFields);
    _loadFieldDefinitions();
  }

  Future<void> _loadFieldDefinitions() async {
    try {
      final api = context.read<CustomFieldsApi>();
      final fields = await api.getCustomFields();
      if (mounted) {
        setState(() {
          _fieldDefinitions = {for (var f in fields) f.id!: f};
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_fieldDefinitions == null || _fieldDefinitions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              S.of(context)!.customFields,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(S.of(context)!.addCustomField),
              onPressed: _showAddFieldDialog,
            ),
          ],
        ),
        ..._fields.map((instance) {
          final fieldDef = _fieldDefinitions![instance.id];
          if (fieldDef == null) return const SizedBox.shrink();
          return _buildFieldEditor(fieldDef, instance);
        }),
      ],
    );
  }

  Widget _buildFieldEditor(
      CustomFieldModel fieldDef, CustomFieldInstance instance) {
    final fieldIndex = _fields.indexWhere((f) => f.id == instance.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildEditorForType(fieldDef, instance, fieldIndex),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            tooltip: S.of(context)!.removeCustomField,
            onPressed: () {
              setState(() {
                _fields.removeAt(fieldIndex);
              });
              widget.onChanged(_fields);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditorForType(
    CustomFieldModel fieldDef,
    CustomFieldInstance instance,
    int index,
  ) {
    return switch (fieldDef.dataType) {
      CustomFieldDataType.text => TextFormField(
          initialValue: instance.value?.toString() ?? '',
          decoration: InputDecoration(
            labelText: fieldDef.name,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) => _updateField(index, value),
        ),
      CustomFieldDataType.integer => TextFormField(
          initialValue: instance.value?.toString() ?? '',
          decoration: InputDecoration(
            labelText: fieldDef.name,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) =>
              _updateField(index, int.tryParse(value)),
        ),
      CustomFieldDataType.number => TextFormField(
          initialValue: instance.value?.toString() ?? '',
          decoration: InputDecoration(
            labelText: fieldDef.name,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) =>
              _updateField(index, double.tryParse(value)),
        ),
      CustomFieldDataType.monetary => TextFormField(
          initialValue: instance.value?.toString() ?? '',
          decoration: InputDecoration(
            labelText: fieldDef.name,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) =>
              _updateField(index, double.tryParse(value)),
        ),
      CustomFieldDataType.boolean => SwitchListTile(
          title: Text(fieldDef.name ?? ''),
          value: instance.value == true,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) => _updateField(index, value),
        ),
      CustomFieldDataType.date => _DateFieldEditor(
          fieldDef: fieldDef,
          value: instance.value?.toString(),
          onChanged: (value) => _updateField(index, value),
        ),
      CustomFieldDataType.url => TextFormField(
          initialValue: instance.value?.toString() ?? '',
          decoration: InputDecoration(
            labelText: fieldDef.name,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          keyboardType: TextInputType.url,
          onChanged: (value) => _updateField(index, value),
        ),
    };
  }

  void _updateField(int index, dynamic value) {
    setState(() {
      _fields[index] = CustomFieldInstance(
        id: _fields[index].id,
        value: value,
      );
    });
    widget.onChanged(_fields);
  }

  void _showAddFieldDialog() {
    final existingIds = _fields.map((f) => f.id).toSet();
    final available = _fieldDefinitions!.values
        .where((f) => !existingIds.contains(f.id))
        .toList();

    if (available.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(S.of(context)!.selectField),
        children: available.map((field) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _fields.add(CustomFieldInstance(
                  id: field.id,
                  value: null,
                ));
              });
              widget.onChanged(_fields);
            },
            child: Text(field.name ?? 'Field ${field.id}'),
          );
        }).toList(),
      ),
    );
  }
}

class _DateFieldEditor extends StatelessWidget {
  final CustomFieldModel fieldDef;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _DateFieldEditor({
    required this.fieldDef,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? current;
    if (value != null && value!.isNotEmpty) {
      current = DateTime.tryParse(value!);
    }
    final displayText = current != null
        ? DateFormat.yMMMMd(Localizations.localeOf(context).toString())
            .format(current)
        : '';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: current ?? DateTime.now(),
          firstDate: DateTime(1800),
          lastDate: DateTime(2200),
        );
        if (picked != null) {
          onChanged(picked.toIso8601String().split('T').first);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: fieldDef.name,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(displayText),
      ),
    );
  }
}
