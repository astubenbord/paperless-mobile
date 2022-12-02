import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';

@injectable
class DocumentScannerCubit extends Cubit<List<File>> {
  final PaperlessDocumentsApi _api;

  static List<File> initialState = [];

  DocumentScannerCubit(this._api) : super(initialState);

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
      emit(initialState);
    } catch (_) {
      throw const PaperlessServerException(ErrorCode.scanRemoveFailed);
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
    final auth = getIt<AuthenticationCubit>().state.authentication;
    if (auth == null) {
      throw const PaperlessServerException(ErrorCode.notAuthenticated);
    }
    await _api.create(
      bytes,
      filename: fileName,
      title: title,
      documentType: documentType,
      correspondent: correspondent,
      tags: tags,
      createdAt: createdAt,
      authToken: auth.token,
      serverUrl: auth.serverUrl,
    );
    if (onConsumptionFinished != null) {
      _api
          .waitForConsumptionFinished(fileName, title)
          .then((value) => onConsumptionFinished(value));
    }
  }
}
