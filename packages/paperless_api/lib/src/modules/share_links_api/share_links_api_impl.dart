import 'package:dio/dio.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_api/src/extensions/dio_exception_extension.dart';
import 'package:paperless_api/src/request_utils.dart';

class PaperlessShareLinksApiImpl implements PaperlessShareLinksApi {
  final Dio _dio;

  const PaperlessShareLinksApiImpl(this._dio);

  @override
  Future<List<ShareLink>> getShareLinks({int? documentId}) async {
    var url = '/api/share_links/?page=1&page_size=100000';
    if (documentId != null) {
      url += '&document__id=$documentId';
    }
    return getCollection(
      url,
      ShareLink.fromJson,
      ErrorCode.shareLinkLoadFailed,
      client: _dio,
    );
  }

  @override
  Future<ShareLink> createShareLink(ShareLink shareLink) async {
    try {
      final response = await _dio.post(
        '/api/share_links/',
        data: {
          'document': shareLink.document,
          'file_version': shareLink.fileVersion,
          if (shareLink.expiration != null)
            'expiration': shareLink.expiration!.toUtc().toIso8601String(),
        },
        options: Options(validateStatus: (status) => status == 201),
      );
      return ShareLink.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.shareLinkCreateFailed),
      );
    }
  }

  @override
  Future<void> deleteShareLink(int id) async {
    try {
      await _dio.delete(
        '/api/share_links/$id/',
        options: Options(validateStatus: (status) => status == 204),
      );
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.shareLinkDeleteFailed),
      );
    }
  }
}
