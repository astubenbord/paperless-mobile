import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/correspondent_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/document_type_query.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/id_query_parameter.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/tags_query.dart';
import 'package:paperless_mobile/features/labels/correspondent/bloc/correspondents_cubit.dart';
import 'package:paperless_mobile/features/labels/document_type/bloc/document_type_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/labels/correspondent/model/correspondent.model.dart';
import 'package:paperless_mobile/features/labels/correspondent/view/pages/add_correspondent_page.dart';
import 'package:paperless_mobile/features/labels/document_type/model/document_type.model.dart';
import 'package:paperless_mobile/features/labels/document_type/view/pages/add_document_type_page.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_form_field.dart';
import 'package:paperless_mobile/features/scan/bloc/document_scanner_cubit.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class DocumentUploadPage extends StatefulWidget {
  final Uint8List fileBytes;
  final void Function()? afterUpload;
  const DocumentUploadPage({
    Key? key,
    required this.fileBytes,
    this.afterUpload,
  }) : super(key: key);

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  static const fkFileName = "fileName";

  static final fileNameDateFormat = DateFormat("yyyy_MM_ddTHH_mm_ss");
  final GlobalKey<FormBuilderState> _formKey = GlobalKey();

  PaperlessValidationErrors _errors = {};
  bool _isUploadLoading = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting(); //TODO: INTL (has to do with intl below)
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
      body: FormBuilder(
        key: _formKey,
        child: ListView(
          children: [
            FormBuilderTextField(
              autovalidateMode: AutovalidateMode.always,
              name: DocumentModel.titleKey,
              initialValue: "scan_${fileNameDateFormat.format(DateTime.now())}",
              validator: FormBuilderValidators.required(),
              decoration: InputDecoration(
                labelText: S.of(context).documentTitlePropertyLabel,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _formKey.currentState?.fields[DocumentModel.titleKey]
                        ?.didChange("");
                    _formKey.currentState?.fields[fkFileName]
                        ?.didChange(".pdf");
                  },
                ),
                errorText: _errors[DocumentModel.titleKey],
              ),
              onChanged: (value) {
                final String? transformedValue =
                    value?.replaceAll(RegExp(r"[\W_]"), "_");
                _formKey.currentState?.fields[fkFileName]
                    ?.didChange("${transformedValue ?? ''}.pdf");
              },
            ),
            FormBuilderTextField(
              autovalidateMode: AutovalidateMode.always,
              readOnly: true,
              enabled: false,
              name: fkFileName,
              decoration: InputDecoration(
                labelText: S.of(context).documentUploadFileNameLabel,
              ),
              initialValue:
                  "scan_${fileNameDateFormat.format(DateTime.now())}.pdf",
            ),
            FormBuilderDateTimePicker(
              autovalidateMode: AutovalidateMode.always,
              format: DateFormat("dd. MMMM yyyy"), //TODO: INTL
              inputType: InputType.date,
              name: DocumentModel.createdKey,
              initialValue: null,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.calendar_month_outlined),
                labelText: S.of(context).documentCreatedPropertyLabel + " *",
              ),
            ),
            BlocBuilder<DocumentTypeCubit, Map<int, DocumentType>>(
              bloc: getIt<DocumentTypeCubit>(), //TODO: Use provider
              builder: (context, state) {
                return LabelFormField<DocumentType, DocumentTypeQuery>(
                  notAssignedSelectable: false,
                  formBuilderState: _formKey.currentState,
                  labelCreationWidgetBuilder: (initialValue) =>
                      BlocProvider.value(
                    value: BlocProvider.of<DocumentTypeCubit>(context),
                    child: AddDocumentTypePage(initialName: initialValue),
                  ),
                  label: S.of(context).documentDocumentTypePropertyLabel + " *",
                  name: DocumentModel.documentTypeKey,
                  state: state,
                  queryParameterIdBuilder: DocumentTypeQuery.fromId,
                  queryParameterNotAssignedBuilder:
                      DocumentTypeQuery.notAssigned,
                  prefixIcon: const Icon(Icons.description_outlined),
                );
              },
            ),
            BlocBuilder<CorrespondentCubit, Map<int, Correspondent>>(
              bloc: getIt<CorrespondentCubit>(), //TODO: Use provider
              builder: (context, state) {
                return LabelFormField<Correspondent, CorrespondentQuery>(
                  notAssignedSelectable: false,
                  formBuilderState: _formKey.currentState,
                  labelCreationWidgetBuilder: (initialValue) =>
                      BlocProvider.value(
                    value: BlocProvider.of<CorrespondentCubit>(context),
                    child: AddCorrespondentPage(initalValue: initialValue),
                  ),
                  label:
                      S.of(context).documentCorrespondentPropertyLabel + " *",
                  name: DocumentModel.correspondentKey,
                  state: state,
                  queryParameterIdBuilder: CorrespondentQuery.fromId,
                  queryParameterNotAssignedBuilder:
                      CorrespondentQuery.notAssigned,
                  prefixIcon: const Icon(Icons.person_outline),
                );
              },
            ),
            const TagFormField(
              name: DocumentModel.tagsKey,
              notAssignedSelectable: false,
              anyAssignedSelectable: false,
              excludeAllowed: false,
              //Label: "Tags" + " *",
            ),
            Text(
              "* " + S.of(context).uploadPageAutomaticallInferredFieldsHintText,
              style: Theme.of(context).textTheme.caption,
            ),
          ].padded(),
        ),
      ),
    );
  }

  void _onSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      try {
        setState(() => _isUploadLoading = true);

        final fv = _formKey.currentState!.value;

        final createdAt = fv[DocumentModel.createdKey] as DateTime?;
        final title = fv[DocumentModel.titleKey] as String;
        final docType = fv[DocumentModel.documentTypeKey] as IdQueryParameter;
        final tags = fv[DocumentModel.tagsKey] as IdsTagsQuery;
        final correspondent =
            fv[DocumentModel.correspondentKey] as IdQueryParameter;
        await BlocProvider.of<DocumentsCubit>(context).addDocument(
          widget.fileBytes,
          _formKey.currentState?.value[fkFileName],
          onConsumptionFinished: _onConsumptionFinished,
          title: title,
          documentType: docType.id,
          correspondent: correspondent.id,
          tags: tags.ids,
          createdAt: createdAt,
        );
        getIt<DocumentScannerCubit>().reset(); //TODO: Access via provider
        showSnackBar(context, S.of(context).documentUploadSuccessText);
        Navigator.pop(context);
        widget.afterUpload?.call();
      } on ErrorMessage catch (error, stackTrace) {
        showError(context, error, stackTrace);
      } on PaperlessValidationErrors catch (errorMessages) {
        setState(() => _errors = errorMessages);
      } catch (unknownError, stackTrace) {
        showError(context, ErrorMessage.unknown(), stackTrace);
      } finally {
        setState(() {
          _isUploadLoading = false;
        });
      }
    }
  }

  void _onConsumptionFinished(document) {
    ScaffoldMessenger.of(rootScaffoldKey.currentContext!).showSnackBar(
      SnackBar(
        action: SnackBarAction(
          onPressed: () async {
            try {
              getIt<DocumentsCubit>().reloadDocuments();
            } on ErrorMessage catch (error, stackTrace) {
              showError(context, error, stackTrace);
            }
          },
          label:
              S.of(context).documentUploadProcessingSuccessfulReloadActionText,
        ),
        content: Text(S.of(context).documentUploadProcessingSuccessfulText),
      ),
    );
  }
}
