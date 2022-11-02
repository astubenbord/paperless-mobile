import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

final dateFormat = DateFormat("yyyy-MM-dd");
final GlobalKey<ScaffoldState> rootScaffoldKey = GlobalKey<ScaffoldState>();
late PackageInfo kPackageInfo;

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void showError(BuildContext context, ErrorMessage error) {
  showSnackBar(context, translateError(context, error.code));
}

bool isNotNull(dynamic value) {
  return value != null;
}

String formatDate(DateTime date) {
  return dateFormat.format(date);
}

String? formatDateNullable(DateTime? date) {
  if (date == null) return null;
  return dateFormat.format(date);
}

Future<String> writeToFile(Uint8List data) async {
  Directory tempDir = await getTemporaryDirectory();
  String tempPath = tempDir.path;
  var filePath = tempPath + '/file_01.tmp'; // file_01.tmp is dump file, can be anything
  return (await File(filePath).writeAsBytes(data)).path;
}

void setKeyNullable(Map data, String key, dynamic value) {
  if (value != null) {
    data[key] = value is String ? value : json.encode(value);
  }
}

String formatLocalDate(BuildContext context, DateTime dateTime) {
  final tag = Localizations.maybeLocaleOf(context)?.toLanguageTag();
  return DateFormat.yMMMd(tag).format(dateTime);
}
