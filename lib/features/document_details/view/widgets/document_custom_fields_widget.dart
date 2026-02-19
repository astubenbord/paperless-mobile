import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/details_item.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentCustomFieldsWidget extends StatefulWidget {
  final DocumentModel document;
  final double itemSpacing;

  const DocumentCustomFieldsWidget({
    super.key,
    required this.document,
    required this.itemSpacing,
  });

  @override
  State<DocumentCustomFieldsWidget> createState() =>
      _DocumentCustomFieldsWidgetState();
}

class _DocumentCustomFieldsWidgetState
    extends State<DocumentCustomFieldsWidget> {
  Map<int, CustomFieldModel>? _fieldDefinitions;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.document.customFields.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _fieldDefinitions == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Fields',
          style: Theme.of(context).textTheme.titleMedium,
        ).paddedOnly(bottom: 8),
        ...widget.document.customFields.map((instance) {
          final fieldDef = _fieldDefinitions![instance.id];
          if (fieldDef == null) return const SizedBox.shrink();
          return _buildFieldItem(context, fieldDef, instance)
              .paddedOnly(bottom: widget.itemSpacing);
        }),
      ],
    );
  }

  Widget _buildFieldItem(
    BuildContext context,
    CustomFieldModel fieldDef,
    CustomFieldInstance instance,
  ) {
    return DetailsItem(
      label: fieldDef.name ?? 'Unknown Field',
      content: _buildFieldValue(context, fieldDef.dataType, instance.value),
    );
  }

  Widget _buildFieldValue(
    BuildContext context,
    CustomFieldDataType dataType,
    dynamic value,
  ) {
    if (value == null) {
      return Text(
        '-',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    final textStyle = Theme.of(context).textTheme.bodyLarge;

    return switch (dataType) {
      CustomFieldDataType.text => Text(
          value.toString(),
          style: textStyle,
        ),
      CustomFieldDataType.boolean => Row(
          children: [
            Icon(
              value == true ? Icons.check_circle : Icons.cancel,
              color: value == true
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              value == true ? 'Yes' : 'No',
              style: textStyle,
            ),
          ],
        ),
      CustomFieldDataType.date => Text(
          _formatDate(value.toString(), context),
          style: textStyle,
        ),
      CustomFieldDataType.url => InkWell(
          onTap: () => _launchUrl(value.toString()),
          child: Text(
            value.toString(),
            style: textStyle?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      CustomFieldDataType.integer => Text(
          value.toString(),
          style: textStyle,
        ),
      CustomFieldDataType.number => Text(
          _formatNumber(value),
          style: textStyle,
        ),
      CustomFieldDataType.monetary => Text(
          _formatMonetary(value),
          style: textStyle,
        ),
    };
  }

  String _formatDate(String dateStr, BuildContext context) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat.yMMMMd(Localizations.localeOf(context).toString())
          .format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatNumber(dynamic value) {
    if (value is num) {
      return NumberFormat.decimalPattern().format(value);
    }
    return value.toString();
  }

  String _formatMonetary(dynamic value) {
    if (value is num) {
      return NumberFormat.currency(symbol: '', decimalDigits: 2).format(value);
    }
    return value.toString();
  }

  Future<void> _launchUrl(String urlStr) async {
    final uri = Uri.tryParse(urlStr);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
