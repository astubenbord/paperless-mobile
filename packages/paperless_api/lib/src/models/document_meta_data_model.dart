class DocumentMetaData {
  String originalChecksum;
  int originalSize;
  String originalMimeType;
  String mediaFilename;
  bool hasArchiveVersion;
  String? archiveChecksum;
  int? archiveSize;

  DocumentMetaData({
    required this.originalChecksum,
    required this.originalSize,
    required this.originalMimeType,
    required this.mediaFilename,
    required this.hasArchiveVersion,
    this.archiveChecksum,
    this.archiveSize,
  });

  DocumentMetaData.fromJson(Map<String, dynamic> json)
      : originalChecksum = json['original_checksum'],
        originalSize = json['original_size'],
        originalMimeType = json['original_mime_type'],
        mediaFilename = json['media_filename'],
        hasArchiveVersion = json['has_archive_version'],
        archiveChecksum = json['archive_checksum'],
        archiveSize = json['archive_size'];

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['original_checksum'] = originalChecksum;
    data['original_size'] = originalSize;
    data['original_mime_type'] = originalMimeType;
    data['media_filename'] = mediaFilename;
    data['has_archive_version'] = hasArchiveVersion;
    data['archive_checksum'] = archiveChecksum;
    data['archive_size'] = archiveSize;
    return data;
  }
}
