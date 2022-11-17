enum ProcessingStatus { starting, working, success, error }

enum ProcessingMessage {
  new_file,
  parsing_document,
  generating_thumbnail,
  parse_date,
  save_document,
  finished
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
