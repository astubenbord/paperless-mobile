import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/hive/hive_extensions.dart';
import 'package:paperless_mobile/core/database/tables/local_user_app_state.dart';
import 'package:paperless_mobile/core/factory/paperless_api_factory.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/core/repository/user_repository.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';
import 'package:paperless_mobile/core/service/dio_file_service.dart';
import 'package:paperless_mobile/features/document_scan/cubit/document_scanner_cubit.dart';
import 'package:paperless_mobile/features/documents/cubit/documents_cubit.dart';
import 'package:paperless_mobile/features/home/view/model/api_version.dart';
import 'package:paperless_mobile/features/inbox/cubit/inbox_cubit.dart';
import 'package:paperless_mobile/features/labels/cubit/label_cubit.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
import 'package:paperless_mobile/core/widgets/global_settings_builder.dart';
import 'package:paperless_mobile/features/tasks/model/pending_tasks_notifier.dart';
import 'package:provider/provider.dart';

class HomeShellWidget extends StatelessWidget {
  /// The id of the currently authenticated user (e.g. demo@paperless.example.com)
  final String localUserId;

  /// The Paperless API version of the currently connected instance
  final int paperlessApiVersion;

  // A factory providing the API implementations given an API version
  final PaperlessApiFactory paperlessProviderFactory;

  final Widget child;

  const HomeShellWidget({
    super.key,
    required this.paperlessApiVersion,
    required this.paperlessProviderFactory,
    required this.localUserId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GlobalSettingsBuilder(
      builder: (context, settings) {
        final currentUserId = settings.loggedInUserId;
        final apiVersion = ApiVersion(paperlessApiVersion);
        return ValueListenableBuilder(
          valueListenable:
              Hive.localUserAccountBox.listenable(keys: [currentUserId]),
          builder: (context, box, _) {
            if (currentUserId == null) {
              //This only happens during logout...
              //FIXME: Find way so this does not occur anymore
              return const SizedBox.shrink();
            }
            final currentLocalUser = box.get(currentUserId);
            if (currentLocalUser == null) {
              return const SizedBox.shrink();
            }
            return MultiProvider(
              key: ValueKey(currentUserId),
              providers: [
                Provider.value(value: currentLocalUser),
                Provider.value(value: apiVersion),
                Provider(
                  create: (context) => CacheManager(
                    Config(
                      // Isolated cache per user.
                      localUserId,
                      fileService:
                          DioFileService(context.read<SessionManager>().client),
                    ),
                  ),
                ),
                Provider(
                  create: (context) =>
                      paperlessProviderFactory.createDocumentsApi(
                    context.read<SessionManager>().client,
                    apiVersion: paperlessApiVersion,
                  ),
                ),
                Provider(
                  create: (context) => paperlessProviderFactory.createLabelsApi(
                    context.read<SessionManager>().client,
                    apiVersion: paperlessApiVersion,
                  ),
                ),
                Provider(
                  create: (context) =>
                      paperlessProviderFactory.createSavedViewsApi(
                    context.read<SessionManager>().client,
                    apiVersion: paperlessApiVersion,
                  ),
                ),
                Provider(
                  create: (context) =>
                      paperlessProviderFactory.createServerStatsApi(
                    context.read<SessionManager>().client,
                    apiVersion: paperlessApiVersion,
                  ),
                ),
                Provider(
                  create: (context) => paperlessProviderFactory.createTasksApi(
                    context.read<SessionManager>().client,
                    apiVersion: paperlessApiVersion,
                  ),
                ),
                Provider(
                  create: (context) =>
                      paperlessProviderFactory.createCustomFieldsApi(
                    context.read<SessionManager>().client,
                  ),
                ),
                Provider(
                  create: (context) =>
                      paperlessProviderFactory.createShareLinksApi(
                    context.read<SessionManager>().client,
                  ),
                ),
                if (currentLocalUser.hasMultiUserSupport)
                  Provider(
                    create: (context) => paperlessProviderFactory.createUserApi(
                      context.read<SessionManager>().client,
                      apiVersion: paperlessApiVersion,
                    ),
                  ),
              ],
              builder: (context, _) {
                return MultiProvider(
                  providers: [
                    ChangeNotifierProvider(
                      create: (context) {
                        return LabelRepository(context.read())
                          ..initialize(
                            loadCorrespondents: currentLocalUser
                                .paperlessUser.canViewCorrespondents,
                            loadDocumentTypes: currentLocalUser
                                .paperlessUser.canViewDocumentTypes,
                            loadStoragePaths: currentLocalUser
                                .paperlessUser.canViewStoragePaths,
                            loadTags:
                                currentLocalUser.paperlessUser.canViewTags,
                          );
                      },
                    ),
                    ChangeNotifierProvider(
                      create: (context) {
                        final repo = SavedViewRepository(context.read());
                        if (currentLocalUser.paperlessUser.canViewSavedViews) {
                          repo.initialize();
                        }
                        return repo;
                      },
                    ),
                    if (currentLocalUser.hasMultiUserSupport)
                      Provider(
                        create: (context) => UserRepository(
                          context.read(),
                        )..initialize(),
                      ),
                  ],
                  builder: (context, _) {
                    return MultiProvider(
                      providers: [
                        Provider(
                          lazy: false,
                          create: (context) => DocumentsCubit(
                            context.read(),
                            context.read(),
                            Hive.box<LocalUserAppState>(
                                    HiveBoxes.localUserAppState)
                                .get(currentUserId)!,
                            context.read(),
                          )..initialize(),
                        ),
                        Provider(
                          create: (context) =>
                              DocumentScannerCubit(context.read())
                                ..initialize(),
                        ),
                        Provider(
                          create: (context) {
                            final inboxCubit = InboxCubit(
                              context.read(),
                              context.read(),
                              context.read(),
                              context.read(),
                              context.read(),
                            );
                            if (currentLocalUser.paperlessUser.canViewInbox) {
                              inboxCubit.initialize();
                            }
                            return inboxCubit;
                          },
                        ),
                        Provider(
                          create: (context) => SavedViewCubit(
                            context.read(),
                          ),
                        ),
                        Provider(
                          create: (context) => LabelCubit(
                            context.read(),
                          ),
                        ),
                        ChangeNotifierProvider(
                          create: (context) => PendingTasksNotifier(
                            context.read(),
                          ),
                        ),
                      ],
                      child: child,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
