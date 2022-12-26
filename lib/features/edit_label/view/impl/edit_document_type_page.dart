import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/edit_label/cubit/edit_label_cubit.dart';
import 'package:paperless_mobile/features/edit_label/view/edit_label_page.dart';

class EditDocumentTypePage extends StatelessWidget {
  final DocumentType documentType;
  const EditDocumentTypePage({super.key, required this.documentType});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditLabelCubit<DocumentType>(
        context.read<LabelRepository<DocumentType>>(),
      ),
      child: EditLabelPage<DocumentType>(
        label: documentType,
        fromJsonT: DocumentType.fromJson,
      ),
    );
  }
}
