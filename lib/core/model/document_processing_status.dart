enum ProcessingStatus { starting, working, success, error }

enum ProcessingMessage {
  // ignore: constant_identifier_names
  new_file,
  // ignore: constant_identifier_names
  parsing_document,
  // ignore: constant_identifier_names
  generating_thumbnail,
  // ignore: constant_identifier_names
  parse_date,
  // ignore: constant_identifier_names
  save_document,
  finished,
}

class DocumentProcessingStatus {
  final int currentProgress;
  final int? documentId;
  final String filename;
  final int maxProgress;
  final ProcessingMessage message;
  final ProcessingStatus status;
  final String taskId;
  final bool isApproximated;

  static const String unknownTaskId = "NO_TASK_ID";

  DocumentProcessingStatus({
    required this.currentProgress,
    this.documentId,
    required this.filename,
    required this.maxProgress,
    required this.message,
    required this.status,
    required this.taskId,
    this.isApproximated = false,
  });

  factory DocumentProcessingStatus.fromJson(Map<dynamic, dynamic> json) {
    return DocumentProcessingStatus(
      currentProgress: json['current_progress'],
      documentId: json['documentId'],
      filename: json['filename'],
      maxProgress: json['max_progress'],
      message: ProcessingMessage.values.byName(json['message']),
      status: ProcessingStatus.values.byName(json['status']),
      taskId: json['task_id'],
    );
  }
}
