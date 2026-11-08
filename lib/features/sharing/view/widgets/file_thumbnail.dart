import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart' as mime;
import 'package:printing/printing.dart';
import 'package:transparent_image/transparent_image.dart';

class FileThumbnail extends StatefulWidget {
  final File? file;
  final Uint8List? bytes;

  final BoxFit? fit;
  final double? width;
  final double? height;
  const FileThumbnail({
    super.key,
    this.file,
    this.bytes,
    this.fit,
    this.width,
    this.height,
  }) : assert((bytes != null) != (file != null));

  @override
  State<FileThumbnail> createState() => _FileThumbnailState();
}

class _FileThumbnailState extends State<FileThumbnail> {
  late String? mimeType;
  late final Future<Uint8List?> _fileBytes;
  @override
  void initState() {
    super.initState();
    mimeType = widget.file != null
        ? mime.lookupMimeType(widget.file!.path)
        : mime.lookupMimeType('', headerBytes: widget.bytes);
    _fileBytes =
        widget.file?.readAsBytes().then(_convertPdfToPng) ??
        _convertPdfToPng(widget.bytes!);
  }

  @override
  Widget build(BuildContext context) {
    return switch (mimeType) {
      "application/pdf" => SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: FutureBuilder<Uint8List?>(
            future: _fileBytes,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              return ColoredBox(
                color: Colors.white,
                child: Image.memory(
                  snapshot.data!,
                  alignment: Alignment.topCenter,
                  fit: widget.fit,
                  width: widget.width,
                  height: widget.height,
                ),
              );
            },
          ),
        ),
      ),
      "image/png" ||
      "image/jpeg" ||
      "image/tiff" ||
      "image/gif" ||
      "image/webp" =>
        widget.file != null
            ? Image.file(
                widget.file!,
                fit: widget.fit,
                width: widget.width,
                height: widget.height,
              )
            : Image.memory(
                widget.bytes!,
                fit: widget.fit,
                width: widget.width,
                height: widget.height,
              ),
      "text/plain" => const Center(child: Text(".txt")),
      _ => const Icon(Icons.file_present_outlined),
    };
  }

  // send pdfFile as params
  Future<Uint8List?> _convertPdfToPng(Uint8List bytes) async {
    final info = await Printing.info();
    if (!info.canRaster) {
      return kTransparentImage;
    }
    final raster = await Printing.raster(bytes, pages: [0], dpi: 72).first;
    return raster.toPng();
  }
}
