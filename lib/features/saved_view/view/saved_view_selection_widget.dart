import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/confirm_delete_saved_view_dialog.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_state.dart';
import 'package:paperless_mobile/features/saved_view/view/add_saved_view_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

class SavedViewSelectionWidget extends StatelessWidget {
  final DocumentFilter currentFilter;
  const SavedViewSelectionWidget({
    Key? key,
    required this.height,
    required this.enabled,
    required this.currentFilter,
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
            BlocBuilder<DocumentsCubit, DocumentsState>(
              buildWhen: (previous, current) =>
                  previous.filter != current.filter,
              builder: (context, docState) {
                return TextButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: enabled
                      ? () => _onCreatePressed(context, docState.filter)
                      : null,
                  label: Text(S.of(context).savedViewCreateNewLabel),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void _onCreatePressed(BuildContext context, DocumentFilter filter) async {
    final newView = await Navigator.of(context).push<SavedView?>(
      MaterialPageRoute(
        builder: (context) => AddSavedViewPage(
          currentFilter: filter,
        ),
      ),
    );
    if (newView != null) {
      try {
        await BlocProvider.of<SavedViewCubit>(context).add(newView);
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      }
    }
  }

  void _onSelected(
      bool isSelected, BuildContext context, SavedView view) async {
    if (isSelected) {
      BlocProvider.of<SavedViewCubit>(context).selectView(view);
    } else {
      BlocProvider.of<SavedViewCubit>(context).selectView(null);
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
        } on PaperlessServerException catch (error, stackTrace) {
          showErrorMessage(context, error, stackTrace);
        }
      }
    }
  }
}
