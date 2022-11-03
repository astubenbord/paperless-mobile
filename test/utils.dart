import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:paperless_mobile/core/type/types.dart';

Future<T> loadOne<T>(String filePath, T Function(JSON) transformFn, int? id) async {
  if (id != null) {
    final coll = await loadCollection(filePath, transformFn);
    return coll.firstWhere((dynamic element) => element.id == id);
  }
  final String response = await rootBundle.loadString(filePath);
  return transformFn(jsonDecode(response));
}

Future<List<T>> loadCollection<T>(String filePath, T Function(JSON) transformFn,
    {int? numItems, List<int>? ids}) async {
  assert(((numItems != null) ^ (ids != null)) || (numItems == null && ids == null));
  final String response = await rootBundle.loadString(filePath);
  final lst = (jsonDecode(response) as List<dynamic>);
  final res = (jsonDecode(response) as List<dynamic>).map((e) => transformFn(e)).toList();
  if (ids != null) {
    return res.where((dynamic element) => ids.contains(element.id)).toList();
  }
  if (numItems != null && lst.length < numItems) {
    throw Exception("The requested collection contains only ${lst.length} items!");
  } else {
    return res.sublist(0, numItems);
  }
}

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
String getRandomString(int length) => String.fromCharCodes(
    Iterable.generate(length, (_) => _chars.codeUnitAt(Random().nextInt(_chars.length))));
