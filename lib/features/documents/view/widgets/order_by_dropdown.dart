import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/sort_field.dart';

class OrderByDropdown extends StatefulWidget {
  static const fkOrderBy = "orderBy";
  const OrderByDropdown({super.key});

  @override
  State<OrderByDropdown> createState() => _OrderByDropdownState();
}

class _OrderByDropdownState extends State<OrderByDropdown> {
  @override
  Widget build(BuildContext context) {
    return FormBuilderDropdown<SortField>(
      name: OrderByDropdown.fkOrderBy,
      items: const [],
    );
  }
}
