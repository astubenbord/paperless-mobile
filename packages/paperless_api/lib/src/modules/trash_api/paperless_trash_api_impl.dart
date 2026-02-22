import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_api/src/extensions/dio_exception_extension.dart';

class PaperlessTrashApiImpl implements PaperlessTrashApi {
  final Dio _dio;

  const PaperlessTrashApiImpl(this._dio);

  @override
  Future<PagedSearchResult<DocumentModel>> findTrashed({
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _dio.get(
        '/api/trash/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
        options: Options(validateStatus: (status) => status == 200),
      );
      return compute(
        PagedSearchResult.fromJsonSingleParam,
        PagedSearchResultJsonSerializer<DocumentModel>(
          response.data,
          DocumentModelJsonConverter(),
        ),
      );
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.documentLoadFailed),
      );
    }
  }

  @override
  Future<void> restoreDocument(int id) async {
    try {
      await _dio.post(
        '/api/trash/',
        data: {
          'documents': [id],
          'action': 'restore',
        },
        options: Options(validateStatus: (status) => status == 200),
      );
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.documentUpdateFailed),
      );
    }
  }

  @override
  Future<void> emptyTrash() async {
    try {
      await _dio.post(
        '/api/trash/',
        data: {
          'action': 'empty',
        },
        options: Options(validateStatus: (status) => status == 200),
      );
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.documentDeleteFailed),
      );
    }
  }
}
