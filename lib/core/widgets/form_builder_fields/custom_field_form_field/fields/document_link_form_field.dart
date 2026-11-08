import 'package:animations/animations.dart';
import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/document_search/view/document_search_page.dart';

class DocumentLinkFormField extends StatelessWidget {
  final int parentDocumentId;
  final String labelText;
  final Object? value;
  final bool enabled;
  final ValueChanged<Object?> onChanged;
  final String? errorText;

  const DocumentLinkFormField({
    super.key,
    required this.labelText,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.errorText,
    required this.parentDocumentId,
  });

  List<int> get _parsedIds {
    if (value is List) {
      return (value as List).whereType<int>().toList();
    }
    return [];
  }

  void _removeId(int id) {
    final newIds = _parsedIds.where((i) => i != id).toList();
    onChanged(newIds.isEmpty ? null : newIds);
  }

  void _addDocument(Document document) {
    if (!_parsedIds.contains(document.id)) {
      onChanged([..._parsedIds, document.id]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = _parsedIds.map(
      (id) => _DocumentLinkChip(
        documentId: id,
        onDeleted: enabled ? () => _removeId(id) : null,
      ),
    );

    return OpenContainer<Document>(
      middleColor: Theme.of(context).colorScheme.surface,
      closedColor: Theme.of(context).colorScheme.surface,
      openColor: Theme.of(context).colorScheme.surface,
      closedShape: InputBorder.none,
      openElevation: 0,
      closedElevation: 0,
      tappable: enabled,
      closedBuilder: (context, openSearch) {
        return GestureDetector(
          onTap: openSearch,
          child: InputDecorator(
            isEmpty: chips.isEmpty,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(12),
              prefixIcon: const Icon(Icons.link),
              enabled: enabled,
              labelText: labelText,
              errorText: errorText,
            ),
            child: SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, _) => const SizedBox(width: 4),
                itemBuilder: (context, index) => chips.elementAt(index),
                itemCount: chips.length,
              ),
            ),
          ),
        ).paddedOnly(top: 4);
      },
      openBuilder: (context, closeContainer) {
        return DocumentSearchPage(
          close: () => closeContainer(),
          disabledIds: [..._parsedIds, parentDocumentId],
          onItemSelected: (context, document) {
            closeContainer(returnValue: document);
          },
        );
      },
      onClosed: (document) {
        if (document != null) {
          _addDocument(document);
        }
      },
    );
  }
}

/// A chip that loads and displays a linked document's title.
class _DocumentLinkChip extends StatelessWidget {
  final int documentId;
  final VoidCallback? onDeleted;

  const _DocumentLinkChip({required this.documentId, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return QueryBuilder(
      query: context.documentRepository.getDocumentQuery(
        documentId,
        fields: ['id', 'title'],
      ),
      builder: (context, state) {
        final title = state.data?.title ?? '#$documentId';
        return Chip(
          label: Text(title, overflow: TextOverflow.ellipsis),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: onDeleted,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }
}
