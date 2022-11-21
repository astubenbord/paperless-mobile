import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/saved_view_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/saved_view_state.dart';
import 'package:paperless_mobile/features/documents/model/saved_view.model.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/add_saved_view_page.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/confirm_delete_saved_view_dialog.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

class SavedViewSelectionWidget extends StatelessWidget {
  const SavedViewSelectionWidget({
    Key? key,
    required this.height,
    required this.enabled,
  }) : super(key: key);

  final double height;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<SavedViewCubit, SavedViewState>(
          builder: (context, state) {
            if (state.value.isEmpty) {
              return Text(S.of(context).savedViewsEmptyStateText);
            }
            return SizedBox(
              height: height,
              child: ListView.separated(
                itemCount: state.value.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final view = state.value.values.elementAt(index);
                  return GestureDetector(
                    onLongPress: () => _onDelete(context, view),
                    child: FilterChip(
                      label: Text(state.value.values.toList()[index].name),
                      selected: view.id == state.selectedSavedViewId,
                      onSelected: enabled
                          ? (isSelected) =>
                              _onSelected(isSelected, context, view)
                          : null,
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(
                  width: 8.0,
                ),
              ),
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              S.of(context).savedViewsLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              onPressed: enabled ? () => _onCreatePressed(context) : null,
              label: Text(S.of(context).savedViewCreateNewLabel),
            ),
          ],
        ),
      ],
    );
  }

  void _onCreatePressed(BuildContext context) async {
    final newView = await Navigator.of(context).push<SavedView?>(
      MaterialPageRoute(
        builder: (context) => AddSavedViewPage(
          currentFilter: getIt<DocumentsCubit>().state.filter,
        ),
      ),
    );
    if (newView != null) {
      try {
        await BlocProvider.of<SavedViewCubit>(context).add(newView);
      } on ErrorMessage catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      }
    }
  }

  void _onSelected(
      bool isSelected, BuildContext context, SavedView view) async {
    try {
      if (isSelected) {
        BlocProvider.of<DocumentsCubit>(context)
            .updateFilter(filter: view.toDocumentFilter());
        BlocProvider.of<SavedViewCubit>(context).selectView(view);
      } else {
        BlocProvider.of<DocumentsCubit>(context).updateFilter();
        BlocProvider.of<SavedViewCubit>(context).selectView(null);
      }
    } on ErrorMessage catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  void _onDelete(BuildContext context, SavedView view) async {
    {
      final delete = await showDialog<bool>(
            context: context,
            builder: (context) => ConfirmDeleteSavedViewDialog(view: view),
          ) ??
          false;
      if (delete) {
        try {
          BlocProvider.of<SavedViewCubit>(context).remove(view);
        } on ErrorMessage catch (error, stackTrace) {
          showErrorMessage(context, error, stackTrace);
        }
      }
    }
  }
}
