import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/sort_field.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/sort_order.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/sort_field_selection_bottom_sheet.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

class SortDocumentsButton extends StatefulWidget {
  const SortDocumentsButton({
    Key? key,
  }) : super(key: key);

  @override
  State<SortDocumentsButton> createState() => _SortDocumentsButtonState();
}

class _SortDocumentsButtonState extends State<SortDocumentsButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.sort),
      onPressed: _onOpenSortBottomSheet,
    );
  }

  void _onOpenSortBottomSheet() {
    showModalBottomSheet(
      elevation: 2,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => BlocProvider.value(
        value: getIt<DocumentsCubit>(),
        child: FractionallySizedBox(
          heightFactor: .6,
          child: const SortFieldSelectionBottomSheet(),
        ),
      ),
    );
  }
}
