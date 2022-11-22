import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:paperless_mobile/core/bloc/label_bloc_provider.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/tags_query.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_details_page.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/home/view/widget/info_drawer.dart';
import 'package:paperless_mobile/features/labels/tags/bloc/tags_cubit.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  Iterable<int> _inboxTags = [];
  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _initInbox();
  }

  Future<void> _initInbox() async {
    final tags = BlocProvider.of<TagCubit>(context).state.values;
    _inboxTags = tags.where((t) => t.isInboxTag ?? false).map((t) => t.id!);
    final filter = DocumentFilter(tags: IdsTagsQuery.included(_inboxTags));
    return BlocProvider.of<DocumentsCubit>(context).updateFilter(
      filter: filter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Inbox"),
      ),
      drawer: const InfoDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        label: Text("Mark all as read"),
        icon: const Icon(FontAwesomeIcons.checkDouble),
        onPressed: () {},
      ),
      body: BlocBuilder<DocumentsCubit, DocumentsState>(
        builder: (context, state) {
          if (!state.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.documents.isEmpty) {
            return Text("You do not have new documents in your inbox.")
                .padded();
          }
          return Column(
            children: [
              Text(
                "You have ${state.documents.length} documents in your inbox.",
              ),
              Expanded(
                  child: ListView(
                children: state.documents
                    .map(
                      (doc) => Dismissible(
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          BlocProvider.of<DocumentsCubit>(context)
                              .removeInboxTags(doc, _inboxTags);
                        },
                        key: ObjectKey(doc.id),
                        child: ListTile(
                          title: Text(doc.title),
                          isThreeLine: true,
                          leading: DocumentPreview(id: doc.id),
                          subtitle: Text(DateFormat().format(doc.added)),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LabelBlocProvider(
                                child: BlocProvider.value(
                                  value:
                                      BlocProvider.of<DocumentsCubit>(context),
                                  child: DocumentDetailsPage(
                                    documentId: doc.id,
                                    allowEdit: false,
                                    isLabelClickable: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              )),
            ],
          );
        },
      ),
    );
  }
}
