import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/document_bulk_action/cubit/document_bulk_action_cubit.dart';
import 'package:paperless_mobile/features/document_bulk_action/view/widgets/fullscreen_bulk_edit_label_page.dart';
import 'package:paperless_mobile/features/document_bulk_action/view/widgets/fullscreen_bulk_edit_tags_widget.dart';
import 'package:paperless_mobile/features/document_details/cubit/document_details_cubit.dart';
import 'package:paperless_mobile/features/document_details/view/pages/document_details_page.dart';
import 'package:paperless_mobile/features/document_edit/cubit/document_edit_cubit.dart';
import 'package:paperless_mobile/features/document_edit/view/document_edit_page.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_view.dart';
import 'package:paperless_mobile/features/documents/view/pages/documents_page.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/navigation_keys.dart';
import 'package:paperless_mobile/core/theme.dart';

import 'shells/authenticated_route.dart';

class DocumentsBranch extends StatefulShellBranchData {
  static final GlobalKey<NavigatorState> $navigatorKey = documentsNavigatorKey;
  const DocumentsBranch();
}

class DocumentsRoute extends GoRouteData with $DocumentsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DocumentsPage();
  }
}

class DocumentDetailsRoute extends GoRouteData with $DocumentDetailsRoute {
  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      outerShellNavigatorKey;

  final int id;
  final bool isLabelClickable;
  final String? queryString;
  final String? thumbnailUrl;
  final String? title;

  const DocumentDetailsRoute({
    required this.id,
    this.isLabelClickable = true,
    this.queryString,
    this.thumbnailUrl,
    this.title,
  });

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (_) => DocumentDetailsCubit(
        context.read(),
        context.read(),
        context.read(),
        id: id,
      )..initialize(),
      lazy: false,
      child: DocumentDetailsPage(
        id: id,
        isLabelClickable: isLabelClickable,
        titleAndContentQueryString: queryString,
        thumbnailUrl: thumbnailUrl,
        title: title,
      ),
    );
  }
}

class EditDocumentRoute extends GoRouteData with $EditDocumentRoute {
  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      outerShellNavigatorKey;

  final DocumentModel $extra;

  const EditDocumentRoute(this.$extra);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: buildOverlayStyle(
        theme,
        systemNavigationBarColor: theme.colorScheme.surface,
      ),
      child: BlocProvider(
        create: (context) => DocumentEditCubit(
          context.read(),
          context.read(),
          context.read(),
          document: $extra,
        )..loadFieldSuggestions(),
        child: const DocumentEditPage(),
      ),
    );
  }
}

class DocumentPreviewRoute extends GoRouteData with $DocumentPreviewRoute {
  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      outerShellNavigatorKey;
  final int id;
  final String? title;

  const DocumentPreviewRoute({
    required this.id,
    this.title,
  });

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return DocumentView(
      bytes: context.read<PaperlessDocumentsApi>().downloadDocument(id),
      title: title,
    );
    // return DocumentView(
    //   documentBytes: context.read<PaperlessDocumentsApi>().downloadDocument(id),
    //   title: title,
    // );
  }
}

class BulkEditExtraWrapper {
  final List<DocumentModel> selection;
  final LabelType type;

  const BulkEditExtraWrapper(this.selection, this.type);
}

class BulkEditDocumentsRoute extends GoRouteData with $BulkEditDocumentsRoute {
  /// Selection
  final BulkEditExtraWrapper $extra;
  BulkEditDocumentsRoute(this.$extra);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final labelRepository = context.read<LabelRepository>();
    return BlocProvider(
      create: (_) => DocumentBulkActionCubit(
        context.read(),
        context.read(),
        selection: $extra.selection,
      ),
      child: BlocBuilder<DocumentBulkActionCubit, DocumentBulkActionState>(
        builder: (context, state) {
          return switch ($extra.type) {
            LabelType.tag => const FullscreenBulkEditTagsWidget(),
            _ => FullscreenBulkEditLabelPage(
                options: switch ($extra.type) {
                  LabelType.correspondent => labelRepository.correspondents,
                  LabelType.documentType => labelRepository.documentTypes,
                  LabelType.storagePath => labelRepository.storagePaths,
                  _ => throw Exception("Parameter not allowed here."),
                },
                selection: state.selection,
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
                  LabelType.documentType =>
                    const Icon(Icons.description_outlined),
                  LabelType.storagePath => const Icon(Icons.folder_outlined),
                  _ => throw Exception("Parameter not allowed here."),
                },
                hintText: S.of(context)!.startTyping,
                onSubmit: switch ($extra.type) {
                  LabelType.correspondent => context
                      .read<DocumentBulkActionCubit>()
                      .bulkModifyCorrespondent,
                  LabelType.documentType => context
                      .read<DocumentBulkActionCubit>()
                      .bulkModifyDocumentType,
                  LabelType.storagePath => context
                      .read<DocumentBulkActionCubit>()
                      .bulkModifyStoragePath,
                  _ => throw Exception("Parameter not allowed here."),
                },
                assignMessageBuilder: (int count, String name) {
                  return switch ($extra.type) {
                    LabelType.correspondent => S
                        .of(context)!
                        .bulkEditCorrespondentAssignMessage(name, count),
                    LabelType.documentType => S
                        .of(context)!
                        .bulkEditDocumentTypeAssignMessage(count, name),
                    LabelType.storagePath => S
                        .of(context)!
                        .bulkEditDocumentTypeAssignMessage(count, name),
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
        },
      ),
    );
  }
}
