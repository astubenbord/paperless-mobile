import 'dart:io';

import 'package:flutter/material.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/connectivity_aware_action_wrapper.dart';
import 'package:paperless_mobile/features/document_scan/model/document_scan.dart';

typedef DocumentActionCallback = void Function();
typedef DocumentPageTapCallback = void Function(int pageIndex);

class ScannedImageItem extends StatelessWidget {
  static const double _itemHeight = 302;
  static const double _carouselHeight = 176;

  final DocumentScan documentScan;
  final DocumentActionCallback onDelete;
  final DocumentActionCallback onEdit;
  final DocumentActionCallback? onPreview;
  final DocumentActionCallback? onUpload;
  final DocumentActionCallback? onExport;
  final DocumentPageTapCallback? onPageTap;

  const ScannedImageItem({
    super.key,
    required this.documentScan,
    required this.onDelete,
    required this.onEdit,
    this.onPreview,
    this.onUpload,
    this.onExport,
    this.onPageTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: _itemHeight,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      documentScan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${documentScan.pageCount} page${documentScan.pageCount == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(height: _carouselHeight, child: _buildCarousel(context)),
              const SizedBox(height: 12),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel(BuildContext context) {
    final pageFiles = documentScan.pageFiles;
    if (pageFiles.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Icon(Icons.description_outlined, size: 36)),
      );
    }

    return CarouselView(
      itemExtent: 220,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: onPageTap,
      children: [
        for (var index = 0; index < pageFiles.length; index++)
          _buildCarouselPage(context, pageFiles[index], index),
      ],
    );
  }

  Widget _buildCarouselPage(BuildContext context, File pageFile, int index) {
    final borderRadius = BorderRadius.circular(18);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            pageFile,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image_outlined, size: 36),
              );
            },
          ),
          Positioned(
            top: 12,
            right: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  '${index + 1}/${documentScan.pageCount}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionChip(
            label: Text(S.of(context)!.edit),
            avatar: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          const SizedBox(width: 8),
          ActionChip(
            label: Text(S.of(context)!.delete),
            avatar: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
          const SizedBox(width: 8),
          ActionChip(
            label: Text(S.of(context)!.previewScan),
            avatar: const Icon(Icons.visibility_outlined),
            onPressed: onPreview,
          ),
          const SizedBox(width: 8),
          ConnectivityAwareActionWrapper(
            offlineBuilder: (context, child) {
              return ActionChip(
                label: Text(S.of(context)!.upload),
                avatar: const Icon(Icons.upload_outlined),
                onPressed: null,
              );
            },
            disabled: onUpload == null,
            child: ActionChip(
              label: Text(S.of(context)!.upload),
              avatar: const Icon(Icons.upload_outlined),
              onPressed: onUpload,
            ),
          ),
          const SizedBox(width: 8),
          ActionChip(
            label: Text(S.of(context)!.export),
            avatar: const Icon(Icons.save_alt_outlined),
            onPressed: onExport,
          ),
        ],
      ),
    );
  }
}
