import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/correspondent_query.dart';
import 'package:paperless_mobile/features/labels/correspondent/bloc/correspondents_cubit.dart';
import 'package:paperless_mobile/features/labels/correspondent/model/correspondent.model.dart';

class CorrespondentWidget extends StatelessWidget {
  final int? correspondentId;
  final void Function()? afterSelected;
  final Color? textColor;
  final bool isClickable;

  const CorrespondentWidget({
    Key? key,
    required this.correspondentId,
    this.afterSelected,
    this.textColor,
    this.isClickable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !isClickable,
      child: BlocBuilder<CorrespondentCubit, Map<int, Correspondent>>(
        builder: (context, state) {
          return GestureDetector(
            onTap: () => _addCorrespondentToFilter(context),
            child: Text(
              (state[correspondentId]?.name) ?? "-",
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

  void _addCorrespondentToFilter(BuildContext context) {
    final cubit = BlocProvider.of<DocumentsCubit>(context);
    if (cubit.state.filter.correspondent.id == correspondentId) {
      cubit.updateCurrentFilter(
        (filter) => filter.copyWith(correspondent: const CorrespondentQuery.unset()),
      );
    } else {
      cubit.updateCurrentFilter(
        (filter) => filter.copyWith(correspondent: CorrespondentQuery.fromId(correspondentId)),
      );
    }
    afterSelected?.call();
  }
}
