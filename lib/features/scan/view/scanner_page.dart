import 'dart:io';
import 'dart:math';

import 'package:edge_detection/edge_detection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/bloc/label_bloc_provider.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/home/view/widget/info_drawer.dart';
import 'package:paperless_mobile/features/scan/bloc/document_scanner_cubit.dart';
import 'package:paperless_mobile/features/scan/view/document_upload_page.dart';
import 'package:paperless_mobile/features/scan/view/widgets/grid_image_item_widget.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  late final AnimationController _fabPulsingController;
  late final Animation _animation;
  @override
  void initState() {
    super.initState();
    _fabPulsingController = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _animation = Tween(begin: 1.0, end: 1.2).animate(_fabPulsingController)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _fabPulsingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const InfoDrawer(),
      floatingActionButton: BlocBuilder<DocumentScannerCubit, List<File>>(
        builder: (context, state) {
          final fab = FloatingActionButton(
            onPressed: () => _openDocumentScanner(context),
            child: const Icon(Icons.add_a_photo_outlined),
          );
          if (state.isEmpty) {
            return Transform.scale(
              child: fab,
              scale: _animation.value,
            );
          }
          return fab;
        },
      ),
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).documentScannerPageTitle),
      actions: [
        BlocBuilder<DocumentScannerCubit, List<File>>(
          builder: (context, state) {
            return IconButton(
              onPressed: state.isEmpty ? null : () => _reset(context),
              icon: const Icon(Icons.delete_sweep),
              tooltip: S.of(context).documentScannerPageResetButtonTooltipText,
            );
          },
        ),
        BlocBuilder<DocumentScannerCubit, List<File>>(
          builder: (context, state) {
            return IconButton(
              onPressed: state.isEmpty ? null : () => _export(context),
              icon: const Icon(Icons.done),
              tooltip: S.of(context).documentScannerPageUploadButtonTooltip,
            );
          },
        ),
      ],
    );
  }

  void _openDocumentScanner(BuildContext context) async {
    await _requestCameraPermissions();
    final imagePath = await EdgeDetection.detectEdge;
    if (imagePath == null) {
      return;
    }
    final file = File(imagePath);
    BlocProvider.of<DocumentScannerCubit>(context).addScan(file);
  }

  void _export(BuildContext context) async {
    final pw.Document doc = pw.Document();

    for (var element in BlocProvider.of<DocumentScannerCubit>(context).state) {
      final img = pw.MemoryImage(element.readAsBytesSync());
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(img.width!.toDouble(), img.height!.toDouble()),
          build: (context) => pw.Image(img),
        ),
      );
    }
    final bytes = await doc.save();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: getIt<DocumentsCubit>(),
          child: LabelBlocProvider(
            child: DocumentUploadPage(
              pdfBytes: bytes,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<DocumentScannerCubit, List<File>>(
      builder: (context, scans) {
        if (scans.isNotEmpty) {
          return _buildImageGrid(scans);
        }
        return Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              S.of(context).documentScannerPageEmptyStateText,
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageGrid(List<File> scans) {
    return GridView.builder(
        itemCount: scans.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1 / sqrt(2),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          return GridImageItemWidget(
            file: scans[index],
            onDelete: () => BlocProvider.of<DocumentScannerCubit>(context).removeScan(index),
            index: index,
            totalNumberOfFiles: scans.length,
          );
        });
  }

  void _reset(BuildContext context) {
    BlocProvider.of<DocumentScannerCubit>(context).reset();
  }

  Future<void> _requestCameraPermissions() async {
    final hasPermission = await Permission.camera.isGranted;
    if (!hasPermission) {
      Permission.camera.request();
    }
  }
}
