import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/repository/document_repository.dart';

@injectable
class DocumentScannerCubit extends Cubit<List<File>> {
  final DocumentRepository documentRepository;

  static List<File> initialState = [];

  DocumentScannerCubit(this.documentRepository) : super(initialState);

  void addScan(File file) => emit([...state, file]);

  void removeScan(int fileIndex) {
    try {
      state[fileIndex].deleteSync();
      final scans = [...state];
      scans.removeAt(fileIndex);
      emit(scans);
    } catch (_) {
      throw const ErrorMessage(ErrorCode.scanRemoveFailed);
    }
  }

  void reset() {
    try {
      for (final doc in state) {
        doc.deleteSync();
        if (kDebugMode) {
          log('[ScannerCubit]: Removed ${doc.path}');
        }
      }
      imageCache.clear();
      emit(initialState);
    } catch (_) {
      throw const ErrorMessage(ErrorCode.scanRemoveFailed);
    }
  }

  Future<void> uploadDocument(
    Uint8List bytes,
    String fileName, {
    required String title,
    required void Function(DocumentModel document)? onConsumptionFinished,
    int? documentType,
    int? correspondent,
    Iterable<int> tags = const [],
    DateTime? createdAt,
  }) async {
    await documentRepository.create(
      bytes,
      fileName,
      title: title,
      documentType: documentType,
      correspondent: correspondent,
      tags: tags,
      createdAt: createdAt,
    );
    if (onConsumptionFinished != null) {
      documentRepository
          .waitForConsumptionFinished(fileName, title)
          .then((value) => onConsumptionFinished(value));
    }
  }
}
