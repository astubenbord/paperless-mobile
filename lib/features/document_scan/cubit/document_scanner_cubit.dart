import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/loading_status.dart';
import 'package:paperless_mobile/core/bloc/transient_error.dart';
import 'package:paperless_mobile/core/store/local_store.dart';
import 'package:paperless_mobile/core/store/slices/local_user_data.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/core/model/info_message_exception.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/features/document_scan/model/document_scan.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:paperless_mobile/features/scanner/models/document_frame.dart';
import 'package:paperless_mobile/features/scanner/models/scan_result.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

part 'document_scanner_cubit.freezed.dart';
part 'document_scanner_state.dart';

const allowedExtensions = ['.jpeg', '.jpg', '.png'];
final _documentScanNameDateFormat = DateFormat('yyyy_MM_ddTHH_mm_ss');

class DocumentScannerCubit extends Cubit<DocumentScannerState> {
  final LocalNotificationService _notificationService;
  final LocalStore _localStore;
  final Uuid _uuid;

  DocumentScannerCubit(
    this._notificationService,
    this._localStore, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid(),
       super(const DocumentScannerState());

  Future<void> initialize() async {
    logger.fd(
      "Restoring document scans...",
      className: runtimeType.toString(),
      methodName: "initialize",
    );
    emit(const DocumentScannerState(status: LoadingStatus.loading));

    await _migrateLegacyScansIfNeeded();

    final validScans = await _validateDocumentScans(_storedDocumentScans);
    logger.fd(
      "Restored ${validScans.length} document scans.",
      className: runtimeType.toString(),
      methodName: "initialize",
    );

    _storeDocumentScans(validScans);
    _emitLoaded(validScans);
  }

  Future<DocumentScan> createDocumentScan({bool persist = true}) async {
    final documentId = _uuid.v4();
    final directory = await FileService.instance.createDocumentScanDirectory(
      documentId: documentId,
    );
    final createdAt = DateTime.now();
    final documentScan = DocumentScan(
      id: documentId,
      name: _documentScanName(createdAt),
      directoryPath: directory.path,
      createdAt: createdAt,
    );

    if (persist) {
      final updatedScans = [...state.documentScans, documentScan];
      _storeDocumentScans(updatedScans);
      _emitLoaded(updatedScans);
    }

    return documentScan;
  }

  Future<void> persistDocumentScan(DocumentScan documentScan) async {
    final updatedScans = [...state.documentScans, documentScan];
    final validScans = await _validateDocumentScans(updatedScans);
    _storeDocumentScans(validScans);
    _emitLoaded(validScans);
  }

  Future<void> refreshDocumentScanFromScanner(
    String documentScanId,
    List<ScanResult> pages,
  ) async {
    final updatedScans = [
      for (final documentScan in state.documentScans)
        if (documentScan.id == documentScanId)
          documentScan.copyWith(pages: pages)
        else
          documentScan,
    ];

    final validScans = await _validateDocumentScans(updatedScans);
    _storeDocumentScans(validScans);
    _emitLoaded(validScans);
  }

  Future<void> removeDocumentScan(DocumentScan documentScan) async {
    try {
      await FileService.instance.removeDocumentScanDirectory(
        documentId: documentScan.id,
      );
      final updatedScans = state.documentScans
          .where((scan) => scan.id != documentScan.id)
          .toList();
      _storeDocumentScans(updatedScans);
      _emitLoaded(updatedScans);
    } catch (error, stackTrace) {
      throw InfoMessageException(
        code: ErrorCode.scanRemoveFailed,
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> reset() async {
    try {
      await Future.wait([
        for (final documentScan in state.documentScans)
          FileService.instance.removeDocumentScanDirectory(
            documentId: documentScan.id,
          ),
      ]);
      _storeDocumentScans(const []);
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

  Future<void> discardEmptyDocumentScan(String documentScanId) async {
    DocumentScan? documentScan;
    for (final scan in state.documentScans) {
      if (scan.id == documentScanId) {
        documentScan = scan;
        break;
      }
    }
    if (documentScan == null) {
      return;
    }

    if (documentScan.pageCount == 0) {
      await removeDocumentScan(documentScan);
    }
  }

  Future<void> discardDocumentScanDraft(String documentScanId) async {
    await FileService.instance.removeDocumentScanDirectory(
      documentId: documentScanId,
    );
  }

  Future<List<DocumentScan>> _validateDocumentScans(
    List<DocumentScan> documentScans,
  ) async {
    final validScans = <DocumentScan>[];
    for (final documentScan in documentScans) {
      final directory = documentScan.directory;
      if (!await directory.exists()) {
        logger.fw(
          'Document scan directory ${directory.path} was missing and has been removed from state.',
          className: runtimeType.toString(),
          methodName: 'initialize',
        );
        continue;
      }

      await _ensureDocumentScanSubdirectories(documentScan);

      final validPages = <ScanResult>[];
      for (final page in documentScan.pages) {
        final originalFile = page.originalFile(documentScan.originalDirectory);
        final editedFile = page.editedFile(documentScan.editedDirectory);
        if (!await originalFile.exists() || !await editedFile.exists()) {
          continue;
        }
        final length = await editedFile.length();
        if (length == 0) {
          await editedFile.delete();
          logger.fw(
            'Document scan page ${editedFile.path} was empty and has been deleted.',
            className: runtimeType.toString(),
            methodName: 'initialize',
          );
          continue;
        }
        validPages.add(page);
      }

      validScans.add(documentScan.copyWith(pages: validPages));
    }
    return validScans;
  }

  Future<void> _migrateLegacyScansIfNeeded() async {
    if (_storedDocumentScans.isNotEmpty) {
      return;
    }

    final tempDir = FileService.instance.temporaryScansDirectory;
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
      return;
    }

    final legacyFiles =
        (await tempDir.list().whereType<File>().toList())
            .where(
              (file) => allowedExtensions.contains(
                p.extension(file.path).toLowerCase(),
              ),
            )
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));

    if (legacyFiles.isEmpty) {
      return;
    }

    final documentId = _uuid.v4();
    final targetDirectory = await FileService.instance
        .createDocumentScanDirectory(documentId: documentId);
    final originalDirectory = FileService.instance
        .getDocumentScanOriginalDirectory(documentId);
    final editedDirectory = FileService.instance.getDocumentScanEditedDirectory(
      documentId,
    );
    final migratedPages = <ScanResult>[];

    for (final file in legacyFiles) {
      final fileName = p.basename(file.path);
      final editedPath = p.join(editedDirectory.path, fileName);
      final migratedEditedFile = await file.rename(editedPath);
      final migratedOriginalFile = await migratedEditedFile.copy(
        p.join(originalDirectory.path, fileName),
      );
      final decoded = await decodeImageFromList(
        await migratedOriginalFile.readAsBytes(),
      );
      try {
        final imageWidth = decoded.width.toDouble();
        final imageHeight = decoded.height.toDouble();
        migratedPages.add(
          ScanResult(
            originalFileName: fileName,
            editedFileName: fileName,
            originalImageSize: Size(imageWidth, imageHeight),
            cropFrame: DocumentFrame(
              topLeft: Offset.zero,
              topRight: Offset(imageWidth, 0),
              bottomRight: Offset(imageWidth, imageHeight),
              bottomLeft: Offset(0, imageHeight),
            ),
            quarterTurns: 0,
            colorFilter: ScanColorFilter.none,
            bwThreshold: 10,
            enhanced: false,
          ),
        );
      } finally {
        decoded.dispose();
      }
    }

    final migratedDocument = DocumentScan(
      id: documentId,
      name: _documentScanName(DateTime.now()),
      directoryPath: targetDirectory.path,
      createdAt: DateTime.now(),
      pages: migratedPages,
    );

    _storeDocumentScans([migratedDocument]);
  }

  List<DocumentScan> get _storedDocumentScans {
    final loggedInAppUserId = _localStore.state.loggedInAppUserId;
    if (loggedInAppUserId == null) {
      return const [];
    }

    return _localStore.state.localUserData[loggedInAppUserId]?.documentScans ??
        const [];
  }

  void _storeDocumentScans(List<DocumentScan> documentScans) {
    final loggedInAppUserId = _localStore.state.loggedInAppUserId;
    if (loggedInAppUserId == null) {
      return;
    }

    _localStore.updateUserData(
      loggedInAppUserId,
      (userData) => userData.copyWith(documentScans: documentScans),
    );
  }

  void _emitLoaded(List<DocumentScan> documentScans) {
    emit(
      documentScans.isEmpty
          ? const DocumentScannerState()
          : DocumentScannerState(
              status: LoadingStatus.loaded,
              documentScans: documentScans,
            ),
    );
  }

  Future<void> _ensureDocumentScanSubdirectories(
    DocumentScan documentScan,
  ) async {
    await Future.wait([
      documentScan.originalDirectory.create(recursive: true),
      documentScan.editedDirectory.create(recursive: true),
    ]);

    for (final page in documentScan.pages) {
      final originalFile = page.originalFile(documentScan.originalDirectory);
      final editedFile = page.editedFile(documentScan.editedDirectory);
      if (await originalFile.exists() && await editedFile.exists()) {
        continue;
      }

      final legacyRootFile = File(
        p.join(documentScan.directory.path, page.editedFileName),
      );
      if (await legacyRootFile.exists()) {
        final movedEditedFile = await legacyRootFile.rename(editedFile.path);
        if (!await originalFile.exists()) {
          await movedEditedFile.copy(originalFile.path);
        }
        continue;
      }

      if (await editedFile.exists() && !await originalFile.exists()) {
        await editedFile.copy(originalFile.path);
      } else if (await originalFile.exists() && !await editedFile.exists()) {
        await originalFile.copy(editedFile.path);
      }
    }
  }

  String _documentScanName(DateTime timestamp) {
    return 'scan_${_documentScanNameDateFormat.format(timestamp)}';
  }
}
