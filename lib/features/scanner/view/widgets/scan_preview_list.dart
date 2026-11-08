import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/features/scanner/models/transient_scan_result.dart';

/// A horizontal scrollable list of scanned document thumbnails.
///
/// Each thumbnail can be tapped (to re-edit) or deleted via a badge button.
class ScanPreviewList extends StatelessWidget {
  /// The total height of the row. This includes the image height + 6px for the overlapping delete badge.
  final double height;
  final List<TransientScanResult> scans;
  final ValueChanged<int> onDelete;
  final ValueChanged<int> onTap;
  final void Function(int oldIndex, int newIndex) onReorder;

  const ScanPreviewList({
    super.key,
    required this.scans,
    required this.onDelete,
    required this.onTap,
    required this.onReorder,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (scans.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: scans.length,
        buildDefaultDragHandles: false,
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final elevate = lerpDouble(0, 6, animation.value)!;
              final scale = lerpDouble(1, 1.08, animation.value)!;
              return Transform.scale(
                scale: scale,
                child: Material(
                  color: Colors.transparent,
                  elevation: elevate,
                  borderRadius: BorderRadius.circular(8),
                  child: child,
                ),
              );
            },
            child: child,
          );
        },
        onReorder: onReorder,
        itemBuilder: (context, index) {
          return Padding(
            key: ValueKey(scans[index]),
            padding: EdgeInsets.only(right: index < scans.length - 1 ? 8 : 0),
            child: _ScanThumbnail(
              scan: scans[index],
              index: index,
              onDelete: () => onDelete(index),
              onTap: () => onTap(index),
              totalHeight: height,
            ),
          );
        },
      ),
    );
  }
}

class _ScanThumbnail extends StatelessWidget {
  final TransientScanResult scan;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final double totalHeight;

  const _ScanThumbnail({
    required this.scan,
    required this.index,
    required this.onDelete,
    required this.onTap,
    required this.totalHeight,
  });

  double get _imageOverlap =>
      6.0; // The amount by which the delete badge overlaps the image
  double get _imageHeight => totalHeight - _imageOverlap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ShortDelayDragStartListener(
      index: index,
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    scan.thumbnailBytes,
                    height: _imageHeight,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    gaplessPlayback: true,
                  ),
                ),
              ),
              _buildDeleteBadge(theme),
            ],
          ),
        ),
      ),
    );
  }

  Positioned _buildDeleteBadge(ThemeData theme) {
    return Positioned(
      top: -_imageOverlap,
      right: -_imageOverlap,
      child: GestureDetector(
        onTap: onDelete,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.inverseSurface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close,
            size: 18,
            color: theme.colorScheme.onInverseSurface,
          ),
        ),
      ),
    );
  }
}

class _ShortDelayDragStartListener extends ReorderableDragStartListener {
  const _ShortDelayDragStartListener({
    required super.child,
    required super.index,
  });

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(
      delay: const Duration(milliseconds: 200),
      debugOwner: this,
    );
  }
}
