import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/document_upload/cubit/document_upload_cubit.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_correspondent_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_document_type_page.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_form_field.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

class DocumentUploadPreparationPage extends StatefulWidget {
  final Uint8List fileBytes;
  final String? title;
  final String? filename;
  final void Function(DocumentModel)? onSuccessfullyConsumed;

  const DocumentUploadPreparationPage({
    Key? key,
    required this.fileBytes,
    this.title,
    this.filename,
    this.onSuccessfullyConsumed,
  }) : super(key: key);

  @override
  State<DocumentUploadPreparationPage> createState() =>
      _DocumentUploadPreparationPageState();
}

class _DocumentUploadPreparationPageState
    extends State<DocumentUploadPreparationPage> {
  static const fkFileName = "filename";
  static final fileNameDateFormat = DateFormat("yyyy_MM_ddTHH_mm_ss");

  final GlobalKey<FormBuilderState> _formKey = GlobalKey();

  PaperlessValidationErrors _errors = {};
  bool _isUploadLoading = false;
  late bool _syncTitleAndFilename;
  final _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _syncTitleAndFilename = widget.filename == null && widget.title == null;
    initializeDateFormatting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(S.of(context).documentsUploadPageTitle),
        bottom: _isUploadLoading
            ? const PreferredSize(
                child: LinearProgressIndicator(),
                preferredSize: Size.fromHeight(4.0))
            : null,
      ),
      floatingActionButton: Visibility(
        visible: MediaQuery.of(context).viewInsets.bottom == 0,
        child: FloatingActionButton.extended(
          onPressed: _onSubmit,
          label: Text(S.of(context).genericActionUploadLabel),
          icon: const Icon(Icons.upload),
        ),
      ),
      body: BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
        builder: (context, state) {
          return FormBuilder(
            key: _formKey,
            child: ListView(
              children: [
                FormBuilderTextField(
                  autovalidateMode: AutovalidateMode.always,
                  name: DocumentModel.titleKey,
                  initialValue:
                      widget.title ?? "scan_${fileNameDateFormat.format(_now)}",
                  validator: FormBuilderValidators.required(),
                  decoration: InputDecoration(
                    labelText: S.of(context).documentTitlePropertyLabel,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _formKey.currentState?.fields[DocumentModel.titleKey]
                            ?.didChange("");
                        if (_syncTitleAndFilename) {
                          _formKey.currentState?.fields[fkFileName]
                              ?.didChange("");
                        }
                      },
                    ),
                    errorText: _errors[DocumentModel.titleKey],
                  ),
                  onChanged: (value) {
                    final String transformedValue =
                        _formatFilename(value ?? '');
                    if (_syncTitleAndFilename) {
                      _formKey.currentState?.fields[fkFileName]
                          ?.didChange(transformedValue);
                    }
                  },
                ),
                FormBuilderTextField(
                  autovalidateMode: AutovalidateMode.always,
                  readOnly: _syncTitleAndFilename,
                  enabled: !_syncTitleAndFilename,
                  name: fkFileName,
                  decoration: InputDecoration(
                    labelText: S.of(context).documentUploadFileNameLabel,
                    suffixText: ".pdf",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _formKey.currentState?.fields[fkFileName]
                          ?.didChange(''),
                    ),
                  ),
                  initialValue: widget.filename ??
                      "scan_${fileNameDateFormat.format(_now)}",
                ),
                SwitchListTile(
                  value: _syncTitleAndFilename,
                  onChanged: (value) {
                    setState(
                      () => _syncTitleAndFilename = value,
                    );
                    if (_syncTitleAndFilename) {
                      final String transformedValue = _formatFilename(_formKey
                          .currentState
                          ?.fields[DocumentModel.titleKey]
                          ?.value as String);
                      if (_syncTitleAndFilename) {
                        _formKey.currentState?.fields[fkFileName]
                            ?.didChange(transformedValue);
                      }
                    }
                  },
                  title: Text(S
                      .of(context)
                      .documentUploadPageSynchronizeTitleAndFilenameLabel), //TODO: INTL
                ),
                FormBuilderDateTimePicker(
                  autovalidateMode: AutovalidateMode.always,
                  format: DateFormat("dd. MMMM yyyy"), //TODO: INTL
                  inputType: InputType.date,
                  name: DocumentModel.createdKey,
                  initialValue: null,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    labelText:
                        S.of(context).documentCreatedPropertyLabel + " *",
                  ),
                ),
                LabelFormField<DocumentType, DocumentTypeQuery>(
                  notAssignedSelectable: false,
                  formBuilderState: _formKey.currentState,
                  labelCreationWidgetBuilder: (initialName) =>
                      RepositoryProvider.value(
                    value: RepositoryProvider.of<LabelRepository<DocumentType>>(
                      context,
                    ),
                    child: AddDocumentTypePage(initialName: initialName),
                  ),
                  label: S.of(context).documentDocumentTypePropertyLabel + " *",
                  name: DocumentModel.documentTypeKey,
                  state: state.documentTypes,
                  queryParameterIdBuilder: DocumentTypeQuery.fromId,
                  queryParameterNotAssignedBuilder:
                      DocumentTypeQuery.notAssigned,
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
                LabelFormField<Correspondent, CorrespondentQuery>(
                  notAssignedSelectable: false,
                  formBuilderState: _formKey.currentState,
                  labelCreationWidgetBuilder: (initialName) =>
                      RepositoryProvider.value(
                    value:
                        RepositoryProvider.of<LabelRepository<Correspondent>>(
                      context,
                    ),
                    child: AddCorrespondentPage(initialName: initialName),
                  ),
                  label:
                      S.of(context).documentCorrespondentPropertyLabel + " *",
                  name: DocumentModel.correspondentKey,
                  state: state.correspondents,
                  queryParameterIdBuilder: CorrespondentQuery.fromId,
                  queryParameterNotAssignedBuilder:
                      CorrespondentQuery.notAssigned,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                TagFormField(
                  name: DocumentModel.tagsKey,
                  notAssignedSelectable: false,
                  anyAssignedSelectable: false,
                  excludeAllowed: false,
                  selectableOptions: state.tags,
                  //Label: "Tags" + " *",
                ),
                Text(
                  "* " +
                      S
                          .of(context)
                          .uploadPageAutomaticallInferredFieldsHintText,
                  style: Theme.of(context).textTheme.caption,
                ),
              ].padded(),
            ),
          );
        },
      ),
    );
  }

  void _onSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final cubit = BlocProvider.of<DocumentUploadCubit>(context);
      try {
        setState(() => _isUploadLoading = true);

        final fv = _formKey.currentState!.value;

        final createdAt = fv[DocumentModel.createdKey] as DateTime?;
        final title = fv[DocumentModel.titleKey] as String;
        final docType = fv[DocumentModel.documentTypeKey] as IdQueryParameter;
        final tags = fv[DocumentModel.tagsKey] as IdsTagsQuery;
        final correspondent =
            fv[DocumentModel.correspondentKey] as IdQueryParameter;

        await cubit.upload(
          widget.fileBytes,
          filename:
              _padWithPdfExtension(_formKey.currentState?.value[fkFileName]),
          title: title,
          onConsumptionFinished: widget.onSuccessfullyConsumed,
          documentType: docType.id,
          correspondent: correspondent.id,
          tags: tags.ids,
          createdAt: createdAt,
        );
        showSnackBar(context, S.of(context).documentUploadSuccessText);
        Navigator.pop(context, true);
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      } on PaperlessValidationErrors catch (PaperlessServerExceptions) {
        setState(() => _errors = PaperlessServerExceptions);
      } catch (unknownError, stackTrace) {
        showErrorMessage(
            context, const PaperlessServerException.unknown(), stackTrace);
      } finally {
        setState(() {
          _isUploadLoading = false;
        });
      }
    }
  }

  String _padWithPdfExtension(String source) {
    return source.endsWith(".pdf") ? source : '$source.pdf';
  }

  String _formatFilename(String source) {
    return source.replaceAll(RegExp(r"[\W_]"), "_");
  }
}
