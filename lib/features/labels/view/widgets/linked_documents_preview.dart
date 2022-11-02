import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/bloc/label_bloc_provider.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_details_page.dart';
import 'package:paperless_mobile/features/documents/view/widgets/list/document_list.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class LinkedDocumentsPreview extends StatefulWidget {
  final DocumentFilter filter;

  const LinkedDocumentsPreview({super.key, required this.filter});

  @override
  State<LinkedDocumentsPreview> createState() => _LinkedDocumentsPreviewState();
}

class _LinkedDocumentsPreviewState extends State<LinkedDocumentsPreview> {
  final PagingController<int, DocumentModel> _pagingController = PagingController(firstPageKey: 1);

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
      body: BlocBuilder<DocumentsCubit, DocumentsState>(
        builder: (context, state) {
          _pagingController.itemList = state.documents;
          return CustomScrollView(
            slivers: [
              DocumentListView(
                onTap: (doc) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctxt) => LabelBlocProvider(
                        child: BlocProvider.value(
                            value: BlocProvider.of<DocumentsCubit>(context),
                            child: DocumentDetailsPage(documentId: doc.id)),
                      ),
                    ),
                  );
                },
                pagingController: _pagingController,
                state: state,
                onSelected: BlocProvider.of<DocumentsCubit>(context).toggleDocumentSelection,
                hasInternetConnection: true,
              ),
            ],
          );
        },
      ),
    );
  }
}
