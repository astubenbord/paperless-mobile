import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_ce/hive.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/hive/hive_extensions.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/features/document_upload/view/document_upload_preparation_page.dart';
import 'package:paperless_mobile/features/inbox/cubit/inbox_cubit.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:paperless_mobile/features/sharing/cubit/receive_share_cubit.dart';
import 'package:paperless_mobile/features/sharing/view/dialog/discard_shared_file_dialog.dart';
import 'package:paperless_mobile/features/tasks/model/pending_tasks_notifier.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/core/util/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/scanner_route.dart';
import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class EventListenerShell extends StatefulWidget {
  final Widget child;
  const EventListenerShell({super.key, required this.child});

  @override
  State<EventListenerShell> createState() => _EventListenerShellState();
}

class _EventListenerShellState extends State<EventListenerShell>
    with WidgetsBindingObserver {
  StreamSubscription? _subscription;
  StreamSubscription? _documentDeletedSubscription;
  Timer? _inboxTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ReceiveSharingIntent.instance.getInitialMedia().then(_onReceiveSharedFiles);
    _subscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_onReceiveSharedFiles);
    context.read<PendingTasksNotifier>().addListener(_onTasksChanged);
    _documentDeletedSubscription =
        context.read<DocumentChangedNotifier>().$deleted.listen((event) {
      if (!mounted) return;
      showSnackBar(context, S.of(context)!.documentSuccessfullyDeleted);
    });
    _listenToInboxChanges();
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   final notifier = context.read<ConsumptionChangeNotifier>();
    //   await notifier.isInitialized;
    //   final pendingFiles = notifier.pendingFiles;
    //   if (pendingFiles.isEmpty) {
    //     return;
    //   }

    //   final shouldProcess = await showDialog<bool>(
    //         context: context,
    //         builder: (context) =>
    //             PendingFilesInfoDialog(pendingFiles: pendingFiles),
    //       ) ??
    //       false;
    //   if (shouldProcess) {
    //     final userId = context.read<LocalUserAccount>().id;
    //     await consumeLocalFiles(
    //       context,
    //       files: pendingFiles,
    //       userId: userId,
    //     );
    //   }
    // });
  }

  void _listenToInboxChanges() {
    final cubit = context.read<InboxCubit>();
    final currentUser = context.read<LocalUserAccount>();
    if (!currentUser.paperlessUser.canViewInbox || _inboxTimer != null) {
      return;
    }
    _inboxTimer = Timer.periodic(30.seconds, (_) {
      cubit.refreshItemsInInboxCount(false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _documentDeletedSubscription?.cancel();
    _inboxTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint(
          "App resumed, reloading connectivity and "
          "restarting periodic query for inbox changes...",
        );
        context.read<ConnectivityCubit>().reload();
        _listenToInboxChanges();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      default:
        _inboxTimer?.cancel();
        _inboxTimer = null;
        debugPrint(
          "App either paused or hidden, stopping "
          "periodic query for inbox changes.",
        );
        break;
    }
  }

  void _onTasksChanged() {
    final taskNotifier = context.read<PendingTasksNotifier>();
    final userId = context.read<LocalUserAccount>().id;
    for (var task in taskNotifier.value.values) {
      context
          .read<LocalNotificationService>()
          .notifyTaskChanged(task, userId: userId);
    }
  }

  void _onReceiveSharedFiles(List<SharedMediaFile> sharedFiles) async {
    final files = sharedFiles.map((file) => File(file.path)).toList();

    if (files.isNotEmpty) {
      try {
        final userId = context.read<LocalUserAccount>().id;
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
      } catch (e) {
        debugPrint('Failed to receive shared files: $e');
        if (mounted) {
          showSnackBar(context, 'Failed to process shared files.');
        }
      }
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
  final filename = p.basename(file.path);
  final hasInternetConnection =
      await context.read<ConnectivityStatusService>().isConnectedToInternet();
  if (!hasInternetConnection) {
    if (!context.mounted) return;
    showSnackBar(
      context,
      "Could not consume $filename", //TODO: INTL
      details: S.of(context)!.youreOffline,
    );
    return;
  }
  if (!context.mounted) return;
  final consumptionNotifier = context.read<ConsumptionChangeNotifier>();
  final taskNotifier = context.read<PendingTasksNotifier>();

  final bytes = await file.readAsBytes();
  final shouldDirectlyUpload =
      Hive.globalSettingsBox.getValue()!.skipDocumentPreprarationOnUpload;
  if (shouldDirectlyUpload) {
    try {
      final taskId = await context.read<PaperlessDocumentsApi>().create(
            bytes,
            filename: filename,
            title: p.basenameWithoutExtension(file.path),
          );
      await consumptionNotifier.discardFile(file, userId: userId);
      if (taskId != null) {
        taskNotifier.listenToTaskChanges(taskId);
      }
    } catch (error) {
      if (!context.mounted) return;
      await Fluttertoast.showToast(
        msg: S.of(context)!.couldNotUploadDocument,
      );
      return;
    } finally {
      if (exitAppAfterConsumed) {
        SystemNavigator.pop();
      }
    }
  } else {
    final result = await DocumentUploadRoute(
          $extra: Future.value(bytes),
          filename: p.basenameWithoutExtension(file.path),
          title: p.basenameWithoutExtension(file.path),
          fileExtension: p.extension(file.path),
        ).push<DocumentUploadResult>(context) ??
        DocumentUploadResult(false, null);

    if (result.success) {
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
      final shouldDiscard = await showDialog<bool>(
            context: context,
            builder: (context) => DiscardSharedFileDialog(bytes: Future.value(bytes)),
          ) ??
          false;
      if (shouldDiscard && context.mounted) {
        await context
            .read<ConsumptionChangeNotifier>()
            .discardFile(file, userId: userId);
      }
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
