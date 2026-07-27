import 'dart:io';

/// Common interface for document scanner engines.
///
/// Each implementation launches a scanner UI and returns a list of JPEG files
/// written to the app's temporary scan directory.
/// Returns an empty list when the user cancels or no image is captured.
abstract class DocumentScannerEngine {
  Future<List<File>> scan();
}
