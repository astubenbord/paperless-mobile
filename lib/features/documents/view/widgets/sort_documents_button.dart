import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/sort_field_selection_bottom_sheet.dart';

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
      icon: const Icon(Icons.sort),
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
      builder: (context) => FractionallySizedBox(
        heightFactor: .6,
        child: BlocBuilder<DocumentsCubit, DocumentsState>(
          builder: (context, state) {
            return SortFieldSelectionBottomSheet(
              initialSortField: state.filter.sortField,
              initialSortOrder: state.filter.sortOrder,
              onSubmit: (field, order) =>
                  BlocProvider.of<DocumentsCubit>(context).updateCurrentFilter(
                (filter) => filter.copyWith(sortField: field, sortOrder: order),
              ),
            );
          },
        ),
      ),
    );
  }
}
