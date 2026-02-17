import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/translation/sort_field_localization_mapper.dart';
import 'package:paperless_mobile/features/documents/cubit/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/sort_field_selection_bottom_sheet.dart';
import 'package:paperless_mobile/features/labels/cubit/label_cubit.dart';
import 'package:paperless_mobile/core/widgets/connectivity_aware_action_wrapper.dart';

class SortDocumentsButton extends StatelessWidget {
  final bool enabled;
  const SortDocumentsButton({
    super.key,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentsCubit, DocumentsState>(
      builder: (context, state) {
        if (state.filter.sortField == null) {
          return const SizedBox.shrink();
        }
        final icon = Icon(state.filter.sortOrder == SortOrder.ascending
            ? Icons.arrow_upward
            : Icons.arrow_downward);
        final label = Text(translateSortField(context, state.filter.sortField));
        return ConnectivityAwareActionWrapper(
          offlineBuilder: (context, child) {
            return TextButton.icon(
              icon: icon,
              label: label,
              onPressed: null,
            );
          },
          child: TextButton.icon(
            icon: icon,
            label: label,
            onPressed: enabled
                ? () {
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
                      builder: (_) => BlocProvider<DocumentsCubit>.value(
                        value: context.read<DocumentsCubit>(),
                        child: MultiBlocProvider(
                          providers: [
                            BlocProvider(
                              create: (context) => LabelCubit(context.read()),
                            ),
                          ],
                          child: SortFieldSelectionBottomSheet(
                            initialSortField: state.filter.sortField,
                            initialSortOrder: state.filter.sortOrder,
                            onSubmit: (field, order) {
                              return context
                                  .read<DocumentsCubit>()
                                  .updateCurrentFilter(
                                    (filter) => filter.copyWith(
                                      sortField: field,
                                      sortOrder: order,
                                    ),
                                  );
                            },
                          ),
                        ),
                      ),
                    );
                  }
                : null,
          ),
        );
      },
    );
  }
}
