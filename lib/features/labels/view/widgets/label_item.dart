import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/labels/bloc/label_bloc_provider.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/repository/document_repository.dart';
import 'package:paperless_mobile/features/labels/model/label.model.dart';
import 'package:paperless_mobile/features/labels/view/widgets/linked_documents_preview.dart';

class LabelItem<T extends Label> extends StatelessWidget {
  final T label;
  final String name;
  final Widget content;
  final void Function(T) onOpenEditPage;
  final DocumentFilter Function(T) filterBuilder;
  final Widget? leading;

  const LabelItem({
    super.key,
    required this.name,
    required this.content,
    required this.onOpenEditPage,
    required this.filterBuilder,
    this.leading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: content,
      leading: leading,
      onTap: () => onOpenEditPage(label),
      trailing: _buildReferencedDocumentsWidget(context),
    );
  }

  Widget _buildReferencedDocumentsWidget(BuildContext context) {
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
                          DocumentsCubit(getIt<DocumentRepository>())
                            ..updateFilter(filter: filter),
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
