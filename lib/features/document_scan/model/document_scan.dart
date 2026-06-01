import 'dart:io';
import 'dart:ui';

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/features/scanner/models/document_frame.dart';
import 'package:paperless_mobile/features/scanner/models/scan_result.dart';
import 'package:path/path.dart' as p;

part 'document_scan.g.dart';

@CopyWith()
@JsonSerializable()
class DocumentScan {
  final String id;
  final String name;
  final String directoryPath;
  final DateTime createdAt;
  @JsonKey(defaultValue: <ScanResult>[])
  final List<ScanResult> pages;

  const DocumentScan({
    required this.id,
    required this.name,
    required this.directoryPath,
    required this.createdAt,
    this.pages = const [],
  });

  Map<String, dynamic> toJson() => _$DocumentScanToJson(this);

  factory DocumentScan.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('page_file_names') && !json.containsKey('pages')) {
      final legacyPageFileNames =
          (json['page_file_names'] as List<dynamic>? ?? const [])
              .cast<String>();
      return DocumentScan(
        id: json['id'] as String,
        name: json['name'] as String,
        directoryPath: json['directory_path'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        pages: [
          for (final fileName in legacyPageFileNames) _legacyPage(fileName),
        ],
      );
    }
    return _$DocumentScanFromJson(json);
  }

  int get pageCount => pages.length;

  Directory get originalDirectory =>
      Directory(p.join(directoryPath, 'original'));

  Directory get editedDirectory => Directory(p.join(directoryPath, 'edited'));

  String? get coverFilePath {
    if (pages.isEmpty) {
      return null;
    }
    return p.join(editedDirectory.path, pages.first.editedFileName);
  }

  File? get coverFile {
    final path = coverFilePath;
    return path == null ? null : File(path);
  }

  List<File> get pageFiles {
    return [for (final page in pages) page.editedFile(editedDirectory)];
  }

  Directory get directory => Directory(directoryPath);
}

ScanResult _legacyPage(String fileName) {
  return ScanResult(
    originalFileName: fileName,
    editedFileName: fileName,
    originalImageSize: Size.zero,
    cropFrame: DocumentFrame(
      topLeft: Offset.zero,
      topRight: Offset.zero,
      bottomRight: Offset.zero,
      bottomLeft: Offset.zero,
    ),
    quarterTurns: 0,
    colorFilter: ScanColorFilter.none,
    bwThreshold: 10,
    enhanced: false,
  );
}
