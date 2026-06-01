import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:paperless_mobile/features/document_upload/view/document_upload_preparation_page.dart';

class DocumentUploadQueueProgress {
  final int currentItem;
  final int totalItems;

  const DocumentUploadQueueProgress({
    required this.currentItem,
    required this.totalItems,
  });

  bool get hasNext => currentItem < totalItems;

  bool get isQueued => totalItems > 1;
}

class DocumentUploadQueueItem<T> {
  final T source;
  final FutureOr<Uint8List> Function() loadFileBytes;
  final String? title;
  final String? filename;
  final String? fileExtension;
  final bool instantUpload;

  const DocumentUploadQueueItem({
    required this.source,
    required this.loadFileBytes,
    this.title,
    this.filename,
    this.fileExtension,
    this.instantUpload = false,
  });
}

enum DocumentUploadQueueCancellationDisposition {
  keepRemaining,
  discardRemaining,
}

abstract interface class DocumentUploadQueueDelegate<T> {
  Future<void> onItemUploaded(
    BuildContext context,
    DocumentUploadQueueItem<T> item,
    DocumentUploadResult result,
  );

  Future<DocumentUploadQueueCancellationDisposition> onQueueCancelled(
    BuildContext context,
    List<DocumentUploadQueueItem<T>> remainingItems,
  );

  Future<void> discardRemainingItems(
    BuildContext context,
    List<DocumentUploadQueueItem<T>> remainingItems,
  );

  Future<void> onQueueCompleted(BuildContext context) async {}
}
