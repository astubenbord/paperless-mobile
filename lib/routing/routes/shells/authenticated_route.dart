import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/accessibility/accessible_page.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/factory/paperless_api_factory.dart';
import 'package:paperless_mobile/features/home/view/home_shell_widget.dart';
import 'package:paperless_mobile/features/sharing/cubit/receive_share_cubit.dart';
import 'package:paperless_mobile/features/sharing/view/widgets/event_listener_shell.dart';
import 'package:paperless_mobile/routing/navigation_keys.dart';
import 'package:paperless_mobile/routing/routes.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';
import 'package:paperless_mobile/routing/routes/inbox_route.dart';
import 'package:paperless_mobile/routing/routes/labels_route.dart';
import 'package:paperless_mobile/routing/routes/landing_route.dart';
import 'package:paperless_mobile/routing/routes/saved_views_route.dart';
import 'package:paperless_mobile/routing/routes/scanner_route.dart';
import 'package:paperless_mobile/routing/routes/upload_queue_route.dart';
import 'package:paperless_mobile/routing/routes/shells/scaffold_shell_route.dart';
import 'package:paperless_mobile/routing/routes/settings_route.dart';
import 'package:provider/provider.dart';

/// Key used to access

part 'authenticated_route.g.dart';

@TypedShellRoute<AuthenticatedRoute>(
  routes: [
    TypedGoRoute<SettingsRoute>(
      path: "/settings",
      name: R.settings,
    ),
    TypedGoRoute<UploadQueueRoute>(
      path: "/upload-queue",
      name: R.uploadQueue,
    ),
    TypedGoRoute<SavedViewsRoute>(
      path: "/saved-views",
      routes: [
        TypedGoRoute<CreateSavedViewRoute>(
          path: "create",
          name: R.createSavedView,
        ),
        TypedGoRoute<EditSavedViewRoute>(
          path: "edit",
          name: R.editSavedView,
        ),
      ],
    ),
    TypedStatefulShellRoute<ScaffoldShellRoute>(
      branches: [
        TypedStatefulShellBranch<LandingBranch>(
          routes: [
            TypedGoRoute<LandingRoute>(
              path: "/landing",
              name: R.landing,
            )
          ],
        ),
        TypedStatefulShellBranch<DocumentsBranch>(
          routes: [
            TypedGoRoute<DocumentsRoute>(
              path: "/documents",
              routes: [
                TypedGoRoute<DocumentDetailsRoute>(
                  path: "details/:id",
                  name: R.documentDetails,
                  routes: [],
                ),
                TypedGoRoute<EditDocumentRoute>(
                  path: "edit",
                  name: R.editDocument,
                ),
                TypedGoRoute<BulkEditDocumentsRoute>(
                  path: "bulk-edit",
                  name: R.bulkEditDocuments,
                ),
                TypedGoRoute<DocumentPreviewRoute>(
                  path: 'preview',
                  name: R.documentPreview,
                ),
              ],
            )
          ],
        ),
        TypedStatefulShellBranch<ScannerBranch>(
          routes: [
            TypedGoRoute<ScannerRoute>(
              path: "/scanner",
              name: R.scanner,
              routes: [
                TypedGoRoute<DocumentUploadRoute>(
                  path: "upload",
                  name: R.uploadDocument,
                ),
              ],
            ),
          ],
        ),
        TypedStatefulShellBranch<LabelsBranch>(
          routes: [
            TypedGoRoute<LabelsRoute>(
              path: "/labels",
              name: R.labels,
              routes: [
                TypedGoRoute<EditLabelRoute>(
                  path: "edit",
                  name: R.editLabel,
                ),
                TypedGoRoute<CreateLabelRoute>(
                  path: "create",
                  name: R.createLabel,
                ),
                TypedGoRoute<LinkedDocumentsRoute>(
                  path: "linked-documents",
                  name: R.linkedDocuments,
                ),
              ],
            ),
          ],
        ),
        TypedStatefulShellBranch<InboxBranch>(
          routes: [
            TypedGoRoute<InboxRoute>(
              path: "/inbox",
              name: R.inbox,
            )
          ],
        ),
      ],
    ),
  ],
)
class AuthenticatedRoute extends ShellRouteData {
  static final GlobalKey<NavigatorState> $navigatorKey = outerShellNavigatorKey;

  const AuthenticatedRoute();

  @override
  Page<void> pageBuilder(
    BuildContext context,
    GoRouterState state,
    Widget navigator,
  ) {
    return accessiblePlatformPage(
      child: Builder(
        builder: (context) {
          final globalSettings =
              Hive.box<GlobalSettings>(HiveBoxes.globalSettings)
                  .getValue();
          final currentUserId = globalSettings?.loggedInUserId;
          if (currentUserId == null) {
            return const SizedBox.shrink();
          }
          final authenticatedUser =
              Hive.box<LocalUserAccount>(HiveBoxes.localUserAccount).get(
            currentUserId,
          );
          if (authenticatedUser == null) {
            return const SizedBox.shrink();
          }
          final apiFactory = context.read<PaperlessApiFactory>();
          return HomeShellWidget(
            localUserId: authenticatedUser.id,
            paperlessApiVersion: authenticatedUser.apiVersion,
            paperlessProviderFactory: apiFactory,
            child: ChangeNotifierProvider(
              create: (context) => ConsumptionChangeNotifier()
                ..loadFromConsumptionDirectory(userId: currentUserId),
              child: EventListenerShell(
                child: navigator,
              ),
            ),
          );
        },
      ),
    );
  }
}
