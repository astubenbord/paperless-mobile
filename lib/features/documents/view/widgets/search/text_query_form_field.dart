import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class TextQueryFormField extends StatelessWidget {
  final String name;
  final TextQuery? initialValue;
  final bool onlyExtendedQueryAllowed;

  const TextQueryFormField({
    super.key,
    required this.name,
    this.initialValue,
    required this.onlyExtendedQueryAllowed,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<TextQuery>(
      name: name,
      initialValue: initialValue,
      builder: (field) {
        return TextFormField(
          initialValue: initialValue?.queryText,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_outlined),
            labelText: _buildLabelText(context, field.value!.queryType),
            suffixIcon: PopupMenuButton<QueryType>(
              icon: onlyExtendedQueryAllowed
                  ? Icon(
                      Icons.more_vert,
                      color: Theme.of(context).disabledColor,
                    )
                  : null,
              enabled: !onlyExtendedQueryAllowed,
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: ListTile(
                    title: Text(S
                        .of(context)
                        .documentFilterQueryOptionsTitleAndContentLabel),
                  ),
                  value: QueryType.titleAndContent,
                ),
                PopupMenuItem(
                  child: ListTile(
                    title: Text(
                        S.of(context).documentFilterQueryOptionsTitleLabel),
                  ),
                  value: QueryType.title,
                ),
                PopupMenuItem(
                  child: ListTile(
                    title: Text(
                        S.of(context).documentFilterQueryOptionsExtendedLabel),
                  ),
                  value: QueryType.extended,
                ),
              ],
              onSelected: (selection) {
                field.didChange(field.value?.copyWith(queryType: selection));
              },
            ),
          ),
          onChanged: (value) {
            field.didChange(field.value?.copyWith(queryText: value));
          },
        );
      },
    );
  }

  String _buildLabelText(BuildContext context, QueryType queryType) {
    switch (queryType) {
      case QueryType.title:
        return S.of(context).documentFilterQueryOptionsTitleLabel;
      case QueryType.titleAndContent:
        return S.of(context).documentFilterQueryOptionsTitleAndContentLabel;
      case QueryType.extended:
        return S.of(context).documentFilterQueryOptionsExtendedLabel;
      default:
        return '';
    }
  }
}
