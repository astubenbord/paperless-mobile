import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/correspondent_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/document_type_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/storage_path_repository_state.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/edit_document/cubit/edit_document_cubit.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_correspondent_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_document_type_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_storage_path_page.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:paperless_mobile/features/labels/bloc/label_state.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_form_field.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

class DocumentEditPage extends StatefulWidget {
  final FieldSuggestions suggestions;
  const DocumentEditPage({
    Key? key,
    required this.suggestions,
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
                    state.document.documentType,
                    state.documentTypes,
                  ).padded(),
                  _buildCorrespondentFormField(
                    state.document.correspondent,
                    state.correspondents,
                  ).padded(),
                  _buildStoragePathFormField(
                    state.document.storagePath,
                    state.storagePaths,
                  ).padded(),
                  TagFormField(
                    initialValue:
                        IdsTagsQuery.included(state.document.tags.toList()),
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
    int? initialId,
    Map<int, StoragePath> options,
  ) {
    return Column(
      children: [
        LabelFormField<StoragePath>(
          notAssignedSelectable: false,
          formBuilderState: _formKey.currentState,
          labelCreationWidgetBuilder: (initialValue) => RepositoryProvider(
            create: (context) => context.read<
                LabelRepository<StoragePath, StoragePathRepositoryState>>(),
            child: AddStoragePathPage(initalValue: initialValue),
          ),
          textFieldLabel: S.of(context).documentStoragePathPropertyLabel,
          labelOptions: options,
          initialValue: IdQueryParameter.fromId(initialId),
          name: fkStoragePath,
          prefixIcon: const Icon(Icons.folder_outlined),
        ),
        if (widget.suggestions.hasSuggestedStoragePaths)
          _buildSuggestionsSkeleton<int>(
            suggestions: widget.suggestions.storagePaths,
            itemBuilder: (context, itemData) => ActionChip(
              label: Text(options[itemData]!.name),
              onPressed: () => _formKey.currentState?.fields[fkStoragePath]
                  ?.didChange((IdQueryParameter.fromId(itemData))),
            ),
          ),
      ],
    );
  }

  Widget _buildCorrespondentFormField(
      int? initialId, Map<int, Correspondent> options) {
    return Column(
      children: [
        LabelFormField<Correspondent>(
          notAssignedSelectable: false,
          formBuilderState: _formKey.currentState,
          labelCreationWidgetBuilder: (initialValue) => RepositoryProvider(
            create: (context) => context.read<
                LabelRepository<Correspondent, CorrespondentRepositoryState>>(),
            child: AddCorrespondentPage(initialName: initialValue),
          ),
          textFieldLabel: S.of(context).documentCorrespondentPropertyLabel,
          labelOptions: options,
          initialValue: IdQueryParameter.fromId(initialId),
          name: fkCorrespondent,
          prefixIcon: const Icon(Icons.person_outlined),
        ),
        if (widget.suggestions.hasSuggestedCorrespondents)
          _buildSuggestionsSkeleton<int>(
            suggestions: widget.suggestions.correspondents,
            itemBuilder: (context, itemData) => ActionChip(
              label: Text(options[itemData]!.name),
              onPressed: () => _formKey.currentState?.fields[fkCorrespondent]
                  ?.didChange((IdQueryParameter.fromId(itemData))),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentTypeFormField(
    int? initialId,
    Map<int, DocumentType> options,
  ) {
    return Column(
      children: [
        LabelFormField<DocumentType>(
          notAssignedSelectable: false,
          formBuilderState: _formKey.currentState,
          labelCreationWidgetBuilder: (currentInput) => RepositoryProvider(
            create: (context) => context.read<
                LabelRepository<DocumentType, DocumentTypeRepositoryState>>(),
            child: AddDocumentTypePage(
              initialName: currentInput,
            ),
          ),
          textFieldLabel: S.of(context).documentDocumentTypePropertyLabel,
          initialValue: IdQueryParameter.fromId(initialId),
          labelOptions: options,
          name: fkDocumentType,
          prefixIcon: const Icon(Icons.description_outlined),
        ),
        if (widget.suggestions.hasSuggestedDocumentTypes)
          _buildSuggestionsSkeleton<int>(
            suggestions: widget.suggestions.documentTypes,
            itemBuilder: (context, itemData) => ActionChip(
              label: Text(options[itemData]!.name),
              onPressed: () => _formKey.currentState?.fields[fkDocumentType]
                  ?.didChange(IdQueryParameter.fromId(itemData)),
            ),
          ),
      ],
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
        await context.read<EditDocumentCubit>().updateDocument(mergedDocument);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormBuilderDateTimePicker(
          inputType: InputType.date,
          name: fkCreatedDate,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_month_outlined),
            label: Text(S.of(context).documentCreatedPropertyLabel),
          ),
          initialValue: initialCreatedAtDate,
          format: DateFormat("dd. MMMM yyyy"), //TODO: Localized date format
          initialEntryMode: DatePickerEntryMode.calendar,
        ),
        if (widget.suggestions.hasSuggestedDates)
          _buildSuggestionsSkeleton<DateTime>(
            suggestions: widget.suggestions.dates,
            itemBuilder: (context, itemData) => ActionChip(
              label: Text(DateFormat.yMd().format(itemData)),
              onPressed: () => _formKey.currentState?.fields[fkCreatedDate]
                  ?.didChange(itemData),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionsSkeleton<T>({
    required Iterable<T> suggestions,
    required ItemBuilder<T> itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Suggestions: ",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            itemBuilder: (context, index) =>
                itemBuilder(context, suggestions.elementAt(index)),
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 4.0),
          ),
        ),
      ],
    ).padded();
  }
}
