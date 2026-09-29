import 'dart:io';

import 'package:flutter/services.dart';
import 'package:paperless_mobile/api/models/models.dart';

/// Bridge to the native Android search index. All calls no-op on other platforms.
class SearchIndexChannel {
  const SearchIndexChannel();

  static const _channel = MethodChannel(
    'de.astubenbord.paperless_mobile/search_index',
  );

  Future<void> put(String userId, List<Document> documents) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('put', {
      'userId': userId,
      'documents': [
        for (final d in documents)
          {'id': d.id, 'title': d.title, 'content': d.content},
      ],
    });
  }

  Future<void> retainOnly(String userId, List<int> ids) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('retainOnly', {'userId': userId, 'ids': ids});
  }

  Future<void> clear(String userId) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('clear', {'userId': userId});
  }

  Future<int> count(String userId) async {
    if (!Platform.isAndroid) return 0;
    return await _channel.invokeMethod<int>('count', {'userId': userId}) ?? 0;
  }

  Future<void> setActiveUser(String? userId) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('setActiveUser', {'userId': userId});
  }

  Future<int?> takePendingDocumentId() async {
    if (!Platform.isAndroid) return null;
    return _channel.invokeMethod<int>('takePendingDocumentId');
  }

  void setOpenDocumentHandler(void Function(int documentId) onOpenDocument) {
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openDocument') {
        onOpenDocument(call.arguments['id'] as int);
      }
    });
  }
}
