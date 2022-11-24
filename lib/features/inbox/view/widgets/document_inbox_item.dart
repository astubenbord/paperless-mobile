import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_details_page.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/labels/bloc/global_state_bloc_provider.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';

class DocumentInboxItem extends StatelessWidget {
  final DocumentModel document;

  const DocumentInboxItem({
    super.key,
    required this.document,
  });
  static const _a4AspectRatio = 1 / 1.4142;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(document.title),
      isThreeLine: true,
      leading: AspectRatio(
        aspectRatio: _a4AspectRatio,
        child: DocumentPreview(
          id: document.id,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat().format(document.added)),
          TagsWidget(
            tagIds: document.tags,
            isMultiLine: false,
            isClickable: false,
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GlobalStateBlocProvider(
            additionalProviders: [
              BlocProvider.value(
                  value: BlocProvider.of<DocumentsCubit>(context)),
            ],
            child: DocumentDetailsPage(
              documentId: document.id,
              allowEdit: false,
              isLabelClickable: false,
            ),
          ),
        ),
      ),
    );
  }
}
