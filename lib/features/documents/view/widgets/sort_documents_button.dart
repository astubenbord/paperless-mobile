import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/sort_field_selection_bottom_sheet.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';

class SortDocumentsButton extends StatelessWidget {
  const SortDocumentsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.sort),
      onPressed: () => _onOpenSortBottomSheet(context),
    );
  }

  void _onOpenSortBottomSheet(BuildContext context) {
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
      builder: (_) => BlocProvider.value(
        value: BlocProvider.of<DocumentsCubit>(context),
        child: FractionallySizedBox(
          heightFactor: .6,
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => LabelCubit<DocumentType>(
                  RepositoryProvider.of<LabelRepository<DocumentType>>(context),
                ),
              ),
              BlocProvider(
                create: (context) => LabelCubit<Correspondent>(
                  RepositoryProvider.of<LabelRepository<Correspondent>>(
                      context),
                ),
              ),
            ],
            child: BlocBuilder<DocumentsCubit, DocumentsState>(
              builder: (context, state) {
                return SortFieldSelectionBottomSheet(
                  initialSortField: state.filter.sortField,
                  initialSortOrder: state.filter.sortOrder,
                  onSubmit: (field, order) =>
                      BlocProvider.of<DocumentsCubit>(context)
                          .updateCurrentFilter(
                    (filter) => filter.copyWith(
                      sortField: field,
                      sortOrder: order,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
