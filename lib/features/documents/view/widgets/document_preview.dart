import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class DocumentPreview extends StatelessWidget {
  final int id;
  final BoxFit fit;
  final Alignment alignment;
  final double borderRadius;
  final bool enableHero;

  const DocumentPreview({
    super.key,
    required this.id,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius = 8.0,
    this.enableHero = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableHero) {
      return _buildPreview(context);
    }
    return Hero(
      tag: "thumb_$id",
      child: _buildPreview(context),
    );
  }

  ClipRRect _buildPreview(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        fit: fit,
        alignment: Alignment.topCenter,
        cacheKey: "thumb_$id",
        imageUrl: context.read<PaperlessDocumentsApi>().getThumbnailUrl(id),
        errorWidget: (ctxt, msg, __) => Text(msg),
        placeholder: (context, value) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: const SizedBox(height: 100, width: 100),
        ),
        cacheManager: context.watch<CacheManager>(),
      ),
    );
  }
}
