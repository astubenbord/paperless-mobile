import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/edit_document/cubit/edit_document_cubit.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_correspondent_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_document_type_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_storage_path_page.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_form_field.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

class DocumentEditPage extends StatefulWidget {
  const DocumentEditPage({
    Key? key,
  }) : super(key: key);

  @override
  State<DocumentEditPage> createState() => _DocumentEditPageState();
}

class _DocumentEditPageState extends State<DocumentEditPage> {
  static const fkTitle = "title";
  static const fkCorrespondent = "correspondent";
  static const fkTags = "tags";
  static const fkDocumentType = "documentType";
  static const fkCreatedDate = "createdAtDate";
  static const fkStoragePath = 'storagePath';

  final GlobalKey<FormBuilderState> _formKey = GlobalKey();
  bool _isSubmitLoading = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditDocumentCubit, EditDocumentState>(
      builder: (context, state) {
        return Scaffold(
            resizeToAvoidBottomInset: false,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _onSubmit(state.document),
              icon: const Icon(Icons.save),
              label: Text(S.of(context).genericActionSaveLabel),
            ),
            appBar: AppBar(
              title: Text(S.of(context).documentEditPageTitle),
              bottom: _isSubmitLoading
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(4),
                      child: LinearProgressIndicator(),
                    )
                  : null,
            ),
            extendBody: true,
            body: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 8,
                left: 8,
                right: 8,
              ),
              child: FormBuilder(
                key: _formKey,
                child: ListView(children: [
                  _buildTitleFormField(state.document.title).padded(),
                  _buildCreatedAtFormField(state.document.created).padded(),
                  _buildDocumentTypeFormField(
                          state.document.documentType, state.documentTypes)
                      .padded(),
                  _buildCorrespondentFormField(
                          state.document.correspondent, state.correspondents)
                      .padded(),
                  _buildStoragePathFormField(
                          state.document.storagePath, state.storagePaths)
                      .padded(),
                  TagFormField(
                    initialValue: IdsTagsQuery.included(state.document.tags),
                    notAssignedSelectable: false,
                    anyAssignedSelectable: false,
                    excludeAllowed: false,
                    name: fkTags,
                    selectableOptions: state.tags,
                  ).padded(),
                ]),
              ),
            ));
      },
    );
  }

  Widget _buildStoragePathFormField(
      int? initialId, Map<int, StoragePath> options) {
    return LabelFormField<StoragePath, StoragePathQuery>(
      notAssignedSelectable: false,
      formBuilderState: _formKey.currentState,
      labelCreationWidgetBuilder: (initialValue) => RepositoryProvider.value(
        value: RepositoryProvider.of<LabelRepository<StoragePath>>(context),
        child: AddStoragePathPage(initalValue: initialValue),
      ),
      label: S.of(context).documentStoragePathPropertyLabel,
      state: options,
      initialValue: StoragePathQuery.fromId(initialId),
      name: fkStoragePath,
      queryParameterIdBuilder: StoragePathQuery.fromId,
      queryParameterNotAssignedBuilder: StoragePathQuery.notAssigned,
      prefixIcon: const Icon(Icons.folder_outlined),
    );
  }

  Widget _buildCorrespondentFormField(
      int? initialId, Map<int, Correspondent> options) {
    return LabelFormField<Correspondent, CorrespondentQuery>(
      notAssignedSelectable: false,
      formBuilderState: _formKey.currentState,
      labelCreationWidgetBuilder: (initialValue) => RepositoryProvider.value(
        value: RepositoryProvider.of<LabelRepository<Correspondent>>(
          context,
        ),
        child: AddCorrespondentPage(initialName: initialValue),
      ),
      label: S.of(context).documentCorrespondentPropertyLabel,
      state: options,
      initialValue: CorrespondentQuery.fromId(initialId),
      name: fkCorrespondent,
      queryParameterIdBuilder: CorrespondentQuery.fromId,
      queryParameterNotAssignedBuilder: CorrespondentQuery.notAssigned,
      prefixIcon: const Icon(Icons.person_outlined),
    );
  }

  Widget _buildDocumentTypeFormField(
      int? initialId, Map<int, DocumentType> options) {
    return LabelFormField<DocumentType, DocumentTypeQuery>(
      notAssignedSelectable: false,
      formBuilderState: _formKey.currentState,
      labelCreationWidgetBuilder: (currentInput) => RepositoryProvider.value(
        value: RepositoryProvider.of<LabelRepository<DocumentType>>(
          context,
        ),
        child: AddDocumentTypePage(
          initialName: currentInput,
        ),
      ),
      label: S.of(context).documentDocumentTypePropertyLabel,
      initialValue: DocumentTypeQuery.fromId(initialId),
      state: options,
      name: fkDocumentType,
      queryParameterIdBuilder: DocumentTypeQuery.fromId,
      queryParameterNotAssignedBuilder: DocumentTypeQuery.notAssigned,
      prefixIcon: const Icon(Icons.description_outlined),
    );
  }

  Future<void> _onSubmit(DocumentModel document) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      var mergedDocument = document.copyWith(
        title: values[fkTitle],
        created: values[fkCreatedDate],
        overwriteDocumentType: true,
        documentType: (values[fkDocumentType] as IdQueryParameter).id,
        overwriteCorrespondent: true,
        correspondent: (values[fkCorrespondent] as IdQueryParameter).id,
        overwriteStoragePath: true,
        storagePath: (values[fkStoragePath] as IdQueryParameter).id,
        overwriteTags: true,
        tags: (values[fkTags] as IdsTagsQuery).includedIds,
      );
      setState(() {
        _isSubmitLoading = true;
      });
      try {
        await BlocProvider.of<EditDocumentCubit>(context)
            .updateDocument(mergedDocument);
        showSnackBar(context, S.of(context).documentUpdateSuccessMessage);
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      } finally {
        setState(() {
          _isSubmitLoading = false;
        });
        Navigator.pop(context);
      }
    }
  }

  Widget _buildTitleFormField(String? initialTitle) {
    return FormBuilderTextField(
      name: fkTitle,
      validator: FormBuilderValidators.required(),
      decoration: InputDecoration(
        label: Text(S.of(context).documentTitlePropertyLabel),
      ),
      initialValue: initialTitle,
    );
  }

  Widget _buildCreatedAtFormField(DateTime? initialCreatedAtDate) {
    return FormBuilderDateTimePicker(
      inputType: InputType.date,
      name: fkCreatedDate,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.calendar_month_outlined),
        label: Text(S.of(context).documentCreatedPropertyLabel),
      ),
      initialValue: initialCreatedAtDate,
      format: DateFormat("dd. MMMM yyyy"), //TODO: Localized date format
      initialEntryMode: DatePickerEntryMode.calendar,
    );
  }
}
