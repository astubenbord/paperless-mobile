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
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_cancel_button.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_confirm_button.dart';
import 'package:paperless_mobile/features/document_upload/model/document_upload_queue.dart';
import 'package:paperless_mobile/features/document_upload/service/document_upload_queue_coordinator.dart';
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
      if (!mounted) return;
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
      if (!mounted) return;
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
  await consumeLocalFiles(
    context,
    files: [file],
    userId: userId,
    exitAppAfterConsumed: exitAppAfterConsumed,
  );
}

Future<void> consumeLocalFiles(
  BuildContext context, {
  required List<File> files,
  required String userId,
  bool exitAppAfterConsumed = false,
}) async {
  if (files.isEmpty) {
    return;
  }

  final hasInternetConnection = await context
      .read<ConnectivityStatusService>()
      .isConnectedToInternet();
  if (!context.mounted) {
    return;
  }
  if (!hasInternetConnection) {
    if (context.mounted) {
      final message = files.length == 1
          ? 'Could not consume ${p.basename(files.first.path)}' //TODO: INTL
          : 'Could not consume shared files'; //TODO: INTL
      showSnackBar(context, message, details: S.of(context)!.youreOffline);
    }
    return;
  }

  final shouldDirectlyUpload =
      context.localStore.state.globalSettings.skipDocumentPreprarationOnUpload;

  await DocumentUploadQueueCoordinator.processQueue<File>(
    context,
    items: [
      for (final file in files)
        DocumentUploadQueueItem(
          source: file,
          loadFileBytes: file.readAsBytes,
          filename: p.basenameWithoutExtension(file.path),
          title: p.basenameWithoutExtension(file.path),
          fileExtension: p.extension(file.path),
          instantUpload: shouldDirectlyUpload,
        ),
    ],
    delegate: _SharedFileUploadQueueDelegate(
      userId: userId,
      exitAppAfterConsumed: exitAppAfterConsumed,
    ),
  );
}

class _SharedFileUploadQueueDelegate
    implements DocumentUploadQueueDelegate<File> {
  final String userId;
  final bool exitAppAfterConsumed;

  const _SharedFileUploadQueueDelegate({
    required this.userId,
    required this.exitAppAfterConsumed,
  });

  @override
  Future<void> onQueueCompleted(BuildContext context) async {
    if (exitAppAfterConsumed) {
      SystemNavigator.pop();
    }
  }

  @override
  Future<void> onItemUploaded(
    BuildContext context,
    DocumentUploadQueueItem<File> item,
    DocumentUploadResult result,
  ) async {
    if (context.mounted) {
      await Fluttertoast.showToast(
        msg: S.of(context)!.documentSuccessfullyUploadedProcessing,
      );
    }
    if (!context.mounted) {
      return;
    }
    await context.read<ConsumptionChangeNotifier>().discardFile(
      item.source,
      userId: userId,
    );
  }

  @override
  Future<DocumentUploadQueueCancellationDisposition> onQueueCancelled(
    BuildContext context,
    List<DocumentUploadQueueItem<File>> remainingItems,
  ) async {
    if (remainingItems.isEmpty) {
      return DocumentUploadQueueCancellationDisposition.keepRemaining;
    }

    if (remainingItems.length == 1) {
      final shouldDiscard =
          await showDialog<bool>(
            useRootNavigator: false,
            context: context,
            builder: (context) => DiscardSharedFileDialog(
              bytes: remainingItems.first.loadFileBytes(),
            ),
          ) ??
          false;
      return shouldDiscard
          ? DocumentUploadQueueCancellationDisposition.discardRemaining
          : DocumentUploadQueueCancellationDisposition.keepRemaining;
    }

    final shouldDiscardRemaining =
        await showDialog<bool>(
          useRootNavigator: false,
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard remaining shared files?'),
            content: Text(
              'The remaining ${remainingItems.length} shared file(s) can either stay pending or be discarded.',
            ),
            actions: [
              const DialogCancelButton(),
              DialogConfirmButton(
                returnValue: true,
                label: S.of(context)!.discard,
                style: DialogConfirmButtonStyle.danger,
              ),
            ],
          ),
        ) ??
        false;

    return shouldDiscardRemaining
        ? DocumentUploadQueueCancellationDisposition.discardRemaining
        : DocumentUploadQueueCancellationDisposition.keepRemaining;
  }

  @override
  Future<void> discardRemainingItems(
    BuildContext context,
    List<DocumentUploadQueueItem<File>> remainingItems,
  ) async {
    final notifier = context.read<ConsumptionChangeNotifier>();
    for (final item in remainingItems) {
      await notifier.discardFile(item.source, userId: userId);
    }
  }
}
