import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/highlighted_text.dart';

class DocumentContentWidget extends StatelessWidget {
  final DocumentModel document;
  final String? queryString;
  const DocumentContentWidget({
    super.key,
    required this.document,
    this.queryString,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HighlightedText(
            text: document.content ?? '',
            highlights: queryString != null ? queryString!.split(" ") : [],
            style: Theme.of(context).textTheme.bodyMedium,
            caseSensitive: false,
          ),
        ],
      ),
    );
  }
}
