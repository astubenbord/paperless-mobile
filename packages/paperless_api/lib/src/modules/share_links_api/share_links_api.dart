import 'package:paperless_api/src/models/share_link_model.dart';

abstract interface class PaperlessShareLinksApi {
  Future<List<ShareLink>> getShareLinks({int? documentId});
  Future<ShareLink> createShareLink(ShareLink shareLink);
  Future<void> deleteShareLink(int id);
}
