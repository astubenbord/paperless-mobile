import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UploadDialog extends StatefulWidget {
  const UploadDialog({
    Key? key,
  }) : super(key: key);

  @override
  State<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<UploadDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    final DateFormat format = DateFormat("yyyy_MM_dd_hh_mm_ss");
    final today = format.format(DateTime.now());
    _controller = TextEditingController.fromValue(
        TextEditingValue(text: "Scan_$today.pdf"));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Upload to paperless-ng"),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          validator: (text) {
            if (text == null || text.isEmpty) {
              return "Filename must be specified!";
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            var txt = _controller.text;
            if (!txt.endsWith(".pdf")) {
              txt += ".pdf";
            }
            Navigator.of(context).pop(txt);
          },
          child: const Text("Upload"),
        ),
      ],
    );
  }
}
