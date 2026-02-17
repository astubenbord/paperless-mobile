import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/extensions/document_extensions.dart';
import 'package:paperless_mobile/features/documents/view/widgets/adaptive_documents_view.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/view_type_selection_widget.dart';
import 'package:paperless_mobile/features/linked_documents/cubit/linked_documents_cubit.dart';
import 'package:paperless_mobile/core/paging/view/document_paging_view_mixin.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';

class LinkedDocumentsPage extends StatefulWidget {
  const LinkedDocumentsPage({super.key});

  @override
  State<LinkedDocumentsPage> createState() => _LinkedDocumentsPageState();
}

class _LinkedDocumentsPageState extends State<LinkedDocumentsPage>
    with DocumentPagingViewMixin<LinkedDocumentsPage, LinkedDocumentsCubit> {
  @override
  final pagingScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context)!.linkedDocuments),
        actions: [
          BlocBuilder<LinkedDocumentsCubit, LinkedDocumentsState>(
            builder: (context, state) {
              return ViewTypeSelectionWidget(
                viewType: state.viewType,
                onChanged: context.read<LinkedDocumentsCubit>().setViewType,
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<LinkedDocumentsCubit, LinkedDocumentsState>(
        builder: (context, state) {
          return BlocBuilder<ConnectivityCubit, ConnectivityState>(
            builder: (context, connectivity) {
              return CustomScrollView(
                controller: pagingScrollController,
                slivers: [
                  SliverAdaptiveDocumentsView(
                    viewType: state.viewType,
                    documents: state.documents,
                    hasInternetConnection: connectivity.isConnected,
                    isLabelClickable: false,
                    isLoading: state.isLoading,
                    hasLoaded: state.hasLoaded,
                    onTap: (document) {
                      DocumentDetailsRoute(
                        title: document.title,
                        id: document.id,
                        isLabelClickable: false,
                        thumbnailUrl: document.buildThumbnailUrl(context),
                      ).push(context);
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
