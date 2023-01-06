import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/bloc/paperless_server_information_cubit.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/features/document_upload/cubit/document_upload_cubit.dart';
import 'package:paperless_mobile/features/document_upload/view/document_upload_preparation_page.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/view/pages/documents_page.dart';
import 'package:paperless_mobile/features/home/view/widget/bottom_navigation_bar.dart';
import 'package:paperless_mobile/features/home/view/widget/info_drawer.dart';
import 'package:paperless_mobile/features/labels/view/pages/labels_page.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
import 'package:paperless_mobile/features/scan/bloc/document_scanner_cubit.dart';
import 'package:paperless_mobile/features/scan/view/scanner_page.dart';
import 'package:paperless_mobile/features/sharing/share_intent_queue.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final DocumentScannerCubit _scannerCubit = DocumentScannerCubit();

  @override
  void initState() {
    super.initState();
    _initializeData(context);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _listenForReceivedFiles();
    });
  }

  void _listenForReceivedFiles() async {
    if (ShareIntentQueue.instance.hasUnhandledFiles) {
      Fluttertoast.showToast(msg: "Sync: Has unhandled files!");
      await _handleReceivedFile(ShareIntentQueue.instance.pop()!);
      Fluttertoast.showToast(msg: "Sync: File handled!");
    }
    ShareIntentQueue.instance.addListener(() async {
      final queue = ShareIntentQueue.instance;
      while (queue.hasUnhandledFiles) {
        Fluttertoast.showToast(msg: "Async: Has unhandled files!");
        final file = queue.pop()!;
        await _handleReceivedFile(file);
        Fluttertoast.showToast(msg: "Async: File handled!");
      }
    });
  }

  bool _isFileTypeSupported(SharedMediaFile file) {
    return supportedFileExtensions.contains(
      file.path.split('.').last.toLowerCase(),
    );
  }

  Future<void> _handleReceivedFile(SharedMediaFile file) async {
    final isGranted = await askForPermission(Permission.storage);

    if (!isGranted) {
      return;
    }
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("Received File."),
              content: Column(
                children: [
                  Text("Path: ${file.path}"),
                  Text("Type: ${file.type.name}"),
                  Text("Exists: ${File(file.path).existsSync()}"),
                  FutureBuilder<bool>(
                    future: Permission.storage.isGranted,
                    builder: (context, snapshot) =>
                        Text("Has storage permission: ${snapshot.data}"),
                  )
                ],
              ),
            ));
    SharedMediaFile mediaFile;
    if (Platform.isIOS) {
      // Workaround for file not found on iOS: https://stackoverflow.com/a/72813212
      mediaFile = SharedMediaFile(
        file.path.replaceAll('file://', ''),
        file.thumbnail,
        file.duration,
        file.type,
      );
    } else {
      mediaFile = file;
    }

    if (!_isFileTypeSupported(mediaFile)) {
      Fluttertoast.showToast(
        msg: translateError(context, ErrorCode.unsupportedFileFormat),
      );
      if (Platform.isAndroid) {
        // As stated in the docs, SystemNavigator.pop() is ignored on IOS to comply with HCI guidelines.
        await SystemNavigator.pop();
      }
      return;
    }
    final filename = extractFilenameFromPath(mediaFile.path);

    try {
      if (File(mediaFile.path).existsSync()) {
        final bytes = File(mediaFile.path).readAsBytesSync();
        final success = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: DocumentUploadCubit(
                    localVault: context.read(),
                    documentApi: context.read(),
                    tagRepository: context.read(),
                    correspondentRepository: context.read(),
                    documentTypeRepository: context.read(),
                  ),
                  child: DocumentUploadPreparationPage(
                    fileBytes: bytes,
                    filename: filename,
                  ),
                ),
              ),
            ) ??
            false;
        if (success) {
          await Fluttertoast.showToast(
            msg: S.of(context).documentUploadSuccessText,
          );
          SystemNavigator.pop();
        }
      }
    } catch (e, stackTrace) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Column(
            children: [
              Text(
                e.toString(),
              ),
              Text(stackTrace.toString()),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, ConnectivityState>(
      //Only re-initialize data if the connectivity changed from not connected to connected
      listenWhen: (previous, current) => current == ConnectivityState.connected,
      listener: (context, state) {
        _initializeData(context);
      },
      child: Scaffold(
        key: rootScaffoldKey,
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _currentIndex,
          onNavigationChanged: (index) {
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
            }
          },
        ),
        drawer: const InfoDrawer(),
        body: [
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => DocumentsCubit(
                  context.read<PaperlessDocumentsApi>(),
                ),
              ),
              BlocProvider(
                create: (context) => SavedViewCubit(
                  context.read<SavedViewRepository>(),
                ),
              ),
            ],
            child: const DocumentsPage(),
          ),
          BlocProvider.value(
            value: _scannerCubit,
            child: const ScannerPage(),
          ),
          const LabelsPage(),
        ][_currentIndex],
      ),
    );
  }

  void _initializeData(BuildContext context) {
    try {
      context.read<LabelRepository<Tag>>().findAll();
      context.read<LabelRepository<Correspondent>>().findAll();
      context.read<LabelRepository<DocumentType>>().findAll();
      context.read<LabelRepository<StoragePath>>().findAll();
      context.read<SavedViewRepository>().findAll();
      context.read<PaperlessServerInformationCubit>().updateInformtion();
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
