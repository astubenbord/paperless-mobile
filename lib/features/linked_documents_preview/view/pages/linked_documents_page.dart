import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:paperless_mobile/core/widgets/documents_list_loading_widget.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_details_page.dart';
import 'package:paperless_mobile/features/documents/view/widgets/list/document_list.dart';
import 'package:paperless_mobile/features/documents/view/widgets/list/document_list_item.dart';
import 'package:paperless_mobile/features/labels/bloc/global_state_bloc_provider.dart';
import 'package:paperless_mobile/features/linked_documents_preview/bloc/linked_documents_cubit.dart';
import 'package:paperless_mobile/features/linked_documents_preview/bloc/state/linked_documents_state.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class LinkedDocumentsPage extends StatefulWidget {
  const LinkedDocumentsPage({super.key});

  @override
  State<LinkedDocumentsPage> createState() => _LinkedDocumentsPageState();
}

class _LinkedDocumentsPageState extends State<LinkedDocumentsPage> {
  final _pagingController =
      PagingController<int, DocumentModel>(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    _pagingController.nextPageKey = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).linkedDocumentsPageTitle),
      ),
      body: BlocBuilder<LinkedDocumentsCubit, LinkedDocumentsState>(
        builder: (context, state) {
          if (!state.isLoaded) {
            return const DocumentsListLoadingWidget();
          }

          _pagingController.itemList = state.documents!.results;
          return Column(
            children: [
              Text(
                S.of(context).referencedDocumentsReadOnlyHintText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.caption,
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    PagedSliverList<int, DocumentModel>(
                      pagingController: _pagingController,
                      builderDelegate: PagedChildBuilderDelegate(
                        animateTransitions: true,
                        itemBuilder: (context, document, index) {
                          return DocumentListItem(
                            isLabelClickable: false,
                            document: document,
                            onTap: (doc) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctxt) => GlobalStateBlocProvider(
                                    additionalProviders: [
                                      BlocProvider.value(
                                        value: BlocProvider.of<DocumentsCubit>(
                                          context,
                                        ),
                                      ),
                                    ],
                                    child: DocumentDetailsPage(
                                      documentId: doc.id,
                                      allowEdit: false,
                                      isLabelClickable: false,
                                    ),
                                  ),
                                ),
                              );
                            },
                            isSelected: false,
                            isAtLeastOneSelected: false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
