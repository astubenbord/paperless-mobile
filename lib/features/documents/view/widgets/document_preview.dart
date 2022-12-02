import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:shimmer/shimmer.dart';

class DocumentPreview extends StatelessWidget {
  final int id;
  final BoxFit fit;
  final Alignment alignment;
  final double borderRadius;

  const DocumentPreview({
    Key? key,
    required this.id,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return
        // Hero(
        // tag: "document_$id",child:
        ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        fit: fit,
        alignment: Alignment.topCenter,
        cacheKey: "thumb_$id",
        imageUrl: getIt<PaperlessDocumentsApi>().getThumbnailUrl(id),
        errorWidget: (ctxt, msg, __) => Text(msg),
        placeholder: (context, value) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: const SizedBox(height: 100, width: 100),
        ),
        cacheManager: getIt<CacheManager>(),
      ),
      // ),
    );
  }
}
