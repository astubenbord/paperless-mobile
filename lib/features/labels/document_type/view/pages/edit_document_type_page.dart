import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/document_type_query.dart';
import 'package:paperless_mobile/features/labels/document_type/bloc/document_type_cubit.dart';
import 'package:paperless_mobile/features/labels/document_type/model/document_type.model.dart';
import 'package:paperless_mobile/features/labels/view/pages/edit_label_page.dart';
import 'package:paperless_mobile/util.dart';

class EditDocumentTypePage extends StatelessWidget {
  final DocumentType documentType;
  const EditDocumentTypePage({super.key, required this.documentType});

  @override
  Widget build(BuildContext context) {
    return EditLabelPage<DocumentType>(
      label: documentType,
      onSubmit: BlocProvider.of<DocumentTypeCubit>(context).replace,
      onDelete: (docType) => _onDelete(docType, context),
      fromJson: DocumentType.fromJson,
    );
  }

  Future<void> _onDelete(DocumentType docType, BuildContext context) async {
    try {
      await BlocProvider.of<DocumentTypeCubit>(context).remove(docType);
      final cubit = BlocProvider.of<DocumentsCubit>(context);
      if (cubit.state.filter.documentType.id == docType.id) {
        cubit.updateFilter(
          filter: cubit.state.filter
              .copyWith(documentType: const DocumentTypeQuery.unset()),
        );
      }
    } on ErrorMessage catch (e) {
      showSnackBar(context, translateError(context, e.code));
    } finally {
      Navigator.pop(context);
    }
  }
}
