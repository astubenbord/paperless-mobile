import 'dart:async';

import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/api/extensions/cached_query_extensions.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/features/documents/view/pages/viewers/image_document_viewer.dart';
import 'package:paperless_mobile/features/documents/view/pages/viewers/pdf_document_viewer.dart';
import 'package:paperless_mobile/features/documents/view/pages/viewers/text_document_viewer.dart';
import 'package:paperless_mobile/features/documents/view/pages/viewers/unsupported_document_viewer.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

// Re-export for backward compatibility with existing LoadedPdfView usages.
export 'package:paperless_mobile/features/documents/view/pages/viewers/pdf_document_viewer.dart'
    show PdfDocumentPageView;

/// MIME types supported by the in-app document viewer.
const _pdfMimeTypes = {'application/pdf'};

const _imageMimeTypes = {
  'image/png',
  'image/jpeg',
  'image/gif',
  'image/tiff',
  'image/bmp',
  'image/webp',
};

const _textMimeTypes = {
  'text/plain',
  'text/csv',
  'text/html',
  'text/xml',
  'text/markdown',
  'text/yaml',
  'application/json',
  'application/xml',
  'application/x-yaml',
  'application/yaml',
};

/// Determines whether the given [mimeType] can be previewed in-app.
bool canPreviewMimeType(String? mimeType) {
  if (mimeType == null) return false;
  return _pdfMimeTypes.contains(mimeType) ||
      _imageMimeTypes.contains(mimeType) ||
      _textMimeTypes.contains(mimeType);
}

/// Attempts to infer the MIME type from the leading bytes (magic numbers)
/// of [data]. Returns `null` if the format is not recognized.
String? _inferMimeType(Uint8List data) {
  if (data.length < 4) return null;

  // PDF: starts with "%PDF"
  if (data[0] == 0x25 &&
      data[1] == 0x50 &&
      data[2] == 0x44 &&
      data[3] == 0x46) {
    return 'application/pdf';
  }

  // PNG: starts with 0x89 "PNG"
  if (data[0] == 0x89 &&
      data[1] == 0x50 &&
      data[2] == 0x4E &&
      data[3] == 0x47) {
    return 'image/png';
  }

  // JPEG: starts with 0xFF 0xD8 0xFF
  if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) {
    return 'image/jpeg';
  }

  // GIF: starts with "GIF8"
  if (data[0] == 0x47 &&
      data[1] == 0x49 &&
      data[2] == 0x46 &&
      data[3] == 0x38) {
    return 'image/gif';
  }

  // BMP: starts with "BM"
  if (data[0] == 0x42 && data[1] == 0x4D) {
    return 'image/bmp';
  }

  // WebP: starts with "RIFF" ... "WEBP"
  if (data.length >= 12 &&
      data[0] == 0x52 &&
      data[1] == 0x49 &&
      data[2] == 0x46 &&
      data[3] == 0x46 &&
      data[8] == 0x57 &&
      data[9] == 0x45 &&
      data[10] == 0x42 &&
      data[11] == 0x50) {
    return 'image/webp';
  }

  // TIFF: starts with "II" (little-endian) or "MM" (big-endian)
  if ((data[0] == 0x49 && data[1] == 0x49) ||
      (data[0] == 0x4D && data[1] == 0x4D)) {
    return 'image/tiff';
  }

  // Heuristic: if the first 512 bytes are valid UTF-8 text, treat as plain text.
  if (_looksLikeText(data)) {
    return 'text/plain';
  }

  return null;
}

/// Returns `true` if the first bytes of [data] look like UTF-8 encoded text
/// (no null bytes and predominantly printable / whitespace characters).
bool _looksLikeText(Uint8List data) {
  final sampleSize = data.length < 512 ? data.length : 512;
  for (int i = 0; i < sampleSize; i++) {
    final byte = data[i];
    // Null byte is a strong indicator of binary content.
    if (byte == 0x00) return false;
  }
  return true;
}

/// A document viewer that selects the appropriate viewer widget based on
/// the document's MIME type.
///
/// Supports PDF, common image formats (PNG, JPEG, GIF, TIFF, BMP, WebP),
/// and plain text files. Falls back to an unsupported-type placeholder
/// for unknown MIME types.
///
/// Provide either [documentId] (to fetch via the repository) or [bytes]
/// (for already-available data such as scanned documents).
///
/// When using [bytes], a [mimeType] should be provided so the correct viewer
/// is selected. If omitted, the MIME type is inferred from the file's magic
/// bytes at runtime.
class DocumentView extends StatelessWidget {
  final int? documentId;
  final Future<Uint8List>? bytes;
  final String? title;
  final bool showAppBar;
  final bool showControls;

  /// The MIME type of the document. Used to select the appropriate viewer.
  ///
  /// When [documentId] is provided, the MIME type is resolved from the
  /// document metadata automatically. When [bytes] is provided directly,
  /// this should be set explicitly. If omitted the viewer will attempt to
  /// infer the type from the file's magic bytes.
  final String? mimeType;

  const DocumentView({
    super.key,
    this.documentId,
    this.bytes,
    this.showAppBar = true,
    this.showControls = true,
    this.title,
    this.mimeType,
  }) : assert(documentId != null || bytes != null);

  @override
  Widget build(BuildContext context) {
    if (documentId != null) {
      return QueryBuilder(
        query: context.documentRepository.downloadDocumentQuery(
          documentId!,
          original: true,
        ),
        builder: (context, state) {
          if (state.isLoadingInitial) {
            return _buildLoadingState();
          }
          if (state.isError) {
            return Center(
              child: Text(S.of(context)!.couldNotLoadDocumentPreview),
            );
          }

          return _buildViewer(state.data!);
        },
      );
    }

    return FutureBuilder(
      future: bytes,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingState();
        }
        return _buildViewer(snapshot.data!);
      },
    );
  }

  /// Selects and builds the appropriate viewer widget for the given [data]
  /// based on the current [mimeType], or infers the type from magic bytes.
  Widget _buildViewer(Uint8List data) {
    final resolvedMimeType = mimeType ?? _inferMimeType(data);

    if (_pdfMimeTypes.contains(resolvedMimeType)) {
      return PdfDocumentViewer(
        bytes: data,
        title: title,
        showAppBar: showAppBar,
        showControls: showControls,
      );
    }

    if (_imageMimeTypes.contains(resolvedMimeType)) {
      return ImageDocumentViewer(
        bytes: data,
        title: title,
        showAppBar: showAppBar,
      );
    }

    if (_textMimeTypes.contains(resolvedMimeType)) {
      return TextDocumentViewer(
        bytes: data,
        title: title,
        showAppBar: showAppBar,
      );
    }

    return UnsupportedDocumentViewer(
      mimeType: resolvedMimeType ?? 'unknown',
      title: title,
      showAppBar: showAppBar,
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator());
  }
}
