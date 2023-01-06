import 'dart:collection';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:rxdart/rxdart.dart';

class ShareIntentQueue extends ChangeNotifier {
  final Queue<SharedMediaFile> _queue = Queue();

  ShareIntentQueue._();

  static final instance = ShareIntentQueue._();

  void add(SharedMediaFile file) {
    _queue.add(file);
    notifyListeners();
  }

  void addAll(Iterable<SharedMediaFile> files) {
    _queue.addAll(files);
    notifyListeners();
  }

  SharedMediaFile? pop() {
    if (hasUnhandledFiles) {
      return _queue.removeFirst();
      // Don't notify listeners, only when new item is added.
    } else {
      return null;
    }
  }

  bool get hasUnhandledFiles => _queue.isNotEmpty;
}
