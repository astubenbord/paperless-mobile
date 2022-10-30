import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_paperless_mobile/di_initializer.dart';
import 'package:flutter_paperless_mobile/features/documents/model/query_parameters/document_type_query.dart';
import 'package:flutter_paperless_mobile/features/labels/document_type/bloc/document_type_cubit.dart';
import 'package:flutter_paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:flutter_paperless_mobile/features/labels/document_type/model/document_type.model.dart';

class DocumentTypeWidget extends StatelessWidget {
  final int? documentTypeId;
  final void Function()? afterSelected;
  const DocumentTypeWidget({
    Key? key,
    required this.documentTypeId,
    this.afterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _addDocumentTypeToFilter,
      child: BlocBuilder<DocumentTypeCubit, Map<int, DocumentType>>(
        builder: (context, state) {
          return Text(
            state[documentTypeId]?.toString() ?? "-",
            style: Theme.of(context)
                .textTheme
                .bodyText2!
                .copyWith(color: Theme.of(context).colorScheme.primary),
          );
        },
      ),
    );
  }

  void _addDocumentTypeToFilter() {
    final cubit = getIt<DocumentsCubit>();
    if (cubit.state.filter.documentType.id == documentTypeId) {
      cubit.updateFilter(
          filter: cubit.state.filter.copyWith(documentType: const DocumentTypeQuery.unset()));
    } else {
      cubit.updateFilter(
        filter: cubit.state.filter.copyWith(
          documentType: DocumentTypeQuery.fromId(documentTypeId),
        ),
      );
    }
    if (afterSelected != null) {
      afterSelected?.call();
    }
  }
}
