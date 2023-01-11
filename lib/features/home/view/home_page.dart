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
import 'package:paperless_mobile/core/repository/state/impl/correspondent_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/document_type_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/storage_path_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/tag_repository_state.dart';
import 'package:paperless_mobile/features/document_upload/cubit/document_upload_cubit.dart';
import 'package:paperless_mobile/features/document_upload/view/document_upload_preparation_page.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/view/pages/documents_page.dart';
import 'package:paperless_mobile/features/home/view/widget/bottom_navigation_bar.dart';
import 'package:paperless_mobile/features/home/view/widget/info_drawer.dart';
import 'package:paperless_mobile/features/labels/view/pages/labels_page.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
import 'package:paperless_mobile/features/scan/bloc/document_scanner_cubit.dart';
import 'package:paperless_mobile/features/scan/view/scanner_page.dart';
import 'package:paperless_mobile/features/sharing/share_intent_queue.dart';
import 'package:paperless_mobile/features/tasks/cubit/task_status_cubit.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:path/path.dart' as p;

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
      await _handleReceivedFile(ShareIntentQueue.instance.pop()!);
    }
    ShareIntentQueue.instance.addListener(() async {
      final queue = ShareIntentQueue.instance;
      while (queue.hasUnhandledFiles) {
        final file = queue.pop()!;
        await _handleReceivedFile(file);
      }
    });
  }

  bool _isFileTypeSupported(SharedMediaFile file) {
    return supportedFileExtensions.contains(
      file.path.split('.').last.toLowerCase(),
    );
  }

  Future<void> _handleReceivedFile(SharedMediaFile file) async {
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
    final extension = p.extension(mediaFile.path);
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
                    title: filename,
                    fileExtension: extension,
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
      } else {
        Fluttertoast.showToast(
          msg: S.of(context).receiveSharedFilePermissionDeniedMessage,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e, stackTrace) {
      Fluttertoast.showToast(
        msg: S.of(context).receiveSharedFilePermissionDeniedMessage,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ConnectivityCubit, ConnectivityState>(
          //Only re-initialize data if the connectivity changed from not connected to connected
          listenWhen: (previous, current) =>
              current == ConnectivityState.connected,
          listener: (context, state) {
            _initializeData(context);
          },
        ),
        BlocListener<TaskStatusCubit, TaskStatusState>(
          listener: (context, state) {
            if (state.task != null) {
              // Handle local notifications on task change (only when app is running for now).
              context
                  .read<LocalNotificationService>()
                  .notifyTaskChanged(state.task!);
            }
          },
        ),
      ],
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
                  context.read<SavedViewRepository>(),
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
      context.read<LabelRepository<Tag, TagRepositoryState>>().findAll();
      context
          .read<LabelRepository<Correspondent, CorrespondentRepositoryState>>()
          .findAll();
      context
          .read<LabelRepository<DocumentType, DocumentTypeRepositoryState>>()
          .findAll();
      context
          .read<LabelRepository<StoragePath, StoragePathRepositoryState>>()
          .findAll();
      context.read<SavedViewRepository>().findAll();
      context.read<PaperlessServerInformationCubit>().updateInformtion();
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
