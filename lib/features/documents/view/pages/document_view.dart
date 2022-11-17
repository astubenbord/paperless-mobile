import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/repository/document_repository.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:pdfx/pdfx.dart';

class DocumentView extends StatefulWidget {
  final Future<Uint8List> documentBytes;

  const DocumentView({
    Key? key,
    required this.documentBytes,
  }) : super(key: key);

  @override
  State<DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<DocumentView> {
  late PdfController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openData(
        widget.documentBytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).documentPreviewPageTitle),
      ),
      body: PdfView(
        builders: PdfViewBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          pageLoaderBuilder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        controller: _pdfController,
      ),
    );
  }
}
