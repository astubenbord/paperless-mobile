import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/logging/utils/redaction_utils.dart';
import 'package:paperless_mobile/helpers/format_helpers.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class FileService {
  FileService._();

  static FileService? _singleton;

  late Directory _logDirectory;
  late Directory _temporaryDirectory;
  late Directory _documentsDirectory;
  late Directory _downloadsDirectory;
  late Directory _uploadDirectory;
  late Directory _temporaryScansDirectory;
  late Directory _documentScansDirectory;

  Directory get logDirectory => _logDirectory;
  Directory get temporaryDirectory => _temporaryDirectory;
  Directory get documentsDirectory => _documentsDirectory;
  Directory get downloadsDirectory => _downloadsDirectory;
  Directory get uploadDirectory => _uploadDirectory;
  Directory get temporaryScansDirectory => _temporaryScansDirectory;
  Directory get documentScansDirectory => _documentScansDirectory;

  Future<void> initialize() async {
    try {
      await Future.wait([
        _initTemporaryDirectory(),
        _initTemporaryScansDirectory(),
        _initUploadDirectory(),
        _initLogDirectory(),
        _initDownloadsDirectory(),
        _initializeDocumentsDirectory(),
        _initializeDocumentScansDirectory(),
      ]);
    } catch (error, stackTrace) {
      debugPrint("Could not initialize directories.");
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Make sure to call and await initialize before accessing any of the instance members.
  static FileService get instance {
    _singleton ??= FileService._();
    return _singleton!;
  }

  Future<File> saveToFile(Uint8List bytes, String filename) async {
    File file = File(p.join(_logDirectory.path, filename));
    logger.fd(
      "Writing bytes to file $filename",
      methodName: 'saveToFile',
      className: runtimeType.toString(),
    );
    return file..writeAsBytes(bytes);
  }

  Directory getDirectory(PaperlessDirectoryType type) {
    return switch (type) {
      PaperlessDirectoryType.documents => _documentsDirectory,
      PaperlessDirectoryType.temporary => _temporaryDirectory,
      PaperlessDirectoryType.scans => _temporaryScansDirectory,
      PaperlessDirectoryType.download => _downloadsDirectory,
      PaperlessDirectoryType.upload => _uploadDirectory,
      PaperlessDirectoryType.logs => _logDirectory,
      PaperlessDirectoryType.documentScans => _documentScansDirectory,
    };
  }

  ///
  /// Returns a [File] pointing to a temporary file in the directory specified by [type].
  /// If [create] is true, the file will be created.
  /// If [fileName] is left blank, a random UUID will be generated.
  ///
  Future<File> allocateTemporaryFile(
    PaperlessDirectoryType type, {
    required String extension,
    String? fileName,
    bool create = false,
  }) async {
    final dir = getDirectory(type);
    final filename = '${fileName ?? const Uuid().v1()}.$extension';
    final file = File(p.join(dir.path, filename));
    if (create) {
      await file.create(recursive: true);
    }
    return file;
  }

  Directory getDocumentScanDirectory(String documentId) {
    return Directory(p.join(_documentScansDirectory.path, documentId));
  }

  Directory getDocumentScanOriginalDirectory(String documentId) {
    return Directory(
      p.join(getDocumentScanDirectory(documentId).path, 'original'),
    );
  }

  Directory getDocumentScanEditedDirectory(String documentId) {
    return Directory(
      p.join(getDocumentScanDirectory(documentId).path, 'edited'),
    );
  }

  Future<Directory> createDocumentScanDirectory({
    required String documentId,
  }) async {
    final directory = await getDocumentScanDirectory(
      documentId,
    ).create(recursive: true);
    await Future.wait([
      getDocumentScanOriginalDirectory(documentId).create(recursive: true),
      getDocumentScanEditedDirectory(documentId).create(recursive: true),
    ]);
    return directory;
  }

  Future<void> removeDocumentScanDirectory({required String documentId}) async {
    final directory = getDocumentScanDirectory(documentId);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<Directory> getConsumptionDirectory({required String userId}) async {
    return Directory(
      p.join(_uploadDirectory.path, userId),
    ).create(recursive: true);
  }

  Future<void> clearUserData({required String userId}) async {
    final redactedId = redactUserId(userId);
    logger.fd(
      "Clearing data for user $redactedId...",
      className: runtimeType.toString(),
      methodName: "clearUserData",
    );

    final scanDirSize = formatBytes(
      await getDirSizeInBytes(_temporaryScansDirectory),
    );
    final tempDirSize = formatBytes(
      await getDirSizeInBytes(_temporaryDirectory),
    );
    final consumptionDir = await getConsumptionDirectory(userId: userId);
    final consumptionDirSize = formatBytes(
      await getDirSizeInBytes(consumptionDir),
    );

    logger.ft(
      "Clearing scans directory...",
      className: runtimeType.toString(),
      methodName: "clearUserData",
    );
    await _temporaryScansDirectory.clear();
    logger.ft(
      "Removed $scanDirSize...",
      className: runtimeType.toString(),
      methodName: "clearUserData",
    );
    logger.ft(
      "Removing temporary files and cache content...",
      className: runtimeType.toString(),
      methodName: "clearUserData",
    );

    await _temporaryDirectory.delete(recursive: true);
    logger.ft(
      "Removed $tempDirSize...",
      className: runtimeType.toString(),
      methodName: "clearUserData",
    );

    logger.ft(
      "Removing files waiting for consumption...",
      className: runtimeType.toString(),
      methodName: "clearUserData",
    );
    await consumptionDir.delete(recursive: true);
    logger.ft(
      "Removed $consumptionDirSize. Re-creating directories...",
      className: runtimeType.toString(),
      methodName: "clearUserData",
    );

    await initialize();
  }

  Future<int> clearDirectoryContent(
    PaperlessDirectoryType type, {
    bool filesOnly = false,
  }) async {
    final dir = getDirectory(type);
    final dirSize = await getDirSizeInBytes(dir);
    if (!await dir.exists()) {
      return 0;
    }
    final streamedEntities = filesOnly
        ? dir.list().whereType<File>().cast<FileSystemEntity>()
        : dir.list();

    final entities = await streamedEntities.toList();
    await Future.wait([
      for (var entity in entities) entity.delete(recursive: !filesOnly),
    ]);
    return dirSize;
  }

  Future<List<File>> getAllFiles(Directory directory) {
    return directory.list().whereType<File>().toList();
  }

  Future<List<Directory>> getAllSubdirectories(Directory directory) {
    return directory.list().whereType<Directory>().toList();
  }

  Future<int> getDirSizeInBytes(Directory dir) async {
    return dir
        .list(recursive: true)
        .fold(0, (previous, element) => previous + element.statSync().size);
  }

  Future<void> _initTemporaryDirectory() async {
    _temporaryDirectory = await getTemporaryDirectory().then(
      (value) => value.create(),
    );
  }

  Future<void> _initializeDocumentsDirectory() async {
    if (Platform.isAndroid) {
      final dirs = await getExternalStorageDirectories(
        type: StorageDirectory.documents,
      );
      _documentsDirectory = await dirs!.first.create(recursive: true);
      return;
    } else if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      _documentsDirectory = await Directory(
        p.join(dir.path, 'documents'),
      ).create(recursive: true);
      return;
    } else {
      throw UnsupportedError("Platform not supported.");
    }
  }

  Future<void> _initLogDirectory() async {
    if (Platform.isAndroid) {
      _logDirectory =
          await getExternalStorageDirectories(type: StorageDirectory.documents)
              .then(
                (directory) async =>
                    directory?.firstOrNull ??
                    await getApplicationDocumentsDirectory(),
              )
              .then(
                (directory) => Directory(
                  p.join(directory.path, 'logs'),
                ).create(recursive: true),
              );
      return;
    } else if (Platform.isIOS) {
      _logDirectory = await getApplicationDocumentsDirectory().then(
        (value) =>
            Directory(p.join(value.path, 'logs')).create(recursive: true),
      );
      return;
    }
    throw UnsupportedError("Platform not supported.");
  }

  Future<void> _initDownloadsDirectory() async {
    if (Platform.isAndroid) {
      var directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        final downloadsDir = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        directory = await downloadsDir!.first.create(recursive: true);
      }
      _downloadsDirectory = directory;
      return;
    } else if (Platform.isIOS) {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/downloads');
      _downloadsDirectory = await dir.create(recursive: true);
      return;
    } else {
      throw UnsupportedError("Platform not supported.");
    }
  }

  Future<void> _initUploadDirectory() async {
    final dir = await getApplicationDocumentsDirectory().then(
      (dir) => Directory(p.join(dir.path, 'upload')),
    );
    _uploadDirectory = await dir.create(recursive: true);
  }

  Future<void> _initTemporaryScansDirectory() async {
    final applicationDirectory = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(applicationDirectory.path, 'scans'));
    await dir.create(recursive: true);
    _temporaryScansDirectory = dir;
  }

  Future<void> _initializeDocumentScansDirectory() async {
    final applicationDirectory = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(applicationDirectory.path, 'document_scans'));
    _documentScansDirectory = await dir.create(recursive: true);
  }
}

enum PaperlessDirectoryType {
  documents,
  temporary,
  scans,
  download,
  documentScans,
  upload,
  logs,
}

extension ClearDirectoryExtension on Directory {
  Future<void> clear() async {
    final streamedEntities = list();
    final entities = await streamedEntities.toList();
    await Future.wait([
      for (var entity in entities) entity.delete(recursive: true),
    ]);
  }
}
