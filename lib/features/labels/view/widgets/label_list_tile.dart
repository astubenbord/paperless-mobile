import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/bloc/label_bloc_provider.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/repository/document_repository.dart';
import 'package:paperless_mobile/features/labels/model/label.model.dart';
import 'package:paperless_mobile/features/labels/tags/model/tag.model.dart';
import 'package:paperless_mobile/features/labels/view/widgets/linked_documents_preview.dart';

class LabelListTile<T extends Label> extends StatelessWidget {
  final T label;
  final DocumentFilter Function(Label) filterBuilder;
  final void Function() onOpenEditPage;

  const LabelListTile(
    this.label, {
    super.key,
    required this.filterBuilder,
    required this.onOpenEditPage,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: (label is Tag)
          ? CircleAvatar(
              backgroundColor: (label as Tag).color,
            )
          : null,
      title: Text(label.name),
      onTap: onOpenEditPage,
      trailing: _buildDocumentCountWidget(context),
      subtitle: Text(
        (label.match?.isEmpty ?? true) ? "-" : label.match!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDocumentCountWidget(BuildContext context) {
    return TextButton.icon(
      label: const Icon(Icons.link),
      icon: Text(_formatDocumentCount(label.documentCount)),
      onPressed: (label.documentCount ?? 0) == 0
          ? null
          : () {
              final filter = filterBuilder(label);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LabelBlocProvider(
                    child: BlocProvider(
                      create: (context) =>
                          DocumentsCubit(getIt<DocumentRepository>())..updateFilter(filter: filter),
                      child: LinkedDocumentsPreview(filter: filter),
                    ),
                  ),
                ),
              );
            },
    );
  }

  String _formatDocumentCount(int? count) {
    if ((count ?? 0) > 99) {
      return "99+";
    }
    return (count ?? 0).toString().padLeft(3);
  }
}
