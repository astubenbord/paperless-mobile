import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:paperless_mobile/features/labels/bloc/providers/correspondent_bloc_provider.dart';
import 'package:paperless_mobile/features/labels/bloc/label_state.dart';
import 'package:paperless_mobile/util.dart';

class CorrespondentWidget extends StatelessWidget {
  final int? correspondentId;
  final void Function()? afterSelected;
  final Color? textColor;
  final bool isClickable;

  const CorrespondentWidget({
    Key? key,
    this.correspondentId,
    this.afterSelected,
    this.textColor,
    this.isClickable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CorrespondentBlocProvider(
      child: AbsorbPointer(
        absorbing: !isClickable,
        child:
            BlocBuilder<LabelCubit<Correspondent>, LabelState<Correspondent>>(
          builder: (context, state) {
            return GestureDetector(
              onTap: () => _addCorrespondentToFilter(context),
              child: Text(
                (state.getLabel(correspondentId)?.name) ?? "-",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyText2?.copyWith(
                      color: textColor ?? Theme.of(context).colorScheme.primary,
                    ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _addCorrespondentToFilter(BuildContext context) {
    final cubit = BlocProvider.of<DocumentsCubit>(context);
    try {
      if (cubit.state.filter.correspondent.id == correspondentId) {
        cubit.updateCurrentFilter(
          (filter) =>
              filter.copyWith(correspondent: const CorrespondentQuery.unset()),
        );
      } else {
        cubit.updateCurrentFilter(
          (filter) => filter.copyWith(
              correspondent: CorrespondentQuery.fromId(correspondentId)),
        );
      }
      afterSelected?.call();
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
