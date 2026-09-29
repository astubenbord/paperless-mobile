import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/features/home/view/home_shell_widget.dart';
import 'package:paperless_mobile/features/sharing/cubit/receive_share_cubit.dart';
import 'package:paperless_mobile/features/sharing/view/widgets/event_listener_shell.dart';
import 'package:paperless_mobile/routing/navigation_keys.dart';
import 'package:paperless_mobile/routing/routes.dart';
import 'package:paperless_mobile/routing/routes/custom_field_route.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';
import 'package:paperless_mobile/routing/routes/inbox_route.dart';
import 'package:paperless_mobile/routing/routes/labels_route.dart';
import 'package:paperless_mobile/routing/routes/landing_route.dart';
import 'package:paperless_mobile/routing/routes/saved_views_route.dart';
import 'package:paperless_mobile/routing/routes/scanner_route.dart';
import 'package:paperless_mobile/routing/routes/settings_route.dart';
import 'package:paperless_mobile/routing/routes/shells/scaffold_shell_route.dart';
import 'package:paperless_mobile/routing/routes/upload_queue_route.dart';
import 'package:provider/provider.dart';

/// Key used to access

part 'authenticated_route.g.dart';

@TypedShellRoute<AuthenticatedRoute>(
  routes: [
    TypedGoRoute<SettingsRoute>(
      path: "/settings",
      name: R.settings,
      routes: [
        TypedGoRoute<SearchIndexingRoute>(
          path: "indexing",
          name: R.searchIndexing,
        ),
      ],
    ),
    TypedGoRoute<UploadQueueRoute>(path: "/upload-queue", name: R.uploadQueue),
    TypedGoRoute<SavedViewsRoute>(
      path: "/saved-views",
      routes: [
        TypedGoRoute<CreateSavedViewRoute>(
          path: "create",
          name: R.createSavedView,
        ),
        TypedGoRoute<EditSavedViewRoute>(path: "edit", name: R.editSavedView),
      ],
    ),
    TypedStatefulShellRoute<ScaffoldShellRoute>(
      branches: [
        TypedStatefulShellBranch<LandingBranch>(
          routes: [
            TypedGoRoute<LandingRoute>(path: "/landing", name: R.landing),
          ],
        ),
        TypedStatefulShellBranch<DocumentsBranch>(
          routes: [
            TypedGoRoute<DocumentsRoute>(
              path: "/documents",
              routes: [
                TypedGoRoute<DocumentDetailsRoute>(
                  path: ":documentId",
                  name: R.documentDetails,
                  routes: [
                    TypedGoRoute<EditDocumentRoute>(
                      path: "edit",
                      name: R.editDocument,
                    ),
                    TypedGoRoute<DocumentPreviewRoute>(
                      path: 'preview',
                      name: R.documentPreview,
                    ),
                  ],
                ),
              ],
            ),
            TypedGoRoute<BulkEditDocumentsRoute>(
              path: "/bulk-edit",
              name: R.bulkEditDocuments,
            ),
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
                TypedGoRoute<EditLabelRoute>(path: "edit", name: R.editLabel),
                TypedGoRoute<CreateLabelRoute>(
                  path: "create",
                  name: R.createLabel,
                ),
                TypedGoRoute<LinkedDocumentsRoute>(
                  path: "linked-documents",
                  name: R.linkedDocuments,
                ),
                TypedGoRoute<CreateCustomFieldRoute>(
                  path: "create-custom-field",
                  name: R.createCustomField,
                ),
                TypedGoRoute<EditCustomFieldRoute>(
                  path: "edit-custom-field",
                  name: R.editCustomField,
                ),
              ],
            ),
          ],
        ),
        TypedStatefulShellBranch<InboxBranch>(
          routes: [TypedGoRoute<InboxRoute>(path: "/inbox", name: R.inbox)],
        ),
      ],
    ),
  ],
)
class AuthenticatedRoute extends ShellRouteData {
  static final GlobalKey<NavigatorState> $navigatorKey = outerShellNavigatorKey;

  const AuthenticatedRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    final loggedInUser = context.loggedInUserData$;
    final appUserId = '${loggedInUser.username}@${loggedInUser.serverUrl}';

    return HomeShellWidget(
      appUserId: appUserId,
      child: ChangeNotifierProvider(
        create: (context) =>
            ConsumptionChangeNotifier()
              ..loadFromConsumptionDirectory(userId: appUserId),
        child: EventListenerShell(child: navigator),
      ),
    );
  }
}
