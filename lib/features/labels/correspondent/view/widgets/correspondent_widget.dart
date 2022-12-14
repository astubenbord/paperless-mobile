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
  final void Function(int? id)? onSelected;
  final Color? textColor;
  final bool isClickable;
  final TextStyle? textStyle;

  const CorrespondentWidget({
    Key? key,
    required this.correspondentId,
    this.textColor,
    this.isClickable = true,
    this.textStyle,
    this.onSelected,
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
              onTap: () => onSelected?.call(correspondentId!),
              child: Text(
                (state.getLabel(correspondentId)?.name) ?? "-",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (textStyle ?? Theme.of(context).textTheme.bodyText2)
                    ?.copyWith(
                  color: textColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
