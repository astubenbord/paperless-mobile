import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:path/path.dart' as p;

part 'receive_share_state.dart';

class ConsumptionChangeNotifier extends ChangeNotifier {
  List<File> pendingFiles = [];

  final Completer _restored = Completer();

  Future<void> get isInitialized => _restored.future;

  Future<void> loadFromConsumptionDirectory({required String userId}) async {
    pendingFiles = await _getCurrentFiles(userId);
    if (!_restored.isCompleted) {
      _restored.complete();
    }
    notifyListeners();
  }

  /// Creates a local copy of all shared files and reloads all files
  /// from the user's consumption directory. Returns the newly added files copied to the consumption directory.
  Future<List<File>> addFiles({
    required List<File> files,
    required String userId,
  }) async {
    if (files.isEmpty) {
      return [];
    }
    final consumptionDirectory = await FileService.instance
        .getConsumptionDirectory(userId: userId);
    final List<File> localFiles = [];
    for (final file in files) {
      if (!file.path.startsWith(consumptionDirectory.path)) {
        final localFile = await file.copy(
          p.join(consumptionDirectory.path, p.basename(file.path)),
        );
        localFiles.add(localFile);
      } else {
        localFiles.add(file);
      }
    }
    await loadFromConsumptionDirectory(userId: userId);
    return localFiles;
  }

  /// Marks a file as processed by removing it from the queue and deleting the local copy of the file.
  Future<void> discardFile(File file, {required String userId}) async {
    final consumptionDirectory = await FileService.instance
        .getConsumptionDirectory(userId: userId);
    if (file.path.startsWith(consumptionDirectory.path)) {
      await file.delete();
    }
    return loadFromConsumptionDirectory(userId: userId);
  }

  /// Returns the next file to process of null if no file exists.
  Future<File?> getNextFile({required String userId}) async {
    final files = await _getCurrentFiles(userId);
    if (files.isEmpty) {
      return null;
    }
    return files.first;
  }

  Future<List<File>> _getCurrentFiles(String userId) async {
    final directory = await FileService.instance.getConsumptionDirectory(
      userId: userId,
    );
    return await FileService.instance.getAllFiles(directory);
  }
}
