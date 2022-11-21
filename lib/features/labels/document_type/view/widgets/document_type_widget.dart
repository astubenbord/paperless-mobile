import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/document_type_query.dart';
import 'package:paperless_mobile/features/labels/document_type/bloc/document_type_cubit.dart';
import 'package:paperless_mobile/features/labels/document_type/model/document_type.model.dart';
import 'package:paperless_mobile/util.dart';

class DocumentTypeWidget extends StatelessWidget {
  final int? documentTypeId;
  final void Function()? afterSelected;
  final bool isClickable;
  const DocumentTypeWidget({
    Key? key,
    required this.documentTypeId,
    this.afterSelected,
    this.isClickable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !isClickable,
      child: GestureDetector(
        onTap: () => _addDocumentTypeToFilter(context),
        child: BlocBuilder<DocumentTypeCubit, Map<int, DocumentType>>(
          builder: (context, state) {
            return Text(
              state[documentTypeId]?.toString() ?? "-",
              style: Theme.of(context)
                  .textTheme
                  .bodyText2!
                  .copyWith(color: Theme.of(context).colorScheme.tertiary),
            );
          },
        ),
      ),
    );
  }

  void _addDocumentTypeToFilter(BuildContext context) {
    final cubit = BlocProvider.of<DocumentsCubit>(context);
    try {
      if (cubit.state.filter.documentType.id == documentTypeId) {
        cubit.updateCurrentFilter(
          (filter) =>
              filter.copyWith(documentType: const DocumentTypeQuery.unset()),
        );
      } else {
        cubit.updateCurrentFilter(
          (filter) => filter.copyWith(
              documentType: DocumentTypeQuery.fromId(documentTypeId)),
        );
      }
      afterSelected?.call();
    } on ErrorMessage catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
