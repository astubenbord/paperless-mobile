import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/query_type.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class QueryTypeFormField extends StatelessWidget {
  static const fkQueryType = 'queryType';
  final QueryType? initialValue;
  final void Function(QueryType)? afterSelected;
  const QueryTypeFormField({
    super.key,
    this.initialValue,
    this.afterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<QueryType>(
      builder: (field) => PopupMenuButton<QueryType>(
        itemBuilder: (context) => [
          PopupMenuItem(
            child: ListTile(
              title: Text(S
                  .of(context)
                  .documentsFilterPageQueryOptionsTitleAndContentLabel),
            ),
            value: QueryType.titleAndContent,
          ),
          PopupMenuItem(
            child: ListTile(
              title:
                  Text(S.of(context).documentsFilterPageQueryOptionsTitleLabel),
            ),
            value: QueryType.title,
          ),
          PopupMenuItem(
            child: ListTile(
              title: Text(
                  S.of(context).documentsFilterPageQueryOptionsExtendedLabel),
            ),
            value: QueryType.extended,
          ),
          //TODO: Add support for ASN queries
        ],
        onSelected: (selection) {
          field.didChange(selection);
          afterSelected?.call(selection);
        },
        child: const Icon(Icons.more_vert),
      ),
      initialValue: initialValue,
      name: QueryTypeFormField.fkQueryType,
    );
  }
}
