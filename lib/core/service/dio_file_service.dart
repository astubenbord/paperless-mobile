import 'dart:io';
// ignore: implementation_imports
import 'package:flutter_cache_manager/src/web/mime_converter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class DioFileService extends FileService {
  final Dio dio;

  DioFileService(this.dio);

  @override
  Future<FileServiceResponse> get(String url,
      {Map<String, String>? headers}) async {
    final response = await dio.get<ResponseBody>(
      url,
      options: Options(
        headers: headers,
        responseType: ResponseType.stream,
      ),
    );
    return DioGetResponse(response);
  }
}

class DioGetResponse implements FileServiceResponse {
  final Response<ResponseBody> _response;

  final DateTime _receivedTime = DateTime.now();

  DioGetResponse(this._response);

  @override
  Stream<List<int>> get content => _response.data!.stream;

  @override
  int? get contentLength => int.tryParse(
      _response.headers.value(HttpHeaders.contentLengthHeader) ?? '-1');

  @override
  String? get eTag => _response.headers.value(HttpHeaders.etagHeader);

  @override
  String get fileExtension {
    var fileExtension = '';
    final contentTypeHeader =
        _response.headers.value(HttpHeaders.contentTypeHeader);
    if (contentTypeHeader != null) {
      final contentType = ContentType.parse(contentTypeHeader);
      fileExtension = contentType.fileExtension;
    }
    return fileExtension;
  }

  @override
  int get statusCode => _response.statusCode ?? 200;

  @override
  DateTime get validTill {
    // Without a cache-control header we keep the file for a week
    var ageDuration = const Duration(days: 7);
    final controlHeader =
        _response.headers.value(HttpHeaders.cacheControlHeader);
    if (controlHeader != null) {
      final controlSettings = controlHeader.split(',');
      for (final setting in controlSettings) {
        final sanitizedSetting = setting.trim().toLowerCase();
        if (sanitizedSetting == 'no-cache') {
          ageDuration = const Duration();
        }
        if (sanitizedSetting.startsWith('max-age=')) {
          var validSeconds = int.tryParse(sanitizedSetting.split('=')[1]) ?? 0;
          if (validSeconds > 0) {
            ageDuration = Duration(seconds: validSeconds);
          }
        }
      }
    }

    return _receivedTime.add(ageDuration);
  }
}
