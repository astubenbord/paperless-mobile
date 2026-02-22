import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:pdfx/pdfx.dart';

class DocumentView extends StatefulWidget {
  final Future<Uint8List> bytes;
  final String? title;
  final bool showAppBar;
  final bool showControls;
  const DocumentView({
    super.key,
    required this.bytes,
    this.showAppBar = true,
    this.showControls = true,
    this.title,
  });

  @override
  State<DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<DocumentView> {
  late final PdfController _controller;
  int _currentPage = 1;
  int? _totalPages;
  @override
  void initState() {
    super.initState();
    final document = widget.bytes.then((value) => PdfDocument.openData(value));
    _controller = PdfController(document: document);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageTransitionDuration = MediaQuery.disableAnimationsOf(context)
        ? 0.milliseconds
        : 100.milliseconds;
    final canGoToNextPage = _totalPages != null && _currentPage < _totalPages!;
    final canGoToPreviousPage =
        _controller.pagesCount != null && _currentPage > 1;
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: widget.title != null ? Text(widget.title!) : null,
            )
          : null,
      bottomNavigationBar: widget.showControls
          ? BottomAppBar(
              child: Row(
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        IconButton.filled(
                          onPressed: canGoToPreviousPage
                              ? () async {
                                  await _controller.previousPage(
                                    duration: pageTransitionDuration,
                                    curve: Curves.easeOut,
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.arrow_left),
                        ),
                        const SizedBox(width: 16),
                        IconButton.filled(
                          onPressed: canGoToNextPage
                              ? () async {
                                  await _controller.nextPage(
                                    duration: pageTransitionDuration,
                                    curve: Curves.easeOut,
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.arrow_right),
                        ),
                      ],
                    ),
                  ),
                  PdfPageNumber(
                    controller: _controller,
                    builder: (context, loadingState, page, pagesCount) {
                      if (loadingState != PdfLoadingState.success) {
                        return const Text("-/-");
                      }
                      return Text(
                        "$page/$pagesCount",
                        style: Theme.of(context).textTheme.titleMedium,
                      ).padded();
                    },
                  ),
                ],
              ),
            )
          : null,
      body: PdfView(
        controller: _controller,
        onDocumentLoaded: (document) {
          if (mounted) {
            setState(() {
              _totalPages = document.pagesCount;
            });
          }
        },
        onPageChanged: (page) {
          if (mounted) {
            setState(() {
              _currentPage = page;
            });
          }
        },
      ),
    );
  }
}
