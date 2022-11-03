import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/bloc/label_bloc_provider.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/correspondent_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/document_type_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/storage_path_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/tags_query.dart';
import 'package:paperless_mobile/features/labels/correspondent/bloc/correspondents_cubit.dart';
import 'package:paperless_mobile/features/labels/correspondent/view/pages/edit_correspondent_page.dart';
import 'package:paperless_mobile/features/labels/document_type/bloc/document_type_cubit.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/home/view/widget/info_drawer.dart';
import 'package:paperless_mobile/features/labels/correspondent/model/correspondent.model.dart';
import 'package:paperless_mobile/features/labels/correspondent/view/pages/add_correspondent_page.dart';
import 'package:paperless_mobile/features/labels/document_type/model/document_type.model.dart';
import 'package:paperless_mobile/features/labels/document_type/view/pages/add_document_type_page.dart';
import 'package:paperless_mobile/features/labels/document_type/view/pages/edit_document_type_page.dart';
import 'package:paperless_mobile/features/labels/model/label.model.dart';
import 'package:paperless_mobile/features/labels/storage_path/bloc/storage_path_cubit.dart';
import 'package:paperless_mobile/features/labels/storage_path/model/storage_path.model.dart';
import 'package:paperless_mobile/features/labels/storage_path/view/pages/add_storage_path_page.dart';
import 'package:paperless_mobile/features/labels/storage_path/view/pages/edit_storage_path_page.dart';
import 'package:paperless_mobile/features/labels/tags/model/tag.model.dart';
import 'package:paperless_mobile/features/labels/tags/view/pages/add_tag_page.dart';
import 'package:paperless_mobile/features/labels/tags/view/pages/edit_tag_page.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_item.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_tab_view.dart';
import 'package:paperless_mobile/features/labels/tags/bloc/tags_cubit.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class LabelsPage extends StatefulWidget {
  const LabelsPage({Key? key}) : super(key: key);

  @override
  State<LabelsPage> createState() => _LabelsPageState();
}

class _LabelsPageState extends State<LabelsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    BlocProvider.of<CorrespondentCubit>(context).initialize();
    BlocProvider.of<DocumentTypeCubit>(context).initialize();
    BlocProvider.of<TagCubit>(context).initialize();

    _tabController = TabController(length: 4, vsync: this)
      ..addListener(() => setState(() => _currentIndex = _tabController.index));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<DocumentsCubit>(),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          drawer: const InfoDrawer(),
          appBar: AppBar(
            title: Text(
              [
                S.of(context).labelsPageCorrespondentsTitleText,
                S.of(context).labelsPageDocumentTypesTitleText,
                S.of(context).labelsPageTagsTitleText,
                S.of(context).labelsPageStoragePathTitleText
              ][_currentIndex],
            ),
            actions: [
              IconButton(
                onPressed: _onAddPressed,
                icon: const Icon(Icons.add),
              )
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: ColoredBox(
                color: Theme.of(context).bottomAppBarColor,
                child: TabBar(
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  controller: _tabController,
                  tabs: [
                    Tab(
                      icon: Icon(
                        Icons.person_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Tab(
                      icon: Icon(
                        Icons.description_outlined,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Tab(
                      icon: Icon(
                        Icons.label_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Tab(
                      icon: Icon(
                        Icons.folder_open,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              LabelTabView<Correspondent>(
                cubit: BlocProvider.of<CorrespondentCubit>(context),
                filterBuilder: (label) => DocumentFilter(
                  correspondent: CorrespondentQuery.fromId(label.id),
                  pageSize: label.documentCount ?? 0,
                ),
                onOpenEditPage: _openEditCorrespondentPage,
                emptyStateActionButtonLabel:
                    S.of(context).labelsPageCorrespondentEmptyStateAddNewLabel,
                emptyStateDescription: S
                    .of(context)
                    .labelsPageCorrespondentEmptyStateDescriptionText,
                onOpenAddNewPage: _onAddPressed,
              ),
              LabelTabView<DocumentType>(
                cubit: BlocProvider.of<DocumentTypeCubit>(context),
                filterBuilder: (label) => DocumentFilter(
                  documentType: DocumentTypeQuery.fromId(label.id),
                  pageSize: label.documentCount ?? 0,
                ),
                onOpenEditPage: _openEditDocumentTypePage,
                emptyStateActionButtonLabel:
                    S.of(context).labelsPageDocumentTypeEmptyStateAddNewLabel,
                emptyStateDescription: S
                    .of(context)
                    .labelsPageDocumentTypeEmptyStateDescriptionText,
                onOpenAddNewPage: _onAddPressed,
              ),
              LabelTabView<Tag>(
                cubit: BlocProvider.of<TagCubit>(context),
                filterBuilder: (label) => DocumentFilter(
                  tags: TagsQuery.fromIds([label.id!]),
                  pageSize: label.documentCount ?? 0,
                ),
                onOpenEditPage: _openEditTagPage,
                leadingBuilder: (t) => CircleAvatar(backgroundColor: t.color),
                emptyStateActionButtonLabel:
                    S.of(context).labelsPageTagsEmptyStateAddNewLabel,
                emptyStateDescription:
                    S.of(context).labelsPageTagsEmptyStateDescriptionText,
                onOpenAddNewPage: _onAddPressed,
              ),
              LabelTabView<StoragePath>(
                cubit: BlocProvider.of<StoragePathCubit>(context),
                onOpenEditPage: _openEditStoragePathPage,
                filterBuilder: (label) => DocumentFilter(
                  storagePath: StoragePathQuery.fromId(label.id),
                  pageSize: label.documentCount ?? 0,
                ),
                contentBuilder: (path) => Text(path.path ?? ""),
                emptyStateActionButtonLabel:
                    S.of(context).labelsPageStoragePathEmptyStateAddNewLabel,
                emptyStateDescription: S
                    .of(context)
                    .labelsPageStoragePathEmptyStateDescriptionText,
                onOpenAddNewPage: _onAddPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditCorrespondentPage(Correspondent correspondent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: getIt<DocumentsCubit>()),
            BlocProvider.value(
                value: BlocProvider.of<CorrespondentCubit>(context)),
          ],
          child: EditCorrespondentPage(correspondent: correspondent),
        ),
      ),
    );
  }

  void _openEditDocumentTypePage(DocumentType docType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: getIt<DocumentsCubit>()),
            BlocProvider.value(
                value: BlocProvider.of<DocumentTypeCubit>(context)),
          ],
          child: EditDocumentTypePage(documentType: docType),
        ),
      ),
    );
  }

  void _openEditTagPage(Tag tag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: getIt<DocumentsCubit>()),
            BlocProvider.value(value: BlocProvider.of<TagCubit>(context)),
          ],
          child: EditTagPage(tag: tag),
        ),
      ),
    );
  }

  void _openEditStoragePathPage(StoragePath path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: getIt<DocumentsCubit>()),
            BlocProvider.value(
                value: BlocProvider.of<StoragePathCubit>(context)),
          ],
          child: EditStoragePathPage(storagePath: path),
        ),
      ),
    );
  }

  void _onAddPressed() {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        late final Widget page;
        switch (_currentIndex) {
          case 0:
            page = const AddCorrespondentPage();
            break;
          case 1:
            page = const AddDocumentTypePage();
            break;
          case 2:
            page = const AddTagPage();
            break;
          case 3:
            page = const AddStoragePathPage();
        }
        return LabelBlocProvider(child: page);
      },
    ));
  }
}
