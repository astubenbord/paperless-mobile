import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/api/extensions/cached_query_extensions.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/custom_fields/boolean_field_value.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/custom_fields/date_field_value.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/custom_fields/document_link_field_value.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/custom_fields/float_field_value.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/custom_fields/integer_field_value.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/custom_fields/monetary_field_value.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/custom_fields/select_field_value.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/custom_fields/string_field_value.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/custom_fields/url_field_value.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/details_item.dart';

class CustomFieldWidget extends StatelessWidget {
  final CustomFieldInstance instance;

  const CustomFieldWidget({super.key, required this.instance});

  @override
  Widget build(BuildContext context) {
    return QueryBuilder(
      query: context.customFieldRepository.getAllQuery(),
      builder: (context, state) {
        if (state.isLoadingInitial) {
          return DetailsItemSkeleton(label: '...');
        }
        final field = state.data?.firstWhereOrNull(
          (f) => f.id == instance.field,
        );
        if (field == null || state.isError) {
          return const SizedBox.shrink();
        }
        return DetailsItem(
          label: field.name,
          content: _CustomFieldValue(
            dataType: field.dataType,
            value: instance.value,
            extraData: field.extraData,
          ),
        );
      },
    );
  }
}

/// Switches on [DataTypeEnum] and renders the appropriate read-only widget for
/// the custom field value.
class _CustomFieldValue extends StatelessWidget {
  final DataTypeEnum dataType;
  final Object? value;
  final Object? extraData;

  const _CustomFieldValue({
    required this.dataType,
    required this.value,
    this.extraData,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    final placeholder = Text('-', style: textStyle);

    return switch (dataType) {
      DataTypeEnum.string => StringFieldValue(
        value: value,
        style: textStyle,
        placeholder: placeholder,
      ),
      DataTypeEnum.url => UrlFieldValue(
        value: value,
        style: textStyle,
        placeholder: placeholder,
      ),
      DataTypeEnum.date => DateFieldValue(
        value: value,
        style: textStyle,
        placeholder: placeholder,
      ),
      DataTypeEnum.boolean => BooleanFieldValue(
        value: value,
        style: textStyle,
        placeholder: placeholder,
      ),
      DataTypeEnum.integer => IntegerFieldValue(
        value: value,
        style: textStyle,
        placeholder: placeholder,
      ),
      DataTypeEnum.float => FloatFieldValue(
        value: value,
        style: textStyle,
        placeholder: placeholder,
      ),
      DataTypeEnum.monetary => MonetaryFieldValue(
        value: value,
        style: textStyle,
        placeholder: placeholder,
      ),
      DataTypeEnum.documentlink => DocumentLinkFieldValue(
        value: value,
        style: textStyle,
        placeholder: placeholder,
      ),
      DataTypeEnum.select => SelectFieldValue(
        id: value,
        extraData: extraData,
        style: textStyle,
        placeholder: placeholder,
      ),
    };
  }
}
