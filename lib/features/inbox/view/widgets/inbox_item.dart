import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/document_details/bloc/document_details_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/document_details/view/pages/document_details_page.dart';
import 'package:paperless_mobile/features/documents/repository/document_repository.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/labels/bloc/global_state_bloc_provider.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';

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
          builder: (_) => GlobalStateBlocProvider(
            additionalProviders: [
              BlocProvider<DocumentDetailsCubit>(
                create: (context) => DocumentDetailsCubit(
                  getIt<DocumentRepository>(),
                  document,
                ),
              ),
            ],
            child: const DocumentDetailsPage(
              allowEdit: false,
              isLabelClickable: false,
            ),
          ),
        ),
      ),
    );
  }
}