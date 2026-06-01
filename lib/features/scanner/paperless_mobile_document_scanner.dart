import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paperless_mobile/features/scanner/constants/constants.dart';
import 'package:paperless_mobile/features/scanner/models/auto_capture_config.dart';
import 'package:paperless_mobile/features/scanner/models/debug_stage.dart';
import 'package:paperless_mobile/features/scanner/models/document_frame.dart';
import 'package:paperless_mobile/features/scanner/models/scan_result.dart';
import 'package:paperless_mobile/features/scanner/models/transient_scan_result.dart';
import 'package:paperless_mobile/features/scanner/processing/detect_edges_from_file.dart';
import 'package:paperless_mobile/features/scanner/processing/image_edit.dart';
import 'package:paperless_mobile/features/scanner/view/document_scanner_view.dart';
import 'package:paperless_mobile/features/scanner/view/image_edit_view.dart';
import 'package:paperless_mobile/features/scanner/view/widgets/debug_stage_switcher.dart';
import 'package:paperless_mobile/features/scanner/view/widgets/resolution_switcher.dart';
import 'package:paperless_mobile/features/scanner/view/widgets/scanner_control_tray.dart';
import 'package:paperless_mobile/features/scanner/view/widgets/scan_preview_list.dart';
import 'package:paperless_mobile/features/scanner/view/widgets/shutter_button.dart';
import 'package:paperless_mobile/features/scanner/view/pages/advanced_scanner_settings_page.dart';
import 'package:paperless_mobile/core/store/bloc/global_settings_builder.dart';
import 'package:paperless_mobile/core/store/slices/global_settings.dart';
import 'package:paperless_mobile/features/scanner/models/scanner_parameters.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;

enum _ScanPhase { liveDetection, processing, imageEditing }

const _shutterButtonSize = 72.0;
const _scanPreviewListHeight = 110.0;
const _actionButtonRowHeight = 56.0;

final ImagePicker picker = ImagePicker();

class _PreparedStillImage {
  final Uint8List bytes;
  final Size imageSize;
  final String filePath;

  const _PreparedStillImage({
    required this.bytes,
    required this.imageSize,
    required this.filePath,
  });
}

class PaperlessMobileDocumentScanner extends StatefulWidget {
  /// Called when the user finishes the scan session.
  /// Receives all accepted scans as persisted page models.
  final Future<void> Function(List<ScanResult> value) onCancelled;
  final ValueChanged<List<ScanResult>> onDone;

  /// Called when the user cancels the scan session.
  final bool liveDetectionInitiallyEnabled;
  final ResolutionPreset resolutionPreset;

  /// App-owned directory used for original captures/imports and edited scans.
  final Directory directory;

  /// App-owned persisted page state used to restore an existing document.
  final List<ScanResult> initialScans;

  /// Configuration for auto-capture behaviour. When enabled, the scanner
  /// automatically takes a picture once the detected frame is stable.
  final AutoCaptureConfig autoCaptureConfig;

  const PaperlessMobileDocumentScanner({
    super.key,
    this.liveDetectionInitiallyEnabled = true,
    this.resolutionPreset = ResolutionPreset.max,
    required this.directory,
    this.initialScans = const [],
    this.autoCaptureConfig = const AutoCaptureConfig(
      enabled: true,
      preStableDelay: Duration(milliseconds: 300),
      stableDuration: Duration(milliseconds: 500),
      minConsecutiveSimilarFrames: 4,
    ),
    required this.onCancelled,
    required this.onDone,
  });

  @override
  State<PaperlessMobileDocumentScanner> createState() =>
      _PaperlessMobileDocumentScannerState();
}

class _PaperlessMobileDocumentScannerState
    extends State<PaperlessMobileDocumentScanner> {
  late bool _liveDetectionEnabled;
  late bool _autoCaptureEnabled;
  CameraController? _controller;
  DebugStage _debugStage = DebugStage.none;
  bool _isTorchActive = false;
  bool _handlingSystemBack = false;
  bool _isSettingsOpen = false;

  void _setController(CameraController? controller) {
    if (controller != _controller) {
      _controller = controller;
      _isTorchActive = false;
    }
  }

  _ScanPhase _phase = _ScanPhase.liveDetection;
  Future<List<CameraDescription>>? _availableCameras;
  DocumentFrame? _lastLiveFrame;
  Size? _lastLiveImageSize;

  /// Set when auto-capture fires, providing a high-confidence fallback frame.
  DocumentFrame? _autoCaptureFallbackFrame;
  Size? _autoCaptureFallbackImageSize;

  // --- State for a new capture (used until the user confirms or discards). ---
  Uint8List? _capturedImageBytes;
  Size? _capturedImageSize;
  DocumentFrame? _capturedFrame;
  String? _capturedFilePath;
  Uint8List? _initialCroppedBytes;

  // --- Re-edit state ---
  /// Index into [_scans] when re-editing an existing scan, or `null` for a
  /// fresh capture.
  int? _editingIndex;

  // Accumulated scan results.
  final List<TransientScanResult> _scans = [];

  // -----------------------------------------------------------------------
  // Capture flow
  // -----------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _liveDetectionEnabled = true;
    _autoCaptureEnabled = widget.autoCaptureConfig.enabled;
    _availableCameras = availableCameras();
    unawaited(_restoreInitialScans());
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  void _setAutoCaptureEnabled(bool enabled) {
    setState(() {
      _autoCaptureEnabled = enabled;
    });
  }

  @override
  void dispose() {
    // Null out the reference to the CameraController so that any in-flight
    // async work (_onShutterPressed) will bail out on the mounted check
    // rather than using a disposed controller.
    _controller = null;
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  Future<void> _onGalleryImportPressed() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null || !mounted) return;

      _setController(null);
      setState(() => _phase = _ScanPhase.processing);

      await _startStillImageEditing(
        await pickedFile.readAsBytes(),
        sourceFileName: p.basename(pickedFile.path),
      );
    } catch (e) {
      debugPrint('Gallery import failed: $e');
      if (mounted) _returnToLiveDetection();
    }
  }

  Future<void> _onShutterPressed() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      // Capture the image BEFORE switching phase, because changing phase
      // removes the camera view from the tree and disposes the controller.
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      final xFile = await controller.takePicture();

      if (!mounted) {
        File(xFile.path).delete().catchError((_) => File(xFile.path));
        return;
      }
      _setController(null);
      setState(() => _phase = _ScanPhase.processing);

      final bytes = await xFile.readAsBytes();

      await _startStillImageEditing(
        bytes,
        sourceFileName: p.basename(xFile.path),
        sourceCleanupPath: xFile.path,
        plausibilityFallbackFrame: _autoCaptureFallbackFrame,
        plausibilityFallbackImageSize: _autoCaptureFallbackImageSize,
        coordinateFallbackFrame: _autoCaptureFallbackFrame ?? _lastLiveFrame,
        coordinateFallbackImageSize: _autoCaptureFallbackFrame != null
            ? _autoCaptureFallbackImageSize
            : _lastLiveImageSize,
      );
    } catch (e) {
      debugPrint('Capture/crop failed: $e');
      if (mounted) _returnToLiveDetection();
    }
  }

  Future<void> _startStillImageEditing(
    Uint8List sourceBytes, {
    String? sourceFileName,
    String? sourceCleanupPath,
    DocumentFrame? plausibilityFallbackFrame,
    Size? plausibilityFallbackImageSize,
    DocumentFrame? coordinateFallbackFrame,
    Size? coordinateFallbackImageSize,
  }) async {
    _PreparedStillImage? preparedImage;

    try {
      preparedImage = await _prepareStillImage(
        sourceBytes,
        sourceFileName: sourceFileName,
      );

      if (sourceCleanupPath != null &&
          sourceCleanupPath != preparedImage.filePath) {
        File(
          sourceCleanupPath,
        ).delete().catchError((_) => File(sourceCleanupPath));
      }

      final frame = await _resolveInitialFrame(
        imageBytes: preparedImage.bytes,
        imageSize: preparedImage.imageSize,
        plausibilityFallbackFrame: plausibilityFallbackFrame,
        plausibilityFallbackImageSize: plausibilityFallbackImageSize,
        coordinateFallbackFrame: coordinateFallbackFrame,
        coordinateFallbackImageSize: coordinateFallbackImageSize,
      );

      _autoCaptureFallbackFrame = null;
      _autoCaptureFallbackImageSize = null;

      if (!mounted) {
        final preparedFilePath = preparedImage.filePath;
        File(
          preparedImage.filePath,
        ).delete().catchError((_) => File(preparedFilePath));
        return;
      }

      setState(() {
        _capturedImageBytes = preparedImage!.bytes;
        _capturedImageSize = preparedImage.imageSize;
        _capturedFrame = frame;
        _capturedFilePath = preparedImage.filePath;
        _initialCroppedBytes = null;
        _editingIndex = null;
        _phase = _ScanPhase.imageEditing;
      });
    } catch (_) {
      if (preparedImage != null) {
        final preparedFilePath = preparedImage.filePath;
        File(
          preparedImage.filePath,
        ).delete().catchError((_) => File(preparedFilePath));
      }
      rethrow;
    }
  }

  Future<_PreparedStillImage> _prepareStillImage(
    Uint8List sourceBytes, {
    String? sourceFileName,
  }) async {
    final decoded = await decodeImageFromList(sourceBytes);

    try {
      final fileName = _newScanFileName(
        extension: _normalizedImageExtension(sourceFileName),
      );
      final imageFile = await _writeImageFile(
        sourceBytes,
        directory: await _originalDirectory(),
        fileName: fileName,
      );

      return _PreparedStillImage(
        bytes: sourceBytes,
        imageSize: Size(decoded.width.toDouble(), decoded.height.toDouble()),
        filePath: imageFile.path,
      );
    } finally {
      decoded.dispose();
    }
  }

  Future<DocumentFrame> _resolveInitialFrame({
    required Uint8List imageBytes,
    required Size imageSize,
    DocumentFrame? plausibilityFallbackFrame,
    Size? plausibilityFallbackImageSize,
    DocumentFrame? coordinateFallbackFrame,
    Size? coordinateFallbackImageSize,
  }) async {
    var detectedFrame = await detectEdgesFromImageBytes(imageBytes);

    if (detectedFrame != null &&
        plausibilityFallbackFrame != null &&
        plausibilityFallbackImageSize != null &&
        !plausibilityFallbackFrame.isPlausibleMatch(
          detectedFrame,
          thisImageSize: plausibilityFallbackImageSize,
          candidateImageSize: imageSize,
        )) {
      debugPrint(
        'Accurate detection diverged from stable frame — using fallback.',
      );
      detectedFrame = null;
    }

    if (detectedFrame != null) {
      return detectedFrame;
    }

    if (coordinateFallbackFrame != null &&
        coordinateFallbackImageSize != null) {
      return coordinateFallbackFrame.scale(
        imageSize.width / coordinateFallbackImageSize.width,
        imageSize.height / coordinateFallbackImageSize.height,
      );
    }

    return DocumentFrame(
      topLeft: Offset.zero,
      topRight: Offset(imageSize.width, 0),
      bottomRight: Offset(imageSize.width, imageSize.height),
      bottomLeft: Offset(0, imageSize.height),
    );
  }

  Future<void> _onImageEditConfirmed(ImageEditResult result) async {
    // Generate a lightweight thumbnail for the preview list.
    final thumbnail = await generateThumbnail(result.editedBytes);

    if (_editingIndex != null) {
      // Re-edit: update the existing scan in place.
      final existing = _scans[_editingIndex!];
      await existing.outputFile.writeAsBytes(result.editedBytes, flush: true);
      existing.cropFrame = result.cropFrame;
      existing.quarterTurns = result.quarterTurns;
      existing.colorFilter = result.colorFilter;
      existing.bwThreshold = result.bwThreshold;
      existing.enhanced = result.enhanced;
      existing.thumbnailBytes = thumbnail;
    } else {
      // New scan: write the output file and create a transient scan.
      final scanFile = await _writeEditedScanFile(
        result.editedBytes,
        sourceFileName: p.basename(_capturedFilePath!),
      );
      _scans.add(
        TransientScanResult(
          originalFile: File(_capturedFilePath!),
          outputFile: scanFile,
          thumbnailBytes: thumbnail,
          scanResult: ScanResult(
            originalFileName: p.basename(_capturedFilePath!),
            editedFileName: p.basename(scanFile.path),
            originalImageSize: _capturedImageSize!,
            cropFrame: result.cropFrame,
            quarterTurns: result.quarterTurns,
            colorFilter: result.colorFilter,
            bwThreshold: result.bwThreshold,
            enhanced: result.enhanced,
          ),
        ),
      );
    }

    _editingIndex = null;
    _returnToLiveDetection();
  }

  void _onImageEditCancelled() {
    if (_editingIndex == null) {
      // New capture discarded — delete the original capture file.
      _deleteOriginalCapture();
    }
    _editingIndex = null;
    _returnToLiveDetection();
  }

  void _onScanTapped(int index) {
    _setController(null);
    setState(() {
      _editingIndex = index;
      _phase = _ScanPhase.imageEditing;
    });
  }

  void _onScanDeleted(int index) async {
    final scan = _scans.removeAt(index);
    scan.outputFile.delete().catchError((_) => scan.outputFile);
    scan.originalFile.delete().catchError((_) => scan.originalFile);
    setState(() {});
  }

  void _onScanReordered(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final scan = _scans.removeAt(oldIndex);
      _scans.insert(newIndex, scan);
    });
  }

  void _returnToLiveDetection() {
    setState(() {
      _phase = _ScanPhase.liveDetection;
      _capturedImageBytes = null;
      _capturedImageSize = null;
      _capturedFrame = null;
      _initialCroppedBytes = null;
      _capturedFilePath = null;
    });
  }

  void _deleteOriginalCapture() {
    if (_capturedFilePath != null) {
      File(_capturedFilePath!).delete().catchError((_) => File(''));
      _capturedFilePath = null;
    }
  }

  Future<Directory> _originalDirectory() {
    return Directory(
      p.join(widget.directory.path, 'original'),
    ).create(recursive: true);
  }

  Future<Directory> _editedDirectory() {
    return Directory(
      p.join(widget.directory.path, 'edited'),
    ).create(recursive: true);
  }

  Future<File> _writeImageFile(
    Uint8List bytes, {
    required Directory directory,
    required String fileName,
  }) async {
    final file = File(p.join(directory.path, fileName));
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<File> _writeEditedScanFile(
    Uint8List bytes, {
    required String sourceFileName,
  }) async {
    return _writeImageFile(
      bytes,
      directory: await _editedDirectory(),
      fileName: '${p.basenameWithoutExtension(sourceFileName)}.png',
    );
  }

  Future<void> _restoreInitialScans() async {
    try {
      final scans = await _loadInitialScans(widget.initialScans);
      if (!mounted || scans.isEmpty) {
        return;
      }

      setState(() {
        _scans
          ..clear()
          ..addAll(scans);
      });
    } catch (e) {
      debugPrint('Failed to restore persisted scans: $e');
    }
  }

  Future<List<TransientScanResult>> _loadInitialScans(
    List<ScanResult> persistedScans,
  ) async {
    final scans = <TransientScanResult>[];
    final originalDirectory = await _originalDirectory();
    final editedDirectory = await _editedDirectory();
    for (final storedScan in persistedScans) {
      final originalFile = storedScan.originalFile(originalDirectory);
      final outputFile = storedScan.editedFile(editedDirectory);
      if (!await originalFile.exists() || !await outputFile.exists()) {
        continue;
      }

      final outputBytes = await outputFile.readAsBytes();
      final originalImageSize = await _resolveOriginalImageSize(
        storedScan,
        originalFile,
      );
      final resolvedScan = storedScan.copyWith(
        originalImageSize: originalImageSize,
        cropFrame: _resolveCropFrame(storedScan, originalImageSize),
      );
      scans.add(
        TransientScanResult(
          originalFile: originalFile,
          outputFile: outputFile,
          thumbnailBytes: await generateThumbnail(outputBytes),
          scanResult: resolvedScan,
        ),
      );
    }

    return scans;
  }

  Future<Size> _resolveOriginalImageSize(
    ScanResult persistedScan,
    File originalFile,
  ) async {
    if (persistedScan.originalImageWidth > 0 &&
        persistedScan.originalImageHeight > 0) {
      return persistedScan.originalImageSize;
    }

    final decoded = await decodeImageFromList(await originalFile.readAsBytes());
    try {
      return Size(decoded.width.toDouble(), decoded.height.toDouble());
    } finally {
      decoded.dispose();
    }
  }

  DocumentFrame _resolveCropFrame(
    ScanResult persistedScan,
    Size originalImageSize,
  ) {
    if (_isZeroFrame(persistedScan.cropFrame)) {
      return DocumentFrame(
        topLeft: Offset.zero,
        topRight: Offset(originalImageSize.width, 0),
        bottomRight: Offset(originalImageSize.width, originalImageSize.height),
        bottomLeft: Offset(0, originalImageSize.height),
      );
    }
    return persistedScan.cropFrame;
  }

  bool _isZeroFrame(DocumentFrame frame) {
    return frame.topLeft == Offset.zero &&
        frame.topRight == Offset.zero &&
        frame.bottomRight == Offset.zero &&
        frame.bottomLeft == Offset.zero;
  }

  String _newScanFileName({String extension = '.jpg'}) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'scan_$timestamp$extension';
  }

  String _normalizedImageExtension(String? sourceFileName) {
    final extension = p.extension(sourceFileName ?? '').toLowerCase();
    if (extension == '.jpg' ||
        extension == '.jpeg' ||
        extension == '.png' ||
        extension == '.webp') {
      return extension;
    }
    return '.jpg';
  }

  List<ScanResult> get _scanResults {
    return [for (final scan in _scans) scan.scanResult];
  }

  void _onFrameChanged(DocumentFrame? frame, Size? imageSize) {
    // Keep a reference to the last detected frame for the capture fallback.
    _lastLiveFrame = frame;
    _lastLiveImageSize = imageSize;
  }

  Future<void> _handleSystemBack() async {
    if (_handlingSystemBack) {
      return;
    }

    _handlingSystemBack = true;
    try {
      switch (_phase) {
        case _ScanPhase.imageEditing:
          _onImageEditCancelled();
          break;
        case _ScanPhase.liveDetection:
        case _ScanPhase.processing:
          await widget.onCancelled(_scanResults);
          break;
      }
    } finally {
      _handlingSystemBack = false;
    }
  }

  Widget _wrapWithBackHandler(Widget child) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(_handleSystemBack());
        }
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _ScanPhase.processing => _wrapWithBackHandler(
        const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      _ScanPhase.imageEditing => _buildImageEditing(),
      _ScanPhase.liveDetection => _wrapWithBackHandler(_buildLiveDetection()),
    };
  }

  Widget _buildImageEditing() {
    final scan = _editingIndex != null ? _scans[_editingIndex!] : null;

    if (scan != null) {
      // Re-edit: load from file on demand.
      return ImageEditView(
        originalImageFile: scan.originalFile,
        originalImageSize: scan.originalImageSize,
        initialCropFrame: scan.cropFrame,
        initialQuarterTurns: scan.quarterTurns,
        initialColorFilter: scan.colorFilter,
        initialBwThreshold: scan.bwThreshold,
        initialEnhanced: scan.enhanced,
        onConfirmed: _onImageEditConfirmed,
        onCancelled: _onImageEditCancelled,
        isNewCapture: false,
      );
    }

    // New capture: bytes already in memory.
    return ImageEditView(
      originalImageBytes: _capturedImageBytes!,
      originalImageSize: _capturedImageSize!,
      initialCropFrame: _capturedFrame!,
      initialCroppedBytes: _initialCroppedBytes,
      animateEntry: true,
      onConfirmed: _onImageEditConfirmed,
      onCancelled: _onImageEditCancelled,
      isNewCapture: true,
    );
  }

  Widget _buildLiveDetection() {
    final bottomViewPadding = MediaQuery.of(context).viewPadding.bottom;
    return GlobalSettingsBuilder(
      builder: (context, globalSettings) {
        final params = globalSettings.scannerParameters;
        final edgeDetectionConfig = params.toEdgeDetectionConfig();
        final autoCaptureConfig = params.toAutoCaptureConfig(
          enabled: _autoCaptureEnabled,
        );
        final resolutionPreset = params.resolutionPresetValue;

        return FutureBuilder<List<CameraDescription>>(
          future: _availableCameras,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              if (error is CameraException) {
                final message = mapCameraErrorCode(error.code);
                return Center(child: Text('$message: ${error.description}'));
              }
              return const Center(child: Text('Error loading cameras'));
            }
            final cameras = snapshot.data!;
            if (cameras.isEmpty) {
              return const Center(child: Text('No cameras found'));
            }
            final camera = cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
              orElse: () => cameras.first,
            );
            const bottomBarVerticalPadding = 8.0;
            final bottomBarHeight =
                _shutterButtonSize +
                _actionButtonRowHeight +
                (_scans.isNotEmpty ? _scanPreviewListHeight : 0) +
                2 *
                    bottomBarVerticalPadding // x2 since it's applied both above and below the shutter row
                    +
                bottomViewPadding;
            return Scaffold(
              bottomNavigationBar: BottomAppBar(
                height: bottomBarHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shutter + torch row.
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: bottomBarVerticalPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _onGalleryImportPressed,
                            icon: const Icon(
                              Icons.add_photo_alternate,
                              size: 32,
                            ),
                          ),
                          ShutterButton(
                            onPressed: _onShutterPressed,
                            size: _shutterButtonSize,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildTorchButton(),
                          ),
                        ],
                      ),
                    ),
                    // Cancel / Done buttons.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        height: _actionButtonRowHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => widget.onCancelled(_scanResults),
                              child: Text(S.of(context)!.cancel),
                            ),
                            if (_scans.isNotEmpty)
                              FilledButton.icon(
                                onPressed: () {
                                  widget.onDone(_scanResults);
                                },
                                icon: const Icon(Icons.done_all),
                                label: Text(
                                  '${S.of(context)!.done} (${_scans.length})',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Scan preview list.
                    if (_scans.isNotEmpty)
                      ScanPreviewList(
                        scans: _scans,
                        onDelete: _onScanDeleted,
                        onTap: _onScanTapped,
                        onReorder: _onScanReordered,
                        height: _scanPreviewListHeight,
                      ),
                  ],
                ),
              ),
              body: Stack(
                children: [
                  // Camera preview with live edge detection.
                  DocumentScannerView(
                    key: ValueKey(resolutionPreset),
                    onControllerInitialized: _setController,
                    camera: camera,
                    debugStage: kDebugMode ? _debugStage : DebugStage.none,
                    resolutionPreset: resolutionPreset,
                    onFrameChanged: _onFrameChanged,
                    liveEdgeDetectionEnabled:
                        _liveDetectionEnabled && !_isSettingsOpen,
                    autoCaptureConfig: autoCaptureConfig,
                    edgeDetectionConfig: edgeDetectionConfig,
                    onAutoCaptureTriggered: (stableFrame) {
                      _autoCaptureFallbackFrame = stableFrame;
                      _autoCaptureFallbackImageSize = _lastLiveImageSize;
                      _onShutterPressed();
                    },
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: RepaintBoundary(
                          child: ScannerControlTray(
                            autoCaptureEnabled: _autoCaptureEnabled,
                            onAutoCaptureChanged: _setAutoCaptureEnabled,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildTopRightControls(context, resolutionPreset),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopRightControls(
    BuildContext context,
    ResolutionPreset resolutionPreset,
  ) {
    return Positioned(
      top: 16,
      right: 16,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton.filledTonal(
              onPressed: () async {
                setState(() => _isSettingsOpen = true);
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdvancedScannerSettingsPage(),
                  ),
                );
                if (mounted) {
                  setState(() => _isSettingsOpen = false);
                }
              },
              icon: const Icon(Icons.tune),
              tooltip: 'Advanced Scanner Settings',
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              DebugStageSwitcher(
                value: _debugStage,
                onChanged: (stage) => setState(() => _debugStage = stage),
              ),
              const SizedBox(height: 12),
              ResolutionSwitcher(
                value: resolutionPreset,
                onChanged: (preset) {
                  context.localStore.updateGlobalSettings(
                    (state) => state.copyWith(
                      scannerParameters: state.scannerParameters.copyWith(
                        resolutionPreset: preset.name,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTorchButton() {
    return IconButton.filledTonal(
      onPressed: () async {
        final controller = _controller;
        if (controller == null || !controller.value.isInitialized) return;
        final wantTorch = !_isTorchActive;
        await controller.setFlashMode(
          wantTorch ? FlashMode.torch : FlashMode.off,
        );
        setState(() => _isTorchActive = wantTorch);
      },
      icon: Icon(
        _isTorchActive ? Icons.flashlight_off : Icons.flashlight_on,
        size: 32,
      ),
    );
  }
}
