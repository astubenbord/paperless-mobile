import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/provider/label_repositories_provider.dart';
import 'package:paperless_mobile/features/document_details/bloc/document_details_cubit.dart';
import 'package:paperless_mobile/features/document_details/view/pages/document_details_page.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';
import 'package:provider/provider.dart';

class InboxItem extends StatelessWidget {
  static const _a4AspectRatio = 1 / 1.4142;

  final DocumentModel document;

  const InboxItem({
    super.key,
    required this.document,
  });

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
            isSelectedPredicate: (_) => false,
            onTagSelected: (_) {},
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => DocumentDetailsCubit(
              context.read<PaperlessDocumentsApi>(),
              document,
            ),
            child: const LabelRepositoriesProvider(
              child: DocumentDetailsPage(
                allowEdit: false,
                isLabelClickable: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
