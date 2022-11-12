import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:injectable/injectable.dart';

@singleton
class DocumentScannerCubit extends Cubit<List<File>> {
  static List<File> initialState = [];

  DocumentScannerCubit() : super(initialState);

  void addScan(File file) => emit([...state, file]);

  void removeScan(int fileIndex) {
    try {
      state[fileIndex].deleteSync();
      final scans = [...state];
      scans.removeAt(fileIndex);
      emit(scans);
    } catch (_) {
      addError(const ErrorMessage(ErrorCode.scanRemoveFailed));
    }
  }

  void reset() {
    for (final doc in state) {
      doc.deleteSync();
      if (kDebugMode) {
        log('[ScannerCubit]: Removed ${doc.path}');
      }
    }

    imageCache.clear();
    emit(initialState);
  }
}
