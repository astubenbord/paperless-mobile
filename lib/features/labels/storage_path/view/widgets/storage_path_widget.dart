import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/storage_path_query.dart';
import 'package:paperless_mobile/features/labels/model/label_state.dart';
import 'package:paperless_mobile/features/labels/storage_path/bloc/storage_path_cubit.dart';
import 'package:paperless_mobile/features/labels/storage_path/model/storage_path.model.dart';
import 'package:paperless_mobile/util.dart';

class StoragePathWidget extends StatelessWidget {
  final int? pathId;
  final void Function()? afterSelected;
  final Color? textColor;
  final bool isClickable;

  const StoragePathWidget({
    Key? key,
    this.pathId,
    this.afterSelected,
    this.textColor,
    this.isClickable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !isClickable,
      child: BlocBuilder<StoragePathCubit, LabelState<StoragePath>>(
        builder: (context, state) {
          return GestureDetector(
            onTap: () => _addStoragePathToFilter(context),
            child: Text(
              state.getLabel(pathId)?.name ?? "-",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyText2?.copyWith(
                    color: textColor ?? Theme.of(context).colorScheme.primary,
                  ),
            ),
          );
        },
      ),
    );
  }

  void _addStoragePathToFilter(BuildContext context) {
    final cubit = BlocProvider.of<DocumentsCubit>(context);
    try {
      if (cubit.state.filter.correspondent.id == pathId) {
        cubit.updateCurrentFilter(
          (filter) =>
              filter.copyWith(storagePath: const StoragePathQuery.unset()),
        );
      } else {
        cubit.updateCurrentFilter(
          (filter) =>
              filter.copyWith(storagePath: StoragePathQuery.fromId(pathId)),
        );
      }
      afterSelected?.call();
    } on ErrorMessage catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
