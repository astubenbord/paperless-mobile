import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/document_extensions.dart';
import 'package:paperless_mobile/core/extensions/label_list_extension.dart';
import 'package:paperless_mobile/core/repository/document_repository.dart';
import 'package:paperless_mobile/features/document_bulk_action/view/widgets/fullscreen_bulk_edit_label_page.dart';
import 'package:paperless_mobile/features/document_bulk_action/view/widgets/fullscreen_bulk_edit_tags_widget.dart';
import 'package:paperless_mobile/features/document_details/document_download/cubit/document_download_cubit.dart';
import 'package:paperless_mobile/features/document_details/document_open_in_system/cubit/document_open_in_system_cubit.dart';
import 'package:paperless_mobile/features/document_details/document_print/cubit/document_print_cubit.dart';
import 'package:paperless_mobile/features/document_details/document_share/cubit/document_share_cubit.dart';
import 'package:paperless_mobile/features/document_details/view/pages/document_details_page.dart';
import 'package:paperless_mobile/features/document_edit/view/document_edit_page.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_view.dart';
import 'package:paperless_mobile/features/documents/view/pages/documents_page.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/navigation_keys.dart';
import 'package:paperless_mobile/theme.dart';

import 'shells/authenticated_route.dart';

class DocumentsBranch extends StatefulShellBranchData {
  static final GlobalKey<NavigatorState> $navigatorKey = documentsNavigatorKey;
  const DocumentsBranch();
}

class DocumentsRoute extends GoRouteData with $DocumentsRoute {
  final DocumentFilter? $extra;

  DocumentsRoute({this.$extra});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DocumentsPage();
  }
}

class DocumentDetailsRoute extends GoRouteData with $DocumentDetailsRoute {
  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      outerShellNavigatorKey;

  final int documentId;
  final bool isLabelClickable;
  final String? queryString;
  final String? thumbnailUrl;
  final String? title;
  final String? heroTagPrefix;

  const DocumentDetailsRoute({
    required this.documentId,
    this.isLabelClickable = true,
    this.queryString,
    this.thumbnailUrl,
    this.title,
    this.heroTagPrefix,
  });

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DocumentDownloadCubit(
            context.read(),
            context.read(),
            context.read(),
            documentId: documentId,
          ),
        ),
        BlocProvider(
          create: (context) => DocumentShareCubit(
            context.read(),
            context.read(),
            documentId: documentId,
          ),
        ),
        BlocProvider(
          create: (context) => DocumentOpenInSystemCubit(
            context.read(),
            context.read(),
            documentId: documentId,
          ),
        ),
        BlocProvider(
          create: (context) => DocumentPrintCubit(
            context.read(),
            context.read(),
            documentId: documentId,
          ),
        ),
      ],
      child: DocumentDetailsPage(
        id: documentId,
        isLabelClickable: isLabelClickable,
        titleAndContentQueryString: queryString,
        thumbnailUrl: thumbnailUrl,
        title: title,
        heroTagPrefix: heroTagPrefix,
      ),
    );
  }
}

class EditDocumentRoute extends GoRouteData with $EditDocumentRoute {
  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      outerShellNavigatorKey;

  final int documentId;

  const EditDocumentRoute({required this.documentId});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: buildOverlayStyle(
        theme,
        systemNavigationBarColor: theme.colorScheme.surface,
      ),
      child: DocumentEditPage(documentId: documentId),
    );
  }
}

class DocumentPreviewRoute extends GoRouteData with $DocumentPreviewRoute {
  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      outerShellNavigatorKey;

  final int documentId;
  final String? title;
  final String? mimeType;

  const DocumentPreviewRoute({
    required this.documentId,
    this.title,
    this.mimeType,
  });

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return DocumentView(
      documentId: documentId,
      title: title,
      mimeType: mimeType,
    );
  }
}

class BulkEditExtraWrapper {
  final Iterable<Document> selection;
  final LabelType type;

  const BulkEditExtraWrapper(this.selection, this.type);
}

class BulkEditDocumentsRoute extends GoRouteData with $BulkEditDocumentsRoute {
  /// Selection
  final BulkEditExtraWrapper $extra;
  BulkEditDocumentsRoute(this.$extra);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return switch ($extra.type) {
      LabelType.tag => FullscreenBulkEditTagsWidget(
        selection: $extra.selection,
      ),
      _ => FullscreenBulkEditLabelPage(
        selection: $extra.selection,
        hintText: S.of(context)!.startTyping,
        options: switch ($extra.type) {
          LabelType.correspondent =>
            context.correspondentRepository
                    .getAllQuery()
                    .state
                    .data
                    ?.toIdMap() ??
                {},
          LabelType.documentType =>
            context.documentTypeRepository
                    .getAllQuery()
                    .state
                    .data
                    ?.toIdMap() ??
                {},
          LabelType.storagePath =>
            context.storagePathRepository.getAllQuery().state.data?.toIdMap() ??
                {},
          _ => throw Exception("Parameter not allowed here."),
        },
        labelMapper: (document) {
          return switch ($extra.type) {
            LabelType.correspondent => document.correspondent,
            LabelType.documentType => document.documentType,
            LabelType.storagePath => document.storagePath,
            _ => throw Exception("Parameter not allowed here."),
          };
        },
        leadingIcon: switch ($extra.type) {
          LabelType.correspondent => const Icon(Icons.person_outline),
          LabelType.documentType => const Icon(Icons.description_outlined),
          LabelType.storagePath => const Icon(Icons.folder_outlined),
          _ => throw Exception("Parameter not allowed here."),
        },
        onSubmit: switch ($extra.type) {
          LabelType.correspondent =>
            (int labelId) =>
                context.read<DocumentRepository>().bulkActionMutation().mutate(
                  BulkEditRequest(
                    documents: $extra.selection.ids.toList(),
                    method: MethodEnum.setCorrespondent,
                    parameters: {'correspondent': labelId},
                  ),
                ),
          LabelType.documentType =>
            (int labelId) =>
                context.read<DocumentRepository>().bulkActionMutation().mutate(
                  BulkEditRequest(
                    documents: $extra.selection.ids.toList(),
                    method: MethodEnum.setDocumentType,
                    parameters: {'document_type': labelId},
                  ),
                ),
          LabelType.storagePath =>
            (int labelId) =>
                context.read<DocumentRepository>().bulkActionMutation().mutate(
                  BulkEditRequest(
                    documents: $extra.selection.ids.toList(),
                    method: MethodEnum.setStoragePath,
                    parameters: {'storage_path': labelId},
                  ),
                ),
          _ => throw Exception("Parameter not allowed here."),
        },
        assignMessageBuilder: (int count, String name) {
          return switch ($extra.type) {
            LabelType.correspondent =>
              S.of(context)!.bulkEditCorrespondentAssignMessage(name, count),
            LabelType.documentType =>
              S.of(context)!.bulkEditDocumentTypeAssignMessage(count, name),
            LabelType.storagePath =>
              S.of(context)!.bulkEditDocumentTypeAssignMessage(count, name),
            _ => throw Exception("Parameter not allowed here."),
          };
        },
        removeMessageBuilder: (int count) {
          return switch ($extra.type) {
            LabelType.correspondent =>
              S.of(context)!.bulkEditCorrespondentRemoveMessage(count),
            LabelType.documentType =>
              S.of(context)!.bulkEditDocumentTypeRemoveMessage(count),
            LabelType.storagePath =>
              S.of(context)!.bulkEditStoragePathRemoveMessage(count),
            _ => throw Exception("Parameter not allowed here."),
          };
        },
      ),
    };
  }
}
