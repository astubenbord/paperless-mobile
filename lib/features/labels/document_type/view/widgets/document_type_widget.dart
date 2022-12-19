import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:paperless_mobile/features/labels/bloc/label_state.dart';
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
    return BlocProvider(
      create: (context) => LabelCubit<DocumentType>(
        RepositoryProvider.of<LabelRepository<DocumentType>>(context),
      ),
      child: AbsorbPointer(
        absorbing: !isClickable,
        child: GestureDetector(
          onTap: () => _addDocumentTypeToFilter(context),
          child:
              BlocBuilder<LabelCubit<DocumentType>, LabelState<DocumentType>>(
            builder: (context, state) {
              return Text(
                state.labels[documentTypeId]?.toString() ?? "-",
                style: Theme.of(context)
                    .textTheme
                    .bodyText2!
                    .copyWith(color: Theme.of(context).colorScheme.tertiary),
              );
            },
          ),
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
              filter.copyWith(documentType: const IdQueryParameter.unset()),
        );
      } else {
        cubit.updateCurrentFilter(
          (filter) => filter.copyWith(
              documentType: IdQueryParameter.fromId(documentTypeId)),
        );
      }
      afterSelected?.call();
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
