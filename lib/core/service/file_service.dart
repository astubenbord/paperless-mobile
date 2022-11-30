import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileService {
  static Future<File> saveToFile(
    Uint8List bytes,
    String filename,
  ) async {
    final dir = await documentsDirectory;
    if (dir == null) {
      throw const ErrorMessage.unknown(); //TODO: better handling
    }
    File file = File("${dir.path}/$filename");
    return file..writeAsBytes(bytes);
  }

  static Future<Directory?> getDirectory(PaperlessDirectoryType type) {
    switch (type) {
      case PaperlessDirectoryType.documents:
        return documentsDirectory;
      case PaperlessDirectoryType.temporary:
        return temporaryDirectory;
      case PaperlessDirectoryType.scans:
        return scanDirectory;
      case PaperlessDirectoryType.download:
        return downloadsDirectory;
    }
  }

  static Future<File> allocateTemporaryFile(
    PaperlessDirectoryType type, {
    required String extension,
    String? fileName,
  }) async {
    final dir = await getDirectory(type);
    final _fileName = (fileName ?? const Uuid().v1()) + '.$extension';
    return File('${dir?.path}/$_fileName');
  }

  static Future<Directory> get temporaryDirectory => getTemporaryDirectory();

  static Future<Directory?> get documentsDirectory async {
    if (Platform.isAndroid) {
      return (await getExternalStorageDirectories(
        type: StorageDirectory.documents,
      ))!
          .first;
    } else if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    } else {
      throw UnsupportedError("Platform not supported.");
    }
  }

  static Future<Directory?> get downloadsDirectory async {
    if (Platform.isAndroid) {
      return (await getExternalStorageDirectories(
              type: StorageDirectory.downloads))!
          .first;
    } else if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    } else {
      throw UnsupportedError("Platform not supported.");
    }
  }

  static Future<Directory?> get scanDirectory async {
    if (Platform.isAndroid) {
      return (await getExternalStorageDirectories(type: StorageDirectory.dcim))!
          .first;
    } else if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    } else {
      throw UnsupportedError("Platform not supported.");
    }
  }

  static Future<void> clearUserData() async {
    final scanDir = await scanDirectory;
    final tempDir = await temporaryDirectory;
    scanDir?.delete(recursive: true);
    tempDir.delete(recursive: true);
  }
}

enum PaperlessDirectoryType {
  documents,
  temporary,
  scans,
  download;
}
