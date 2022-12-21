import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/document_status_cubit.dart';
import 'package:paperless_mobile/core/model/document_processing_status.dart';
import 'package:paperless_mobile/features/login/model/authentication_information.dart';
import 'package:paperless_mobile/util.dart';
import 'package:web_socket_channel/io.dart';

abstract class StatusService {
  Future<void> startListeningBeforeDocumentUpload(String httpUrl,
      AuthenticationInformation credentials, String documentFileName);
}

class WebSocketStatusService implements StatusService {
  late WebSocket? socket;
  late IOWebSocketChannel? _channel;

  WebSocketStatusService();

  @override
  Future<void> startListeningBeforeDocumentUpload(
    String httpUrl,
    AuthenticationInformation credentials,
    String documentFileName,
  ) async {
    //   socket = await WebSocket.connect(
    //     httpUrl.replaceFirst("http", "ws") + "/ws/status/",
    //     customClient: getIt<HttpClient>(),
    //     headers: {
    //       'Authorization': 'Token ${credentials.token}',
    //     },
    //   ).catchError((_) {
    //     // Use long polling if connection could not be established
    //   });

    //   if (socket != null) {
    //     socket!.where(isNotNull).listen((event) {
    //       final status = DocumentProcessingStatus.fromJson(event);
    //       getIt<DocumentStatusCubit>().updateStatus(status);
    //       if (status.currentProgress == 100) {
    //         socket!.close();
    //       }
    //     });
    //   }
  }
}

class LongPollingStatusService implements StatusService {
  static const maxRetries = 60;

  final BaseClient httpClient;
  LongPollingStatusService(this.httpClient);

  @override
  Future<void> startListeningBeforeDocumentUpload(
    String httpUrl,
    AuthenticationInformation credentials,
    String documentFileName,
  ) async {
    //   final today = DateTime.now();
    //   bool consumptionFinished = false;
    //   int retryCount = 0;

    //   getIt<DocumentStatusCubit>().updateStatus(
    //     DocumentProcessingStatus(
    //       currentProgress: 0,
    //       filename: documentFileName,
    //       maxProgress: 100,
    //       message: ProcessingMessage.new_file,
    //       status: ProcessingStatus.working,
    //       taskId: DocumentProcessingStatus.unknownTaskId,
    //       documentId: null,
    //       isApproximated: true,
    //     ),
    //   );

    //   do {
    //     final response = await httpClient.get(
    //       Uri.parse(
    //           '$httpUrl/api/documents/?query=$documentFileName added:${formatDate(today)}'),
    //     );
    //     final data = await compute(
    //       PagedSearchResult.fromJson,
    //       PagedSearchResultJsonSerializer(
    //           jsonDecode(response.body), DocumentModel.fromJson),
    //     );
    //     if (data.count > 0) {
    //       consumptionFinished = true;
    //       final docId = data.results[0].id;
    //       getIt<DocumentStatusCubit>().updateStatus(
    //         DocumentProcessingStatus(
    //           currentProgress: 100,
    //           filename: documentFileName,
    //           maxProgress: 100,
    //           message: ProcessingMessage.finished,
    //           status: ProcessingStatus.success,
    //           taskId: DocumentProcessingStatus.unknownTaskId,
    //           documentId: docId,
    //           isApproximated: true,
    //         ),
    //       );
    //       return;
    //     }
    //     sleep(const Duration(seconds: 1));
    //   } while (!consumptionFinished && retryCount < maxRetries);
  }
}
