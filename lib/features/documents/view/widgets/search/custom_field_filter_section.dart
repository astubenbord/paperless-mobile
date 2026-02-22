import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:provider/provider.dart';

class CustomFieldFilterSection extends StatefulWidget {
  final String name;
  final List<CustomFieldQueryClause>? initialClauses;

  const CustomFieldFilterSection({
    super.key,
    required this.name,
    this.initialClauses,
  });

  @override
  State<CustomFieldFilterSection> createState() =>
      _CustomFieldFilterSectionState();
}

class _CustomFieldFilterSectionState extends State<CustomFieldFilterSection> {
  late List<_ClauseEntry> _clauses;
  List<CustomFieldModel>? _availableFields;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _clauses = (widget.initialClauses ?? [])
        .map((c) => _ClauseEntry(
              fieldId: c.fieldId,
              operator: c.operator,
              value: c.value?.toString() ?? '',
            ))
        .toList();
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final fields = await context.read<CustomFieldsApi>().getCustomFields();
      if (mounted) {
        setState(() {
          _availableFields = fields;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _addClause() {
    if (_availableFields == null || _availableFields!.isEmpty) return;
    setState(() {
      _clauses.add(_ClauseEntry(
        fieldId: _availableFields!.first.id!,
        operator: 'icontains',
        value: '',
      ));
    });
    _updateFormValue();
  }

  void _removeClause(int index) {
    setState(() => _clauses.removeAt(index));
    _updateFormValue();
  }

  void _updateFormValue() {
    final validClauses = _clauses
        .where((c) => c.value.isNotEmpty)
        .map((c) => CustomFieldQueryClause(
              fieldId: c.fieldId,
              operator: c.operator,
              value: c.value,
            ))
        .toList();
    FormBuilder.of(context)
        ?.fields[widget.name]
        ?.didChange(validClauses.isEmpty ? null : validClauses);
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<List<CustomFieldQueryClause>>(
      name: widget.name,
      initialValue: widget.initialClauses,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Custom Fields',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (!_loading && _availableFields != null && _availableFields!.isNotEmpty)
                  TextButton.icon(
                    onPressed: _addClause,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
              ],
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_availableFields == null || _availableFields!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'No custom fields available',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ..._clauses.asMap().entries.map((entry) {
                final index = entry.key;
                final clause = entry.value;
                return _ClauseRow(
                  clause: clause,
                  availableFields: _availableFields!,
                  onChanged: () {
                    _updateFormValue();
                  },
                  onRemove: () => _removeClause(index),
                );
              }),
          ],
        );
      },
    );
  }
}

class _ClauseEntry {
  int fieldId;
  String operator;
  String value;

  _ClauseEntry({
    required this.fieldId,
    required this.operator,
    required this.value,
  });
}

const _operators = [
  ('exact', 'Equals'),
  ('icontains', 'Contains'),
  ('istartswith', 'Starts with'),
  ('gt', 'Greater than'),
  ('lt', 'Less than'),
  ('isnull', 'Is empty'),
];

class _ClauseRow extends StatelessWidget {
  final _ClauseEntry clause;
  final List<CustomFieldModel> availableFields;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _ClauseRow({
    required this.clause,
    required this.availableFields,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              initialValue: availableFields.any((f) => f.id == clause.fieldId)
                  ? clause.fieldId
                  : availableFields.first.id,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: availableFields
                  .map((f) => DropdownMenuItem(
                        value: f.id,
                        child: Text(
                          f.name ?? 'Field ${f.id}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  clause.fieldId = v;
                  onChanged();
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: clause.operator,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: _operators
                  .map((op) => DropdownMenuItem(
                        value: op.$1,
                        child: Text(op.$2, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  clause.operator = v;
                  onChanged();
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          if (clause.operator != 'isnull')
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: clause.value,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Value',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (v) {
                  clause.value = v;
                  onChanged();
                },
              ),
            ),
          if (clause.operator == 'isnull')
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                initialValue: clause.value.isEmpty ? 'true' : clause.value,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'true', child: Text('Yes')),
                  DropdownMenuItem(value: 'false', child: Text('No')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    clause.value = v;
                    onChanged();
                  }
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
