import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/loading_status.dart';
import 'package:paperless_mobile/core/bloc/transient_error.dart';
import 'package:paperless_mobile/core/logging/logger.dart';
import 'package:paperless_mobile/core/model/info_message_exception.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:rxdart/rxdart.dart';

part 'document_scanner_cubit.freezed.dart';
part 'document_scanner_state.dart';

class DocumentScannerCubit extends Cubit<DocumentScannerState> {
  final LocalNotificationService _notificationService;

  DocumentScannerCubit(this._notificationService)
      : super(const DocumentScannerState());

  Future<void> initialize() async {
    logger.fd(
      "Restoring scans...",
      className: runtimeType.toString(),
      methodName: "initialize",
    );
    emit(const DocumentScannerState(status: LoadingStatus.loading));
    final tempDir = FileService.instance.temporaryScansDirectory;
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
      emit(const DocumentScannerState());
      return;
    }
    final allFiles = tempDir.list().whereType<File>();
    final scans =
        await allFiles.where((event) => event.path.endsWith(".jpeg")).toList();
    logger.fd(
      "Restored ${scans.length} scans.",
      className: runtimeType.toString(),
      methodName: "initialize",
    );
    emit(
      scans.isEmpty
          ? const DocumentScannerState()
          : DocumentScannerState(scans: scans, status: LoadingStatus.loaded),
    );
  }

  void addScan(File file) async {
    emit(DocumentScannerState(
      status: LoadingStatus.loaded,
      scans: [...state.scans, file],
    ));
  }

  Future<void> removeScan(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error, stackTrace) {
      throw InfoMessageException(
        code: ErrorCode.scanRemoveFailed,
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }
    final scans = state.scans.where((f) => f != file).toList();
    emit(
      scans.isEmpty
          ? const DocumentScannerState()
          : DocumentScannerState(
              status: LoadingStatus.loaded,
              scans: scans,
            ),
    );
  }

  Future<void> reset() async {
    try {
      Future.wait([for (final file in state.scans) file.delete()]);
      imageCache.clear();
    } catch (_) {
      addError(TransientPaperlessApiError(code: ErrorCode.scanRemoveFailed));
    } finally {
      emit(const DocumentScannerState());
    }
  }

  Future<void> saveToFile(
    Uint8List bytes,
    String fileName,
    String locale,
  ) async {
    try {
      var file = await FileService.instance.saveToFile(bytes, fileName);
      _notificationService.notifyFileSaved(
        filename: fileName,
        filePath: file.path,
        finished: true,
        locale: locale,
      );
    } on Exception catch (e) {
      addError(TransientMessageError(message: e.toString()));
    }
  }
}
