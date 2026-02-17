import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/accessibility/accessibility_utils.dart';
import 'package:paperless_mobile/core/widgets/connectivity_aware_action_wrapper.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class DocumentPreview extends StatelessWidget {
  final int documentId;
  final String? title;
  final BoxFit fit;
  final Alignment alignment;
  final double borderRadius;
  final bool enableHero;
  final double scale;
  final bool isClickable;

  const DocumentPreview({
    super.key,
    required this.documentId,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
    this.borderRadius = 12.0,
    this.enableHero = true,
    this.scale = 1.1,
    this.isClickable = true,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ConnectivityAwareActionWrapper(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: isClickable
            ? () => DocumentPreviewRoute(
                  id: documentId,
                  title: title,
                ).push(context)
            : null,
        child: Builder(builder: (context) {
          if (enableHero) {
            return Hero(
              tag: "thumb_$documentId",
              child: _buildPreview(context),
            ).accessible();
          }
          return _buildPreview(context);
        }),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Transform.scale(
        scale: scale,
        child: CachedNetworkImage(
          fit: fit,
          alignment: alignment,
          cacheKey: "thumb_$documentId",
          imageUrl:
              context.read<PaperlessDocumentsApi>().getThumbnailUrl(documentId),
          errorWidget: (ctxt, msg, __) => Text(msg),
          placeholder: (context, value) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: const SizedBox(height: 100, width: 100),
          ),
          cacheManager: context.watch<CacheManager>(),
        ),
      ),
    );
  }
}
