import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_correspondent_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_document_type_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_storage_path_page.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:paperless_mobile/features/labels/bloc/providers/labels_bloc_provider.dart';
import 'package:paperless_mobile/features/labels/bloc/label_state.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_form_field.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

class DocumentEditPage extends StatefulWidget {
  final DocumentModel document;
  final FutureOr<void> Function(DocumentModel updatedDocument) onEdit;

  const DocumentEditPage({
    Key? key,
    required this.document,
    required this.onEdit,
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

  late Future<Uint8List> documentBytes;

  final GlobalKey<FormBuilderState> _formKey = GlobalKey();
  bool _isSubmitLoading = false;

  @override
  void initState() {
    super.initState();
    documentBytes =
        getIt<PaperlessDocumentsApi>().getPreview(widget.document.id);
  }

  @override
  Widget build(BuildContext context) {
    return LabelsBlocProvider(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _onSubmit,
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
              _buildDocumentTypeFormField().padded(),
              _buildCorrespondentFormField().padded(),
              _buildStoragePathFormField().padded(),
              TagFormField(
                initialValue: IdsTagsQuery.included(widget.document.tags),
                notAssignedSelectable: false,
                anyAssignedSelectable: false,
                excludeAllowed: false,
                name: fkTags,
              ).padded(),
            ]),
          ),
        ),
      ),
    );
  }

  BlocBuilder<LabelCubit<StoragePath>, LabelState<StoragePath>>
      _buildStoragePathFormField() {
    return BlocBuilder<LabelCubit<StoragePath>, LabelState<StoragePath>>(
      builder: (context, state) {
        return LabelFormField<StoragePath, StoragePathQuery>(
          notAssignedSelectable: false,
          formBuilderState: _formKey.currentState,
          labelCreationWidgetBuilder: (initialValue) =>
              RepositoryProvider.value(
            value: RepositoryProvider.of<LabelRepository<StoragePath>>(context),
            child: AddStoragePathPage(initalValue: initialValue),
          ),
          label: S.of(context).documentStoragePathPropertyLabel,
          state: state.labels,
          initialValue: StoragePathQuery.fromId(widget.document.storagePath),
          name: fkStoragePath,
          queryParameterIdBuilder: StoragePathQuery.fromId,
          queryParameterNotAssignedBuilder: StoragePathQuery.notAssigned,
          prefixIcon: const Icon(Icons.folder_outlined),
        );
      },
    );
  }

  BlocBuilder<LabelCubit<Correspondent>, LabelState<Correspondent>>
      _buildCorrespondentFormField() {
    return BlocBuilder<LabelCubit<Correspondent>, LabelState<Correspondent>>(
      builder: (context, state) {
        return LabelFormField<Correspondent, CorrespondentQuery>(
          notAssignedSelectable: false,
          formBuilderState: _formKey.currentState,
          labelCreationWidgetBuilder: (initialValue) =>
              RepositoryProvider.value(
            value: RepositoryProvider.of<LabelRepository<Correspondent>>(
              context,
            ),
            child: AddCorrespondentPage(initialName: initialValue),
          ),
          label: S.of(context).documentCorrespondentPropertyLabel,
          state: state.labels,
          initialValue:
              CorrespondentQuery.fromId(widget.document.correspondent),
          name: fkCorrespondent,
          queryParameterIdBuilder: CorrespondentQuery.fromId,
          queryParameterNotAssignedBuilder: CorrespondentQuery.notAssigned,
          prefixIcon: const Icon(Icons.person_outlined),
        );
      },
    );
  }

  BlocBuilder<LabelCubit<DocumentType>, LabelState<DocumentType>>
      _buildDocumentTypeFormField() {
    return BlocBuilder<LabelCubit<DocumentType>, LabelState<DocumentType>>(
      builder: (context, state) {
        return LabelFormField<DocumentType, DocumentTypeQuery>(
          notAssignedSelectable: false,
          formBuilderState: _formKey.currentState,
          labelCreationWidgetBuilder: (currentInput) =>
              RepositoryProvider.value(
            value: RepositoryProvider.of<LabelRepository<DocumentType>>(
              context,
            ),
            child: AddDocumentTypePage(
              initialName: currentInput,
            ),
          ),
          label: S.of(context).documentDocumentTypePropertyLabel,
          initialValue: DocumentTypeQuery.fromId(widget.document.documentType),
          state: state.labels,
          name: fkDocumentType,
          queryParameterIdBuilder: DocumentTypeQuery.fromId,
          queryParameterNotAssignedBuilder: DocumentTypeQuery.notAssigned,
          prefixIcon: const Icon(Icons.description_outlined),
        );
      },
    );
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      var updatedDocument = widget.document.copyWith(
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
        await widget.onEdit(updatedDocument);
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
