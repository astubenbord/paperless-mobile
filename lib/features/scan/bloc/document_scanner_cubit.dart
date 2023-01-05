import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';

class DocumentScannerCubit extends Cubit<List<File>> {
  DocumentScannerCubit() : super(const []);

  void addScan(File file) => emit([...state, file]);

  void removeScan(int fileIndex) {
    try {
      state[fileIndex].deleteSync();
      final scans = [...state];
      scans.removeAt(fileIndex);
      emit(scans);
    } catch (_) {
      throw const PaperlessServerException(ErrorCode.scanRemoveFailed);
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
      emit([]);
    } catch (_) {
      throw const PaperlessServerException(ErrorCode.scanRemoveFailed);
    }
  }
}
