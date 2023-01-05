import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:paperless_mobile/features/labels/bloc/label_state.dart';
import 'package:paperless_mobile/features/labels/bloc/providers/document_type_bloc_provider.dart';

class DocumentTypeWidget extends StatelessWidget {
  final int? documentTypeId;
  final bool isClickable;
  final TextStyle? textStyle;
  final void Function(int? id)? onSelected;
  const DocumentTypeWidget({
    Key? key,
    required this.documentTypeId,
    this.isClickable = true,
    this.textStyle,
    this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DocumentTypeBlocProvider(
      child: AbsorbPointer(
        absorbing: !isClickable,
        child: GestureDetector(
          onTap: () => onSelected?.call(documentTypeId),
          child:
              BlocBuilder<LabelCubit<DocumentType>, LabelState<DocumentType>>(
            builder: (context, state) {
              return Text(
                state.labels[documentTypeId]?.toString() ?? "-",
                style: (textStyle ?? Theme.of(context).textTheme.bodyMedium)
                    ?.copyWith(color: Theme.of(context).colorScheme.tertiary),
              );
            },
          ),
        ),
      ),
    );
  }
}
