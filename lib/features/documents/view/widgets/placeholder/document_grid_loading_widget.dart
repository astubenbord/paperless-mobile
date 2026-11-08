import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/view/widgets/placeholder/tags_placeholder.dart';
import 'package:paperless_mobile/features/documents/view/widgets/placeholder/text_placeholder.dart';

class DocumentGridLoadingWidget extends StatelessWidget {
  final bool _isSliver;
  @override
  const DocumentGridLoadingWidget({super.key}) : _isSliver = false;

  const DocumentGridLoadingWidget.sliver({super.key}) : _isSliver = true;

  @override
  Widget build(BuildContext context) {
    const delegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1 / 2,
    );
    if (_isSliver) {
      return SliverGrid.builder(
        gridDelegate: delegate,
        itemBuilder: (context, index) => _buildPlaceholderGridItem(context),
      );
    }
    return GridView.builder(
      gridDelegate: delegate,
      itemBuilder: (context, index) => _buildPlaceholderGridItem(context),
    );
  }

  Widget _buildPlaceholderGridItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerPlaceholder(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ShimmerPlaceholder(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TextPlaceholder(length: 70, fontSize: 16).padded(1),
                      const TextPlaceholder(length: 50, fontSize: 16).padded(1),
                      TextPlaceholder(
                        length: 200,
                        fontSize:
                            Theme.of(context).textTheme.titleMedium?.fontSize ??
                            10,
                      ).padded(1),
                      const Spacer(),
                      const TagsPlaceholder(count: 2, dense: true),
                      const Spacer(),
                      TextPlaceholder(
                        length: 100,
                        fontSize: Theme.of(
                          context,
                        ).textTheme.bodySmall!.fontSize!,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
