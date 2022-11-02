import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/labels/document_type/bloc/document_type_cubit.dart';
import 'package:paperless_mobile/features/labels/document_type/model/document_type.model.dart';
import 'package:paperless_mobile/features/labels/view/pages/add_label_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class AddDocumentTypePage extends StatelessWidget {
  final String? initialName;
  const AddDocumentTypePage({Key? key, this.initialName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AddLabelPage<DocumentType>(
      addLabelStr: S.of(context).addDocumentTypePageTitle,
      fromJson: DocumentType.fromJson,
      cubit: BlocProvider.of<DocumentTypeCubit>(context),
      initialName: initialName,
    );
  }
}
