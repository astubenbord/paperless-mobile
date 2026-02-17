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
// import 'dart:async';
// import 'dart:developer';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
// import 'package:pdfx/pdfx.dart';

// class DocumentView extends StatefulWidget {
//   final String? filePath;
//   final Future<Uint8List>? bytes;
//   final String? title;
//   final bool showAppBar;
//   final bool showControls;
//   const DocumentView({
//     super.key,
//     this.bytes,
//     this.showAppBar = true,
//     this.showControls = true,
//     this.title,
//     this.filePath,
//   }) : assert(bytes != null || filePath != null);

//   @override
//   State<DocumentView> createState() => _DocumentViewState();
// }

// class _DocumentViewState extends State<DocumentView> {
//   late final PdfController _controller;
//   int _currentPage = 1;
//   int? _totalPages;
//   @override
//   void initState() {
//     super.initState();
//     Future<PdfDocument> document;
//     if (widget.bytes != null) {
//       document = widget.bytes!.then((value) => PdfDocument.openData(value));
//     } else {
//       document = PdfDocument.openFile(widget.filePath!);
//     }
//     _controller = PdfController(document: document);
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final pageTransitionDuration = MediaQuery.disableAnimationsOf(context)
//         ? 0.milliseconds
//         : 100.milliseconds;
//     final canGoToNextPage = _totalPages != null && _currentPage < _totalPages!;
//     final canGoToPreviousPage =
//         _controller.pagesCount != null && _currentPage > 1;
//     return Scaffold(
//       appBar: widget.showAppBar
//           ? AppBar(
//               title: widget.title != null ? Text(widget.title!) : null,
//             )
//           : null,
//       bottomNavigationBar: widget.showControls
//           ? BottomAppBar(
//               child: Row(
//                 children: [
//                   Flexible(
//                     child: Row(
//                       children: [
//                         IconButton.filled(
//                           onPressed: canGoToPreviousPage
//                               ? () async {
//                                   await _controller.previousPage(
//                                     duration: pageTransitionDuration,
//                                     curve: Curves.easeOut,
//                                   );
//                                 }
//                               : null,
//                           icon: const Icon(Icons.arrow_left),
//                         ),
//                         const SizedBox(width: 16),
//                         IconButton.filled(
//                           onPressed: canGoToNextPage
//                               ? () async {
//                                   await _controller.nextPage(
//                                     duration: pageTransitionDuration,
//                                     curve: Curves.easeOut,
//                                   );
//                                 }
//                               : null,
//                           icon: const Icon(Icons.arrow_right),
//                         ),
//                       ],
//                     ),
//                   ),
//                   PdfPageNumber(
//                     controller: _controller,
//                     builder: (context, loadingState, page, pagesCount) {
//                       if (loadingState != PdfLoadingState.success) {
//                         return const Text("-/-");
//                       }
//                       return Text(
//                         "$page/$pagesCount",
//                         style: Theme.of(context).textTheme.titleMedium,
//                       ).padded();
//                     },
//                   ),
//                 ],
//               ),
//             )
//           : null,
//       body: PdfView(
//         builders: PdfViewBuilders<DefaultBuilderOptions>(
//           options: const DefaultBuilderOptions(),
//           documentLoaderBuilder: (_) =>
//               const Center(child: CircularProgressIndicator()),
//           pageLoaderBuilder: (_) =>
//               const Center(child: CircularProgressIndicator()),
//           errorBuilder: (p0, error) {
//             return Center(
//               child: Text(error.toString()),
//             );
//           },
//         ),
//         onPageChanged: (page) {
//           setState(() {
//             _currentPage = page;
//           });
//         },
//         controller: _controller,
//       ),
//       // PdfView(
//       //   controller: _controller,
//       //   onDocumentLoaded: (document) {
//       //     setState(() {
//       //       _totalPages = document.pagesCount;
//       //     });
//       //   },
//       //   onPageChanged: (page) {
//       //     setState(() {
//       //       _currentPage = page;
//       //     });
//       //   },
//       // ),
//     );
//   }
// }

// import 'dart:math';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
// import 'package:pdfrx/pdfrx.dart';

// class DocumentView extends StatefulWidget {
//   final Future<Uint8List> bytes;
//   final String? title;
//   final bool showAppBar;
//   final bool showControls;
//   const DocumentView({
//     Key? key,
//     required this.bytes,
//     this.showAppBar = true,
//     this.showControls = true,
//     this.title,
//   }) : super(key: key);

//   @override
//   State<DocumentView> createState() => _DocumentViewState();
// }

// class _DocumentViewState extends State<DocumentView> {
//   late final PdfViewerController _controller;
//   int _currentPage = 1;
//   int? _totalPages;
//   @override
//   void initState() {
//     super.initState();
//     _controller = PdfViewerController()
//       ..addListener(() {
//         if (_controller.isLoaded) {
//           setState(() {
//             _totalPages = _controller.pages.length;
//           });
//         }
//       });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final pageTransitionDuration = MediaQuery.disableAnimationsOf(context)
//         ? 0.milliseconds
//         : 100.milliseconds;
//     final canGoToNextPage = _controller.isLoaded && _currentPage < _totalPages!;
//     final canGoToPreviousPage = _controller.isLoaded && _currentPage > 1;
//     return SafeArea(
//       child: Scaffold(
//         appBar: widget.showAppBar
//             ? AppBar(
//                 title: widget.title != null ? Text(widget.title!) : null,
//               )
//             : null,
//         bottomNavigationBar: widget.showControls
//             ? BottomAppBar(
//                 child: Row(
//                   children: [
//                     Flexible(
//                       child: Row(
//                         children: [
//                           IconButton.filled(
//                             onPressed: canGoToPreviousPage
//                                 ? () async {
//                                     await _controller.goToPage(
//                                       pageNumber: _currentPage - 1,
//                                       duration: pageTransitionDuration,
//                                     );
//                                   }
//                                 : null,
//                             icon: const Icon(Icons.arrow_left),
//                           ),
//                           const SizedBox(width: 16),
//                           IconButton.filled(
//                             onPressed: canGoToNextPage
//                                 ? () async {
//                                     await _controller.goToPage(
//                                       pageNumber: _currentPage + 1,
//                                       duration: pageTransitionDuration,
//                                     );
//                                   }
//                                 : null,
//                             icon: const Icon(Icons.arrow_right),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Builder(
//                       builder: (context) {
//                         if (_totalPages == null) {
//                           return const SizedBox.shrink();
//                         }
//                         return Text(
//                           "$_currentPage/$_totalPages",
//                           style: Theme.of(context).textTheme.titleMedium,
//                         ).padded();
//                       },
//                     ),
//                   ],
//                 ),
//               )
//             : null,
//         body: FutureBuilder<Uint8List>(
//           future: widget.bytes,
//           builder: (context, snapshot) {
//             if (!snapshot.hasData) {
//               return const Center(child: CircularProgressIndicator());
//             }
//             return PdfViewer.data(
//               snapshot.data!,
//               controller: _controller,
//               displayParams: PdfViewerParams(
//                 minScale: 1,
//                 boundaryMargin: EdgeInsets.all(24),
//                 pageAnchor: PdfPageAnchor.center,
//                 backgroundColor: Theme.of(context).colorScheme.background,
//                 loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
//                   return Center(
//                     child: CircularProgressIndicator(),
//                   );
//                 },
//                 layoutPages: (pages, params) {
//                   final height =
//                       pages.fold(0.0, (prev, page) => max(prev, page.height)) +
//                           params.margin * 2;
//                   final pageLayouts = <Rect>[];
//                   double x = params.margin;
//                   for (var page in pages) {
//                     pageLayouts.add(
//                       Rect.fromLTWH(
//                         x,
//                         (height - page.height) / 2, // center vertically
//                         page.width,
//                         page.height,
//                       ),
//                     );
//                     x += page.width + params.margin;
//                   }
//                   return PdfPageLayout(
//                     pageLayouts: pageLayouts,
//                     documentSize: Size(x, height),
//                   );
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
