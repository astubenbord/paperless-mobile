import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:paperless_mobile/features/documents/view/pages/viewers/android_pdf_text_selection_handle.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

/// A viewer for PDF documents.
///
/// Displays PDF pages with navigation controls (previous/next page)
/// and a page number indicator.
class PdfDocumentViewer extends StatefulWidget {
  final Uint8List bytes;
  final String? title;
  final bool showAppBar;
  final bool showControls;

  const PdfDocumentViewer({
    super.key,
    required this.bytes,
    this.title,
    this.showAppBar = true,
    this.showControls = true,
  });

  @override
  State<PdfDocumentViewer> createState() => _PdfDocumentViewerState();
}

class _PdfDocumentViewerState extends State<PdfDocumentViewer> {
  final PdfViewerController _controller = PdfViewerController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _currentPage = 1;
  int? _totalPages;
  bool _isSearchMode = false;
  PdfTextSearcher? _textSearcher;

  String get _sourceName =>
      '${widget.title ?? 'document'}-${widget.bytes.hashCode}-${widget.bytes.lengthInBytes}';

  bool get _hasSearchQuery => _searchController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _disposeTextSearcher();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageTransitionDuration = MediaQuery.disableAnimationsOf(context)
        ? 0.milliseconds
        : 100.milliseconds;
    final canGoToNextPage = _totalPages != null && _currentPage < _totalPages!;
    final canGoToPreviousPage = _currentPage > 1;

    return Scaffold(
      appBar: widget.showAppBar ? _buildAppBar(context) : null,
      bottomNavigationBar: _buildControls(
        canGoToPreviousPage,
        pageTransitionDuration,
        canGoToNextPage,
      ),
      body: PdfViewer.data(
        widget.bytes,
        sourceName: _sourceName,
        controller: _controller,
        params: PdfViewerParams(
          backgroundColor: Theme.of(context).colorScheme.surface,
          textSelectionParams: PdfTextSelectionParams(
            enabled: true,
            buildSelectionHandle: (context, anchor, state) {
              return AndroidPdfTextSelectionHandle(
                anchor: anchor,
                state: state,
              );
            },
            calcSelectionHandleOffset:
                AndroidPdfTextSelectionHandle.offsetForAnchor,
          ),
          viewerOverlayBuilder: (context, size, handleLinkTap) => [
            if (_controller.pageCount > 1)
              PdfViewerScrollThumb(
                controller: _controller,
                orientation: ScrollbarOrientation.right,
                thumbSize: const Size(44, 28),
                margin: 8,
                thumbBuilder: _buildScrollThumb,
              ),
          ],
          pagePaintCallbacks: [
            if (_textSearcher != null)
              _textSearcher!.pageTextMatchPaintCallback,
          ],
          onViewerReady: (document, controller) {
            _attachTextSearcher(controller);
            if (!mounted) {
              return;
            }
            setState(() {
              _totalPages = document.pages.length;
              _currentPage = controller.pageNumber ?? 1;
            });
          },
          onPageChanged: (pageNumber) {
            if (!mounted || pageNumber == null) {
              return;
            }
            setState(() {
              _currentPage = pageNumber;
            });
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: _isSearchMode ? 0 : null,
      title: _isSearchMode
          ? _buildSearchBar(context)
          : widget.title != null
          ? Text(widget.title!)
          : null,
      actionsPadding: EdgeInsets.symmetric(horizontal: _isSearchMode ? 0 : 8),
      actions: _isSearchMode
          ? const []
          : [
              IconButton(
                onPressed: _openSearch,
                icon: const Icon(Icons.search),
                tooltip: MaterialLocalizations.of(context).searchFieldLabel,
              ),
            ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final textSearcher = _textSearcher;
    final hasMatches = textSearcher?.matches.isNotEmpty ?? false;
    final currentMatchIndex = textSearcher?.currentIndex;
    final matchCount = textSearcher?.matches.length ?? 0;

    return SearchBar(
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: S.of(context)!.searchContent,
      autoFocus: true,
      elevation: const WidgetStatePropertyAll<double>(0),
      backgroundColor: WidgetStatePropertyAll<Color>(
        Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      side: const WidgetStatePropertyAll<BorderSide>(BorderSide.none),
      padding: const WidgetStatePropertyAll<EdgeInsets>(
        EdgeInsets.symmetric(horizontal: 12),
      ),
      constraints: const BoxConstraints(minHeight: 46),
      leading: const Icon(Icons.search),
      textInputAction: TextInputAction.search,
      onChanged: _handleSearchChanged,
      onSubmitted: _handleSearchSubmitted,
      trailing: [
        if (textSearcher?.isSearching ?? false)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        if (_hasSearchQuery)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              hasMatches ? '${(currentMatchIndex ?? 0) + 1}/$matchCount' : '0',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        IconButton(
          onPressed: hasMatches ? _goToPreviousMatch : null,
          icon: const Icon(Icons.keyboard_arrow_up),
          tooltip: MaterialLocalizations.of(context).previousPageTooltip,
        ),
        IconButton(
          onPressed: hasMatches ? _goToNextMatch : null,
          icon: const Icon(Icons.keyboard_arrow_down),
          tooltip: MaterialLocalizations.of(context).nextPageTooltip,
        ),
        IconButton(
          onPressed: _closeSearch,
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        ),
      ],
    );
  }

  void _attachTextSearcher(PdfViewerController controller) {
    if (_textSearcher?.controller == controller) {
      return;
    }
    _disposeTextSearcher();
    _textSearcher = PdfTextSearcher(controller)
      ..addListener(_handleTextSearchChanged);
    if (_hasSearchQuery) {
      _textSearcher!.startTextSearch(
        _searchController.text.trim(),
        searchImmediately: true,
      );
    }
  }

  void _disposeTextSearcher() {
    _textSearcher?.removeListener(_handleTextSearchChanged);
    _textSearcher?.dispose();
    _textSearcher = null;
  }

  void _handleTextSearchChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _openSearch() {
    setState(() {
      _isSearchMode = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _searchFocusNode.requestFocus();
      _searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchController.text.length,
      );
    });
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    _searchController.clear();
    _textSearcher?.resetTextSearch();
    setState(() {
      _isSearchMode = false;
    });
  }

  void _handleSearchChanged(String value) {
    _textSearcher?.startTextSearch(value.trim());
    setState(() {});
  }

  void _handleSearchSubmitted(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      _textSearcher?.resetTextSearch();
      setState(() {});
      return;
    }

    final textSearcher = _textSearcher;
    if (textSearcher != null &&
        textSearcher.pattern == query &&
        textSearcher.hasMatches) {
      _goToNextMatch();
      return;
    }

    textSearcher?.startTextSearch(query, searchImmediately: true);
    setState(() {});
  }

  Future<void> _goToPreviousMatch() async {
    await _textSearcher?.goToPrevMatch();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _goToNextMatch() async {
    await _textSearcher?.goToNextMatch();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Widget _buildScrollThumb(
    BuildContext context,
    Size thumbSize,
    int? pageNumber,
    PdfViewerController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          pageNumber?.toString() ?? '-',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget? _buildControls(
    bool canGoToPreviousPage,
    Duration pageTransitionDuration,
    bool canGoToNextPage,
  ) {
    if (!widget.showControls) {
      return null;
    }
    return BottomAppBar(
      child: Row(
        children: [
          Flexible(
            child: Row(
              children: [
                IconButton.filled(
                  onPressed: canGoToPreviousPage
                      ? () async {
                          await _controller.goToPage(
                            pageNumber: _currentPage - 1,
                            duration: pageTransitionDuration,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_left),
                ),
                const SizedBox(width: 16),
                IconButton.filled(
                  onPressed: canGoToNextPage
                      ? () async {
                          await _controller.goToPage(
                            pageNumber: _currentPage + 1,
                            duration: pageTransitionDuration,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_right),
                ),
              ],
            ),
          ),
          Text(
            _totalPages == null ? '-/-' : '$_currentPage/$_totalPages',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
