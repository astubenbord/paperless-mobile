import 'dart:io';

import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/store/bloc/global_settings_builder.dart';
import 'package:paperless_mobile/features/document_scan/model/document_scan.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/connectivity_aware_action_wrapper.dart';

typedef DocumentActionCallback = void Function();
typedef DocumentPageTapCallback = void Function(int pageIndex);

class ScannedImageItem extends StatelessWidget {
  static const double _itemHeight = 320;
  static const double _carouselHeight = 176;

  final DocumentScan documentScan;
  final String defaultTitle;
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
    required this.defaultTitle,
    this.onPreview,
    this.onUpload,
    this.onExport,
    this.onPageTap,
  });

  @override
  Widget build(BuildContext context) {
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
                      documentScan.name ?? defaultTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete),
                        tooltip: S.of(context)!.delete,
                      ),
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        tooltip: S.of(context)!.edit,
                      ),
                    ],
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
    return GlobalSettingsBuilder(
      builder: (context, settings) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              label: Text(S.of(context)!.previewScan),
              icon: Icon(Icons.visibility_outlined),
              onPressed: onPreview,
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              label: Text(S.of(context)!.export),
              icon: const Icon(Icons.save_alt_outlined),
              onPressed: onExport,
            ),
            const SizedBox(width: 8),
            ConnectivityAwareActionWrapper(
              offlineBuilder: (context, child) {
                return FilledButton.tonalIcon(
                  label: Text(S.of(context)!.upload),
                  icon: const Icon(Icons.upload_outlined),
                  onPressed: null,
                );
              },
              disabled: onUpload == null,
              child: FilledButton.tonalIcon(
                label: Text(S.of(context)!.upload),
                icon: const Icon(Icons.upload_outlined),
                onPressed: onUpload,
              ),
            ),
          ],
        );
      },
    );
  }
}
