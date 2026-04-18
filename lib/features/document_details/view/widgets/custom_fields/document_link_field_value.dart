import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/api/extensions/cached_query_extensions.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/widgets/icon_loading_widget.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';

class DocumentLinkFieldValue extends StatelessWidget {
  final Object? value;
  final TextStyle? style;
  final Widget placeholder;

  const DocumentLinkFieldValue({
    super.key,
    required this.value,
    this.style,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null) return placeholder;
    // Document links are stored as a list of document IDs.
    final ids = _parseDocumentIds(value);
    if (ids.isEmpty) return placeholder;
    return QueryBuilder(
      query: context.documentRepository.getAllQuery(
        filter: DocumentFilter(
          documentIds: ids,
          pageSize: ids.length,
          fields: ['id', 'title'],
        ),
      ),
      builder: (context, state) {
        final documents =
            state.data?.pages.expand((e) => e.results).toList() ?? [];
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: ids.map((id) {
            final doc = documents.where((d) => d.id == id).firstOrNull;
            return ActionChip(
              avatar: state.isLoadingInitial
                  ? IconLoadingWidget()
                  : Icon(Icons.description_outlined),
              onPressed: () {
                DocumentDetailsRoute(documentId: id).go(context);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              label: Text(doc?.title ?? 'Doc #$id'),
            );
          }).toList(),
        );
      },
    );
  }

  List<int> _parseDocumentIds(Object? value) {
    if (value is List) {
      return value.whereType<int>().toList();
    }
    return [];
  }
}
