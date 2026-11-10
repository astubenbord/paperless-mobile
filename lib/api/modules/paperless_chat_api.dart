import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:paperless_mobile/api/extensions/dio_exception_extension.dart';
import 'package:paperless_mobile/api/models/document_chat_reference.dart';
import 'package:paperless_mobile/api/models/document_chat_response.dart';
import 'package:paperless_mobile/api/models/exception/paperless_api_exception.dart';

///
/// API for the LLM based document chat of paperless-ngx, which is only
/// available if AI features are enabled on the server.
///
abstract class PaperlessChatApi {
  /// Emits the answer received so far each time a new chunk arrives.
  /// Asks about all documents if [documentId] is null.
  Stream<DocumentChatResponse> chat(String question, {int? documentId});
}

class PaperlessChatApiImpl implements PaperlessChatApi {
  /// Separates the answer from the trailing JSON containing the references.
  static const _metadataDelimiter = '\n\n__PAPERLESS_CHAT_METADATA__';

  final Dio client;

  PaperlessChatApiImpl(this.client);

  @override
  Stream<DocumentChatResponse> chat(String question, {int? documentId}) async* {
    final Response<ResponseBody> response;
    try {
      response = await client.post<ResponseBody>(
        '/api/documents/chat/',
        data: {
          'q': question,
          if (documentId != null) 'document_id': documentId,
        },
        options: Options(
          responseType: ResponseType.stream,
          // Waiting for the LLM to respond can take a while.
          receiveTimeout: const Duration(minutes: 3),
          validateStatus: (status) => status == 200,
        ),
      );
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: PaperlessApiException(ErrorCode.documentChatFailed),
      );
    }
    var answer = '';
    yield* response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .map((chunk) => _parseResponse(answer += chunk))
        .handleError(
          (exception) => throw (exception as DioException).unravel(
            orElse: PaperlessApiException(ErrorCode.documentChatFailed),
          ),
          test: (exception) => exception is DioException,
        );
  }

  DocumentChatResponse _parseResponse(String answer) {
    final delimiterIndex = answer.indexOf(_metadataDelimiter);
    if (delimiterIndex == -1) {
      return DocumentChatResponse(content: answer);
    }
    final content = answer.substring(0, delimiterIndex);
    try {
      final metadata = jsonDecode(
        answer.substring(delimiterIndex + _metadataDelimiter.length),
      );
      return DocumentChatResponse(
        content: content,
        references: (metadata['references'] as List? ?? [])
            .map((json) => DocumentChatReference.fromJson(json))
            .toList(),
      );
    } catch (_) {
      // The metadata has not been fully received yet.
      return DocumentChatResponse(content: content);
    }
  }
}
