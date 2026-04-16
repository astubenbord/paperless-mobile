import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:listen_sharing_intent/listen_sharing_intent.dart';
import 'package:paperless_mobile/constants.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/features/document_upload/view/document_upload_preparation_page.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:paperless_mobile/features/sharing/cubit/receive_share_cubit.dart';
import 'package:paperless_mobile/features/sharing/view/dialog/discard_shared_file_dialog.dart';
import 'package:paperless_mobile/features/sharing/view/dialog/pending_files_info_dialog.dart';
import 'package:paperless_mobile/features/tasks/model/pending_tasks_notifier.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/changelog_route.dart';
import 'package:paperless_mobile/routing/routes/scanner_route.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class EventListenerShell extends StatefulWidget {
  final Widget child;
  const EventListenerShell({super.key, required this.child});

  @override
  State<EventListenerShell> createState() => _EventListenerShellState();
}

class _EventListenerShellState extends State<EventListenerShell> {
  StreamSubscription? _subscription;
  StreamSubscription? _documentDeletedSubscription;
  Timer? _inboxTimer;

  @override
  void initState() {
    super.initState();
    ReceiveSharingIntent.instance.getInitialMedia().then((files) async {
      if (files.isEmpty) {
        final shouldShowChangelog = await _shouldShowChangelog;
        if (shouldShowChangelog && mounted) {
          ChangelogRoute().push(context);
        }
        return;
      }
      _onReceiveSharedFiles(files);
    });
    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _onReceiveSharedFiles,
    );
    context.read<PendingTasksNotifier>().addListener(_onTasksChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = context.loggedInUser.appUserId;
      final notifier = context.read<ConsumptionChangeNotifier>();
      await notifier.isInitialized;
      final pendingFiles = notifier.pendingFiles;
      if (pendingFiles.isEmpty) {
        return;
      }

      final shouldProcess =
          await showDialog<bool>(
            useRootNavigator: false,
            context: context,
            builder: (context) =>
                PendingFilesInfoDialog(pendingFiles: pendingFiles),
          ) ??
          false;
      if (shouldProcess) {
        await consumeLocalFiles(context, files: pendingFiles, userId: userId);
      }
    });
  }

  Future<bool> get _shouldShowChangelog async {
    try {
      final sp = await SharedPreferences.getInstance();
      final currentBuild = packageInfo.buildNumber;
      final existingVersions = sp.getStringList('changelogSeenForBuilds') ?? [];
      if (existingVersions.contains(currentBuild)) {
        return false;
      } else {
        existingVersions.add(currentBuild);
        await sp.setStringList('changelogSeenForBuilds', existingVersions);
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _documentDeletedSubscription?.cancel();
    _inboxTimer?.cancel();
    super.dispose();
  }

  void _onTasksChanged() {
    final taskNotifier = context.read<PendingTasksNotifier>();
    for (var task in taskNotifier.value.values) {
      context.read<LocalNotificationService>().notifyTaskChanged(
        task,
        userId: context.loggedInAppUserId!,
      );
    }
  }

  void _onReceiveSharedFiles(List<SharedMediaFile> sharedFiles) async {
    final files = sharedFiles.map((file) => File(file.path)).toList();
    final userId = context.loggedInAppUserId!;
    if (files.isNotEmpty) {
      logger.fi(
        'Received shared files: \n\t${sharedFiles.map((e) => e.path).join(',\n\t')}',
        className: runtimeType.toString(),
        methodName: '_onReceiveSharedFiles',
      );
      final notifier = context.read<ConsumptionChangeNotifier>();
      final addedLocalFiles = await notifier.addFiles(
        files: files,
        userId: userId,
      );
      if (!mounted) return;
      consumeLocalFiles(
        context,
        files: addedLocalFiles,
        userId: userId,
        exitAppAfterConsumed: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

Future<void> consumeLocalFile(
  BuildContext context, {
  required File file,
  required String userId,
  bool exitAppAfterConsumed = false,
}) async {
  final shouldDirectlyUpload =
      context.localStore.state.globalSettings.skipDocumentPreprarationOnUpload;
  final consumptionNotifier = context.read<ConsumptionChangeNotifier>();
  final filename = p.basename(file.path);
  final hasInternetConnection = await context
      .read<ConnectivityStatusService>()
      .isConnectedToInternet();
  if (!hasInternetConnection) {
    if (context.mounted) {
      showSnackBar(
        context,
        "Could not consume $filename", //TODO: INTL
        details: S.of(context)!.youreOffline,
      );
    }
    return;
  }

  final bytes = file.readAsBytes();
  // if () {
  //   try {
  //     final taskId = await documentsApi.create(
  //       await bytes,
  //       filename: filename,
  //       title: p.basenameWithoutExtension(file.path),
  //     );

  //     consumptionNotifier.discardFile(file, userId: userId);
  //     taskNotifier.listenToTaskChanges(taskId);
  //   } catch (error) {
  //     if (!context.mounted) return;
  //     await Fluttertoast.showToast(msg: S.of(context)!.couldNotUploadDocument);
  //     return;
  //   } finally {
  //     if (exitAppAfterConsumed) {
  //       SystemNavigator.pop();
  //     }
  //   }
  final result = await DocumentUploadRoute(
    $extra: bytes,
    filename: p.basenameWithoutExtension(file.path),
    title: p.basenameWithoutExtension(file.path),
    fileExtension: p.extension(file.path),
    instantUpload: shouldDirectlyUpload,
  ).push<DocumentUploadResult?>(context);

  if (result?.success ?? false) {
    if (context.mounted) {
      await Fluttertoast.showToast(
        msg: S.of(context)!.documentSuccessfullyUploadedProcessing,
      );
    }
    await consumptionNotifier.discardFile(file, userId: userId);

    // if (result.taskId != null) {
    //   taskNotifier.listenToTaskChanges(result.taskId!);
    // }
    if (exitAppAfterConsumed) {
      SystemNavigator.pop();
    }
  } else {
    if (!context.mounted) return;
    final shouldDiscard =
        await showDialog<bool>(
          useRootNavigator: false,
          context: context,
          builder: (context) => DiscardSharedFileDialog(bytes: bytes),
        ) ??
        false;
    if (shouldDiscard && context.mounted) {
      await context.read<ConsumptionChangeNotifier>().discardFile(
        file,
        userId: userId,
      );
    }
  }
}

Future<void> consumeLocalFiles(
  BuildContext context, {
  required List<File> files,
  required String userId,
  bool exitAppAfterConsumed = false,
}) async {
  for (int i = 0; i < files.length; i++) {
    final file = files[i];
    await consumeLocalFile(
      context,
      file: file,
      userId: userId,
      exitAppAfterConsumed: exitAppAfterConsumed && (i == files.length - 1),
    );
  }
}
