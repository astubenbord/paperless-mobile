import 'package:flutter/material.dart';
import 'package:paperless_mobile/features/document_upload/model/document_upload_queue.dart';
import 'package:paperless_mobile/features/document_upload/view/document_upload_preparation_page.dart';
import 'package:paperless_mobile/routing/navigation_keys.dart';

class DocumentUploadQueueCoordinator {
  static Future<void> processQueue<T>(
    BuildContext context, {
    required List<DocumentUploadQueueItem<T>> items,
    required DocumentUploadQueueDelegate<T> delegate,
  }) async {
    if (items.isEmpty) {
      return;
    }

    final navigator =
        outerShellNavigatorKey.currentState ??
        Navigator.of(context, rootNavigator: true);

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final result = await navigator.push<DocumentUploadResult?>(
        MaterialPageRoute(
          builder: (routeContext) => DocumentUploadPreparationPage(
            fileBytes: item.loadFileBytes(),
            title: item.title,
            filename: item.filename,
            fileExtension: item.fileExtension,
            instantUpload: item.instantUpload,
            uploadQueueProgress: DocumentUploadQueueProgress(
              currentItem: index + 1,
              totalItems: items.length,
            ),
          ),
        ),
      );

      if (result?.success ?? false) {
        if (!context.mounted) {
          return;
        }
        await delegate.onItemUploaded(context, item, result!);
        if (!context.mounted) {
          return;
        }
        continue;
      }

      if (!context.mounted) {
        return;
      }

      final remainingItems = items.sublist(index);
      final disposition = await delegate.onQueueCancelled(
        context,
        remainingItems,
      );
      if (!context.mounted) {
        return;
      }
      if (disposition ==
          DocumentUploadQueueCancellationDisposition.discardRemaining) {
        await delegate.discardRemainingItems(context, remainingItems);
        if (!context.mounted) {
          return;
        }
      }
      return;
    }

    if (!context.mounted) {
      return;
    }
    await delegate.onQueueCompleted(context);
  }
}
