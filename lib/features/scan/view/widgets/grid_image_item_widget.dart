import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

typedef DeleteCallback = void Function();
typedef OnImageOperation = void Function(File);

class GridImageItemWidget extends StatefulWidget {
  final File file;
  final DeleteCallback onDelete;
  //final OnImageOperation onImageOperation;

  final int index;
  final int totalNumberOfFiles;

  const GridImageItemWidget({
    Key? key,
    required this.file,
    required this.onDelete,
    required this.index,
    required this.totalNumberOfFiles,
    //required this.onImageOperation,
  }) : super(key: key);

  @override
  State<GridImageItemWidget> createState() => _GridImageItemWidgetState();
}

class _GridImageItemWidgetState extends State<GridImageItemWidget> {
  bool isProcessing = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImage(context),
      child: _buildImageItem(context),
    );
  }

  Card _buildImageItem(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Stack(
          children: [
            Align(alignment: Alignment.bottomCenter, child: _buildNumbering()),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.close),
              ),
            ),
            isProcessing
                ? _buildIsProcessing()
                : Align(
                    alignment: Alignment.center,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.file(
                        widget.file,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Center _buildIsProcessing() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          Text(
            "Processing transformation...",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: _buildNumbering(prefix: "Image"),
          ),
          body: PhotoView(imageProvider: FileImage(widget.file)),
        ),
      ),
    );
  }

  Widget _buildNumbering({String? prefix}) {
    return Text(
      "${prefix ?? ""} ${widget.index + 1}/${widget.totalNumberOfFiles}",
    );
  }
}
