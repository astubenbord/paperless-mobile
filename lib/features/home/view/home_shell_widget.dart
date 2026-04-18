import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:paperless_mobile/api/extensions/cached_query_extensions.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/correspondent_repository.dart';
import 'package:paperless_mobile/core/repository/custom_field_repository.dart';
import 'package:paperless_mobile/core/repository/document_repository.dart';
import 'package:paperless_mobile/core/repository/document_type_repository.dart';
import 'package:paperless_mobile/core/repository/inbox_repository.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/core/repository/search_repository.dart';
import 'package:paperless_mobile/core/repository/server_statistics_repository.dart';
import 'package:paperless_mobile/core/repository/storage_path_repository.dart';
import 'package:paperless_mobile/core/repository/tag_repository.dart';
import 'package:paperless_mobile/core/repository/user_profile_repository.dart';
import 'package:paperless_mobile/core/repository/user_repository.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';
import 'package:paperless_mobile/core/service/dio_file_service.dart';
import 'package:paperless_mobile/core/store/local_store.dart';
import 'package:paperless_mobile/core/store/slices/local_user_account.dart';
import 'package:paperless_mobile/features/document_scan/cubit/document_scanner_cubit.dart';
import 'package:paperless_mobile/features/login/view/widgets/login_transition_page.dart';
import 'package:paperless_mobile/features/tasks/model/pending_tasks_notifier.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class HomeShellWidget extends StatelessWidget {
  /// The id of the currently authenticated user (e.g. demo@paperless.example.com)
  final String appUserId;

  /// The Paperless API version of the currently connected instance

  final Widget child;

  const HomeShellWidget({
    super.key,
    required this.appUserId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final localStoreState = context.watch<LocalStore>().state;
    final currentUserId = localStoreState.loggedInAppUserId;
    final client = context.read<SessionManager>().client;

    return MultiProvider(
      key: ValueKey(currentUserId),
      providers: [
        Provider(
          create: (context) => CacheManager(
            Config(
              // Isolated cache per user.
              appUserId,
              fileService: DioFileService(client),
            ),
          ),
        ),
        Provider<PaperlessDocumentsApi>(
          create: (context) => PaperlessDocumentsApiImpl(client),
        ),
        Provider<PaperlessSearchApi>(
          create: (context) => PaperlessSearchApiImpl(client),
        ),
        Provider<PaperlessCorrespondentsApi>(
          create: (context) => PaperlessCorrespondentsApiImpl(client),
        ),
        Provider<PaperlessDocumentTypesApi>(
          create: (context) => PaperlessDocumentTypesApiImpl(client),
        ),
        Provider<PaperlessTagsApi>(
          create: (context) => PaperlessTagsApiImpl(client),
        ),
        Provider<PaperlessStoragePathsApi>(
          create: (context) => PaperlessStoragePathsApiImpl(client),
        ),
        Provider<PaperlessSavedViewsApi>(
          create: (context) => PaperlessSavedViewsApiImpl(client),
        ),
        Provider<PaperlessCustomFieldsApi>(
          create: (context) => PaperlessCustomFieldsApiImpl(client),
        ),
        Provider<PaperlessServerStatsApi>(
          create: (context) => PaperlessServerStatsApiImpl(client),
        ),
        Provider<PaperlessTasksApi>(
          create: (context) => PaperlessTasksApiImpl(client),
        ),
        Provider<PaperlessUserApi>(
          create: (context) => PaperlessUserApiImpl(client),
        ),
      ],
      builder: (context, _) {
        return MultiProvider(
          providers: [
            Provider(create: (context) => DocumentRepository(context.read())),
            Provider(create: (context) => SearchRepository(context.read())),
            // For correspondent, document type, tag, storage path labels
            Provider(
              create: (context) => CorrespondentRepository(context.read()),
            ),
            Provider(
              create: (context) => DocumentTypeRepository(context.read()),
            ),
            Provider(create: (context) => TagRepository(context.read())),
            Provider(
              create: (context) => StoragePathRepository(context.read()),
            ),
            Provider(
              create: (context) =>
                  DocumentScannerCubit(context.read())..initialize(),
            ),
            Provider(create: (context) => UserRepository(context.read())),
            Provider(create: (context) => SavedViewRepository(context.read())),
            Provider(
              create: (context) => ServerStatisticsRepository(context.read()),
            ),
            Provider(
              create: (context) => CustomFieldsRepository(context.read()),
            ),
            Provider(
              create: (context) => InboxRepository(
                context.read(),
                context.read(),
                context.read(),
                context.read(),
              ),
              dispose: (_, repo) => repo.dispose(),
            ),
            Provider(
              create: (context) =>
                  SessionDataRepository(context.read(), context.read()),
            ),
            ChangeNotifierProvider(
              create: (context) => PendingTasksNotifier(context.read()),
            ),
          ],
          child: Builder(
            builder: (context) => QueryBuilder(
              query: context.read<SessionDataRepository>().userProfileQuery(
                appUserId,
              ),
              builder: (context, state) {
                if (state.isLoadingInitial) {
                  return LoginTransitionPage(
                    text: S.of(context)!.fetchingUserInformation,
                  );
                } else if (state.isError) {
                  return SizedBox.shrink(); // TODO: Show actual error
                }
                final sessionData = state.data!;
                final localUserAccount = LocalUserAccount(
                  appUserId: appUserId,
                  serverUrl: client.options.baseUrl,
                  apiVersion: sessionData.apiVersion,
                  profile: sessionData.profile,
                );
                return Provider.value(value: localUserAccount, child: child);
              },
            ),
          ),
        );
      },
    );
  }
}
