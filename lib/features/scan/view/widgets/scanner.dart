import 'dart:io';

import 'package:flutter/material.dart';
import 'package:paperless_mobile/util.dart';
import 'package:permission_handler/permission_handler.dart';

typedef OnImageScannedCallback = void Function(File);

class ScannerWidget extends StatefulWidget {
  final OnImageScannedCallback onImageScannedCallback;
  const ScannerWidget({
    Key? key,
    required this.onImageScannedCallback,
  }) : super(key: key);

  @override
  _ScannerWidgetState createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget> {
  List<File> documents = List.empty(growable: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan document")),
      body: FutureBuilder<bool>(
          future: askForPermission(Permission.camera),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!) {
              return Container();
            }
            return const Center(
              child: Text("No camera permissions, please enable in settings!"),
            );
          }),
    );
  }
}
