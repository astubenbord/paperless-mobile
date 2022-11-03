import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/correspondent_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/document_type_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/id_query_parameter.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/storage_path_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/tags_query.dart';
import 'package:paperless_mobile/features/documents/repository/document_repository.dart';
import 'package:paperless_mobile/features/labels/correspondent/bloc/correspondents_cubit.dart';
import 'package:paperless_mobile/features/labels/correspondent/model/correspondent.model.dart';
import 'package:paperless_mobile/features/labels/correspondent/view/pages/add_correspondent_page.dart';
import 'package:paperless_mobile/features/labels/document_type/bloc/document_type_cubit.dart';
import 'package:paperless_mobile/features/labels/document_type/model/document_type.model.dart';
import 'package:paperless_mobile/features/labels/document_type/view/pages/add_document_type_page.dart';
import 'package:paperless_mobile/features/labels/storage_path/bloc/storage_path_cubit.dart';
import 'package:paperless_mobile/features/labels/storage_path/model/storage_path.model.dart';
import 'package:paperless_mobile/features/labels/storage_path/view/pages/add_storage_path_page.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_form_field.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';

class DocumentEditPage extends StatefulWidget {
  final DocumentModel document;
  const DocumentEditPage({Key? key, required this.document}) : super(key: key);

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

  late Future<Uint8List> documentBytes;

  final GlobalKey<FormBuilderState> _formKey = GlobalKey();
  bool _isSubmitLoading = false;

  @override
  void initState() {
    documentBytes = getIt<DocumentRepository>().getPreview(widget.document.id);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_formKey.currentState?.saveAndValidate() ?? false) {
            final values = _formKey.currentState!.value;
            final updatedDocument = widget.document.copyWith(
              title: values[fkTitle],
              created: values[fkCreatedDate],
              documentType: values[fkDocumentType] as IdQueryParameter,
              correspondent: values[fkCorrespondent] as IdQueryParameter,
              storagePath: values[fkStoragePath] as IdQueryParameter,
              tags: values[fkTags] as TagsQuery,
            );
            setState(() {
              _isSubmitLoading = true;
            });
            await getIt<DocumentsCubit>().updateDocument(updatedDocument);
            Navigator.pop(context);
            showSnackBar(
                context, "Document successfully updated."); //TODO: INTL
          }
        },
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
            _buildTitleFormField().padded(),
            _buildCreatedAtFormField().padded(),
            BlocBuilder<DocumentTypeCubit, Map<int, DocumentType>>(
              builder: (context, state) {
                return LabelFormField<DocumentType, DocumentTypeQuery>(
                  notAssignedSelectable: false,
                  formBuilderState: _formKey.currentState,
                  labelCreationWidgetBuilder: (currentInput) =>
                      BlocProvider.value(
                    value: BlocProvider.of<DocumentTypeCubit>(context),
                    child: AddDocumentTypePage(
                      initialName: currentInput,
                    ),
                  ),
                  label: S.of(context).documentDocumentTypePropertyLabel,
                  initialValue:
                      DocumentTypeQuery.fromId(widget.document.documentType),
                  state: state,
                  name: fkDocumentType,
                  queryParameterIdBuilder: DocumentTypeQuery.fromId,
                  queryParameterNotAssignedBuilder:
                      DocumentTypeQuery.notAssigned,
                  prefixIcon: const Icon(Icons.description_outlined),
                );
              },
            ).padded(),
            BlocBuilder<CorrespondentCubit, Map<int, Correspondent>>(
              builder: (context, state) {
                return LabelFormField<Correspondent, CorrespondentQuery>(
                  notAssignedSelectable: false,
                  formBuilderState: _formKey.currentState,
                  labelCreationWidgetBuilder: (initialValue) =>
                      BlocProvider.value(
                    value: BlocProvider.of<CorrespondentCubit>(context),
                    child: AddCorrespondentPage(initalValue: initialValue),
                  ),
                  label: S.of(context).documentCorrespondentPropertyLabel,
                  state: state,
                  initialValue:
                      CorrespondentQuery.fromId(widget.document.correspondent),
                  name: fkCorrespondent,
                  queryParameterIdBuilder: CorrespondentQuery.fromId,
                  queryParameterNotAssignedBuilder:
                      CorrespondentQuery.notAssigned,
                  prefixIcon: const Icon(Icons.person_outlined),
                );
              },
            ).padded(),
            BlocBuilder<StoragePathCubit, Map<int, StoragePath>>(
              builder: (context, state) {
                return LabelFormField<StoragePath, StoragePathQuery>(
                  notAssignedSelectable: false,
                  formBuilderState: _formKey.currentState,
                  labelCreationWidgetBuilder: (initialValue) =>
                      BlocProvider.value(
                    value: BlocProvider.of<StoragePathCubit>(context),
                    child: AddStoragePathPage(initalValue: initialValue),
                  ),
                  label: S.of(context).documentStoragePathPropertyLabel,
                  state: state,
                  initialValue:
                      StoragePathQuery.fromId(widget.document.storagePath),
                  name: fkStoragePath,
                  queryParameterIdBuilder: StoragePathQuery.fromId,
                  queryParameterNotAssignedBuilder:
                      StoragePathQuery.notAssigned,
                  prefixIcon: const Icon(Icons.folder_outlined),
                );
              },
            ).padded(),
            TagFormField(
              initialValue: TagsQuery.fromIds(widget.document.tags),
              name: fkTags,
            ).padded(),
          ]),
        ),
      ),
    );
  }

  Widget _buildTitleFormField() {
    return FormBuilderTextField(
      name: fkTitle,
      validator: FormBuilderValidators.required(),
      decoration: InputDecoration(
        label: Text(S.of(context).documentTitlePropertyLabel),
      ),
      initialValue: widget.document.title,
    );
  }

  Widget _buildCreatedAtFormField() {
    return FormBuilderDateTimePicker(
      inputType: InputType.date,
      name: fkCreatedDate,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.calendar_month_outlined),
        label: Text(S.of(context).documentCreatedPropertyLabel),
      ),
      initialValue: widget.document.created,
      format: DateFormat("dd. MMMM yyyy"), //TODO: Localized date format
      initialEntryMode: DatePickerEntryMode.calendar,
    );
  }
}
